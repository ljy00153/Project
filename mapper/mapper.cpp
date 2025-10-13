#include <iostream>
#include <vector>
#include <string>
#include <cmath>
#include <algorithm>
#include <fstream>

//#include "data_type.h"
#include "eyeriss.cpp"

using namespace std;

class EyerissMapper
{
    public:
        EyerissAnalyzer analyzer;
        EyerissMapper()
        {

        }

        void run(LinearShapeParam linear, int top_k)
        {
            analyzer.linear_shape = linear;

            vector<AnalysisResult> results;

            generate_hardware();

            auto mappings = generate_mappings();

            //cout << "建立 mappings  " << (int)mappings.size() << endl;

            for (int i = 0; i < (int)mappings.size(); i++)
            {
                analyzer.mapping = mappings[i];
                results.push_back(analyzer.summary());
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
                cout << "N : " << mappings[p.second].N << endl;
                cout << "K : " << mappings[p.second].K << endl;
                
                cout << endl;

            }

            if (!scored_results.empty())
            {
                // 取出 top 1
                auto &best = scored_results[0];
                int idx = best.second;

                ofstream csv("log/result.csv");  // 輸出到build資料夾

                if (csv.is_open())
                {
                    // 寫入欄位名稱
                    csv << "layer,glb_usage,glb_read,glb_write,glb_access,dram_read,"
                        "dram_write,dram_access,"
                        "macs,intensity,peak_performance,peak_bandwidth,latency,energy_total,power_total,tk,tn,K,N\n";

                    // 寫入資料
                    csv << "linear,"
                        << results[idx].glb_usage << ","
                        << results[idx].glb_read << ","
                        << results[idx].glb_write << ","
                        << results[idx].glb_access << ","
                        << results[idx].dram_read << ","
                        << results[idx].dram_write << ","
                        << results[idx].dram_access << ","
                        << results[idx].macs << ","
                        << results[idx].intensity << ","
                        << results[idx].peak_performance << ","
                        << results[idx].peak_bandwidth << ","
                        << results[idx].latency << ","
                        << results[idx].energy_total << ","
                        << results[idx].power_total << ","
                        << mappings[idx].tk << ","
                        << mappings[idx].tn << ","
                        << mappings[idx].N << ","
                        << mappings[idx].K
                        << "\n";

                    csv.close();
                    cout << "✅ Top-1 result saved to /build/result.csv\n";
                }
                else
                {
                    cerr << "❌ Failed to open top1_result.csv for writing\n";
                }
            }
        }

        double evaluate(AnalysisResult metrics)
        {
            double score = 0;
            //記憶體訪問次數 (Memory Access)
            int dram_access = metrics.dram_access;
            int glb_access = metrics.glb_access;

            //print(intensity - machine_blance_point)

            // 記憶體訪問能耗估算 (Memory Energy)
            double energy_dram = double(dram_access) * ENERGY_PER_DRAM_ACCESS;  // DRAM access energy
            double energy_glb = double(glb_access) * ENERGY_PER_GLB_ACCESS;

            long long int latency = metrics.latency * CLOCK_RATE;  // 運算延遲（週期數）
            /*
            cout << "energy_dram: " << energy_dram << " J, "
                 << "energy_glb: " << energy_glb << " J, "
                 << "latency: " << metrics.latency << " sec"
                 << endl;
            */
            // 綜合評分（目標是越小越好）
            score +=  energy_glb
                    + energy_dram
                    + (latency * 10);
                    
            return score;
        }

        vector<EyerissMappingParam> generate_mappings()
        {
            const int GLB_LIMIT = 64 * 1024; // 64 KB = 65536 bytes
            const int IFMAP_PER_PE = 3;
            const int WEIGHT_PER_PE = 12;

            vector<EyerissMappingParam> results;

            int tk = 6; //for GEMV
            int tn = 8; //for GEMV
            for (int K = tk; K <= 512; K++) 
            { 
                for (int N = tn; N <= 512; N++) 
                {
                    int used_bytes = K * 1 * IFMAP_PER_PE + K * N * WEIGHT_PER_PE;
                    if (used_bytes < GLB_LIMIT) 
                        results.push_back({tk, tn, K, N});
                    else 
                        break; // N 再增大只會超出限制，可提早中斷
                }
            }

            return results;
        }

        void generate_hardware()
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

            analyzer.hardware_param = hardware;
        }
};


