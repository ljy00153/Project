#pragma once
#include <iostream>
#include <vector>
#include <string>
#include <cmath>
#include <algorithm>
#include <fstream>
#include <filesystem>
#include <memory>

#include "data_type.h"
#include "Eyeriss_base.hpp"
//#include "analayzer_OS/eyeriss.cpp"

class EyerissMapper_base
{
    public:
        unique_ptr<EyerissAnalyzer_base> analyzer;

        AnalysisResult best_result;
        EyerissMappingParam best_mapping;

        virtual ~EyerissMapper_base() = default;

        virtual void create_analyzer()
        {
            analyzer = make_unique<EyerissAnalyzer_base>();// 預設使用 base 版本
        }

        virtual void run(LinearShapeParam linear, int top_k, string log_path = "")
        {
            create_analyzer();
            analyzer->linear_shape = linear;

            vector<AnalysisResult> results;

            generate_hardware();
            cout << "Starting design space exploration..." << endl;
            auto mappings = generate_mappings();
            cout << "Total configurations to evaluate: " << mappings.size() << endl;
            for (int i = 0; i < (int)mappings.size(); i++)
            {
                analyzer->mapping = mappings[i];
                results.push_back(analyzer->summary());
            }

            //cout << "建立 (score, index) pair" << endl;
            vector<pair<double, int>> scored_results;
            for (int i = 0; i < (int)results.size(); i++)
            {
                double score = evaluate(results[i]);
                if(score > 0)
                    scored_results.push_back({score, i});
            }
            

                // 找出前 top_k 個最小分數
            if (scored_results.size() > top_k)
            {
                partial_sort(
                    scored_results.begin(),
                    scored_results.begin() + top_k,
                    scored_results.end(),
                    [](auto &a, auto &b) { return a.first < b.first; });
            }
            else
            {
                sort(
                    scored_results.begin(),
                    scored_results.end(),
                    [](auto &a, auto &b) { return a.first < b.first; });
            }
            cout << "Design space exploration completed." << endl;
            cout << "---------------------------------------" << endl;
            cout << "Total valid configurations: " << scored_results.size() << endl;
            cout << endl << "Top " << top_k << " configurations:\n";
            
            for (int i = 0; i < min(top_k, (int)scored_results.size()); i++)
            {
                auto &p = scored_results[i];
                cout << i + 1 << ". Score = " << p.first << endl;

                cout << "glb_usage: " << results[p.second].glb_usage << " bytes" << endl;
                cout << "glb_access: " << results[p.second].glb_access << " bytes" << endl;
                cout << "dram_access: " << results[p.second].dram_access << " bytes" << endl;
                cout << "latency: " << results[p.second].latency << " sec" << endl;
                cout << "energy_glb: " << results[p.second].glb_access * 10 * ENERGY_UNIT << " J" << endl;
                cout << "energy_dram: " << double(results[p.second].dram_access) * 200 * ENERGY_UNIT << " J" << endl;
                cout << "mode: " << mappings[p.second].mode << endl;
                cout << "tk : " << mappings[p.second].tk << endl;
                cout << "tn : " << mappings[p.second].tn << endl;
                cout << "M : " << mappings[p.second].M << endl;
                cout << "N : " << mappings[p.second].N << endl;
                cout << "K : " << mappings[p.second].K << endl;
                
                cout << endl;

            }

            if (!scored_results.empty())
            {
                // 取出 top 1
                cout << "---------------------------------------" << endl;
                if(log_path != "")
                    cout << "Top-1 configuration details saved to "<< log_path << endl;
                auto &best = scored_results[0];
                int idx = best.second;
                best_result = results[idx];
                best_mapping = mappings[idx];
                if(log_path != "")
                    mapping_to_csv_no_cycle(results[idx], mappings[idx], log_path);
            }
        }

        virtual double evaluate(AnalysisResult metrics)
        {
            double score = 0;
            //記憶體訪問次數 (Memory Access)
            double energy_dram = metrics.dram_access;  // DRAM access energy

            long long int latency = metrics.latency * CLOCK_RATE;  // 運算延遲（週期數）
            /*
            cout << "energy_dram: " << energy_dram << " J, "
                 << "energy_glb: " << energy_glb << " J, "
                 << "latency: " << metrics.latency << " sec"
                 << endl;
            */
            // 綜合評分（目標是越小越好）
            score +=  metrics.energy_total
                    + (latency * 10);
                    
            return score;
        }

        virtual vector<EyerissMappingParam> generate_mappings()
        {
            const int GLB_LIMIT = 64 * 1024; // 64 KB = 65536 bytes
            const int IFMAP_PER_PE = 3;
            const int WEIGHT_PER_PE = 4;

            vector<EyerissMappingParam> results;

            int tk[4] = {6, 3, 2, 1}; //for GEMM now
            int tn = 8; //for GEMM and GEMV
            int mode[4] = {1, 2, 3, 6};
            for (int i = 0; i < 4; i++)
            {
                cout << "   trying mode= " << mode[i]<<endl;
                for(int M = mode[i]; M <= 1024; M++)
                {
                    if(M > analyzer->linear_shape.B)
                        break;// M 不應該大於 batch size
                    for (int K = tk[i]; K <= 1024; K++) 
                    { 
                        for (int N = tn; N <= 1024; N++) 
                        {
                            int used_bytes =  M * K * IFMAP_PER_PE * 4 
                                            + K * IFMAP_PER_PE * N * WEIGHT_PER_PE * 4
                                            + analyzer->linear_shape.B * N * 4 * 4;

                            if (used_bytes < GLB_LIMIT) 
                                results.push_back({tk[i], tn, mode[i], M, K, N});
                            else 
                                break; // N 再增大只會超出限制，可提早中斷
                        }
                    }
                }
            }


            return results;
        }

        virtual void generate_hardware()
        {
            EyerissHardwareParam hardware;
            hardware.pe_array_h = 6;
            hardware.pe_array_w = 8;
            hardware.ifmap_spad_size = 12;
            hardware.filter_spad_size = 48;
            hardware.psum_spad_size = 16;
            hardware.glb_size = 64 * 1024;
            hardware.bus_bw = 4;
            hardware.noc_bw = 4;

            analyzer->hardware_param = hardware;
        }

        virtual void mapping_to_csv_no_cycle(AnalysisResult& results, const EyerissMappingParam mappings, const string& path)
        {
            string output_name = "/GEMM.csv";
            string filename = path + output_name;
            string batch = to_string(analyzer->linear_shape.B);
            string in_f = to_string(analyzer->linear_shape.in_features);
            string out_f = to_string(analyzer->linear_shape.out_features);
            results.name = results.name + "(" + batch + "," + in_f + "," + out_f + ")" + "\"";
            bool file_exists = std::filesystem::exists(filename);
            bool is_empty = true;
            if (file_exists) 
            {
                std::ifstream check(filename, ios::ate | ios::binary);
                is_empty = (check.tellg() == 0);
                check.close();
            }

            ofstream csv(filename, ios::app);  // ✅ append 模式

            if (csv.is_open())
            {
                // 寫入欄位名稱
                if (is_empty)
                {
                    csv << "layer,glb_usage,glb_read,glb_write,glb_access,dram_read,"
                        "dram_write,dram_access,"
                        "macs,intensity,peak_performance,peak_bandwidth,latency,energy_total,power_total,"
                        "tk,tn,mode,M,K,N\n";    
                }
                

                // 寫入資料
                csv << results.name << ","
                    << results.glb_usage << ","
                    << results.glb_read << ","
                    << results.glb_write << ","
                    << results.glb_access << ","
                    << results.dram_read << ","
                    << results.dram_write << ","
                    << results.dram_access << ","
                    << results.macs << ","
                    << results.intensity << ","
                    << results.peak_performance << ","
                    << results.peak_bandwidth << ","
                    << results.latency << ","
                    << results.energy_total << ","
                    << results.power_total << ","
                    << mappings.tk << ","
                    << mappings.tn << ","
                    << mappings.mode << ","
                    << mappings.M << ","
                    << mappings.K << ","
                    << mappings.N
                    << "\n";

                csv.close();
                cout << "✅ Top-1 result saved to" << filename << "\n";
            }
            else
            {
                cout << "❌ Unable to open file: " << filename << endl;
            }
        }

        virtual void mapping_to_csv_with_cycle(const string& path)
        {
            string output_name = "/GEMM.csv";
            string filename = path + output_name;
            string batch = to_string(analyzer->linear_shape.B);
            string in_f = to_string(analyzer->linear_shape.in_features);
            string out_f = to_string(analyzer->linear_shape.out_features);
            best_result.name = best_result.name + "(" + batch + "," + in_f + "," + out_f + ")" + '"';
            bool file_exists = std::filesystem::exists(filename);
            bool is_empty = true;
            if (file_exists) 
            {
                ifstream check(filename, ios::ate | ios::binary);
                is_empty = (check.tellg() == 0);
                check.close();
            }

            ofstream csv(filename, ios::app);  // ✅ append 模式

            if (csv.is_open())
            {
                // 寫入欄位名稱
                if (is_empty)
                {
                    csv << "layer,glb_usage,glb_read,glb_write,glb_access,dram_read,"
                        "dram_write,dram_access,"
                        "macs,intensity,peak_performance,peak_bandwidth,cycles,latency,energy_total,power_total,"
                        "tk,tn,mode,M,K,N\n";    
                }
                
                // 寫入資料
                csv << best_result.name << ","
                    << best_result.glb_usage << ","
                    << best_result.glb_read << ","
                    << best_result.glb_write << ","
                    << best_result.glb_access << ","
                    << best_result.dram_read << ","
                    << best_result.dram_write << ","
                    << best_result.dram_access << ","
                    << best_result.macs << ","
                    << best_result.intensity << ","
                    << best_result.peak_performance << ","
                    << best_result.peak_bandwidth << ","
                    << best_result.cycles << ","
                    << best_result.latency << ","
                    << best_result.energy_total << ","
                    << best_result.power_total << ","
                    << best_mapping.tk << ","
                    << best_mapping.tn << ","
                    << best_mapping.mode << ","
                    << best_mapping.M << ","
                    << best_mapping.K << ","
                    << best_mapping.N
                    << "\n";

                csv.close();
                cout << "✅ Top-1 result saved to" << filename << "\n";
            }
            else
            {
                cout << "❌ Unable to open file: " << filename << endl;
            }
        }
        // ... (在 mapping_to_csv_with_cycle 之後)

        virtual void generate_assembly(const string& base_file_path, const string& output_file_path)
        {
            // 檢查是否已經有最佳結果
            if (best_mapping.M == 0) 
            { // 簡單檢查是否已執行過 run
                cout << "❌ Warning: No best mapping found. Please run exploration first." << endl;
                return;
            }
            string output_name = "/GEMM_assembly.txt";
            string shape = "/shape.txt";
            ofstream outfile(output_file_path + output_name);
            ofstream fs(output_file_path + shape);
            if (!outfile.is_open() || !fs.is_open())
            {
                cout << "❌ Unable to create output file: " << output_file_path << endl;
                return;
            }
            // 1. 生成 Header (.set constants)
            // 根據 best_mapping 和 linear_shape 計算
            int B = analyzer->linear_shape.B;
            int IF = analyzer->linear_shape.in_features; 
            int OF = analyzer->linear_shape.out_features;

            int M = best_mapping.M;
            int K = best_mapping.K * 3 * 4;
            int N = best_mapping.N * 4;
            int tk = best_mapping.tk;
            int tn = best_mapping.tn;
            int mode = best_mapping.mode;

            fs << "IF_SIZE: " << IF << endl;
            fs << "OF_SIZE: " << OF << endl;
            fs << "B_SIZE: " << B << endl;
            fs << "K_SIZE: " << best_mapping.K << endl;
            fs << "N_SIZE: " << best_mapping.N << endl;
            fs << "M_SIZE: " << best_mapping.M << endl;

            fs.close();

            // 根據 controller_assembly.txt 註解推導的計算邏輯
            int N_times_4 = N * 4;
            
            // Offsets
            int outf_offset = N;   
            int inf_offset  = K;   
            int b_offset    = M;   
            int k_offset    = tk; 
            int n_offset    = tn;     
            int m_offset    = mode;       

            // Sizes
            int pe_array_weight_size = 48 * 12 * 4; 
            int pe_array_ipsum_size = tn * 16; 
            int pe_array_ifmap_size = tk * 12;

            int glb_ifmap_size  = best_mapping.M * best_mapping.K * 12;
            int glb_weight_size = best_mapping.K * best_mapping.N * 48;
            int glb_opsum_size  = B * best_mapping.N * 16;

            int dram_ifmap_size  = IF * B;
            int dram_weight_size = IF * OF;
            int dram_opsum_size  = B * OF * 4;

            outfile << "# Generated by EyerissMapper" << endl;
            outfile << "# Batch = " << B << ", In Feature = " << IF << ", Out Feature = " << OF << endl;
            outfile << endl;
            outfile << "#set constant" << endl;
            outfile << ".set IF, " << IF << endl;
            outfile << ".set OF, " << OF << endl;
            outfile << ".set B, " << B << endl;
            outfile << "#mapping parameter" << endl;
            outfile << ".set M, " << M << endl;
            outfile << ".set K, " << best_mapping.K << endl;
            outfile << ".set N, " << best_mapping.N << endl;
            outfile << ".set N_times_16, " << N_times_4 << "\t # " << best_mapping.N << " * 4 * 4" << endl;
            outfile << ".set outf_offset, " << outf_offset << "\t # " << best_mapping.N << " * 4" << endl;
            outfile << ".set inf_offset, " << inf_offset << "\t # " << best_mapping.K << " * 3 * 4" << endl;
            outfile << ".set b_offset, " << b_offset << "\t # M" << endl;
            outfile << ".set k_offset, " << k_offset << "\t # tk" << endl;
            outfile << ".set n_offset, " << n_offset << "\t # tn" << endl;
            outfile << ".set m_offset, " << m_offset << "\t # mode" << endl;
            outfile << endl;
            outfile << ".set PE_ARRAY_WEIGHT_SIZE, " << pe_array_weight_size << "\t# 48 * 12 * 4" << endl;
            outfile << ".set PE_ARRAY_IPSUM_SIZE, " << pe_array_ipsum_size << "\t# 8 * 1 * 4 * 4" << endl;
            outfile << ".set PE_ARRAY_IFMAP_SIZE, " << pe_array_ifmap_size << "\t# 6 * 3 * 4" << endl;
            outfile << ".set GLB_IFMAP_SIZE, " << glb_ifmap_size << "\t# M * K * 12" << endl;
            outfile << ".set GLB_WEIGHT_SIZE, " << glb_weight_size << "\t# K * 3 * N * 4 * 4" << endl;
            outfile << ".set GLB_OPSUM_SIZE, " << glb_opsum_size << "\t# B * N * 16" << endl;
            outfile << ".set DRAM_IFMAP_SIZE, " << dram_ifmap_size << endl;
            outfile << ".set DRAM_WEIGHT_SIZE, " << dram_weight_size << endl;
            outfile << ".set DRAM_OPSUM_SIZE, " << dram_opsum_size << endl;
            outfile << endl;

            // 2. 讀取 Base File 並附加內容
            string base_name = "/assembly_base.txt";
            ifstream base_file(base_file_path + base_name);
            if (base_file.is_open()) 
            {
                outfile << base_file.rdbuf(); // 快速複製整個檔案內容
                base_file.close();
                cout << "✅ Assembly generated: " << output_file_path + output_name << endl;
            } else 
            {
                cout << "❌ Unable to open base file: " << base_file_path + base_name << endl;
            }

            outfile.close();
        }
};


