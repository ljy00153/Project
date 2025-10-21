#pragma once
#include <iostream>
#include <vector>
#include <array>
#include <string>
#include <fstream>
#include <sstream>
#include "../src/PE/pe_array.cpp"

#include "../analayzer/mapper_base.hpp"

using namespace std;
using DataType = int32_t;
void load_data(std::vector<DataType> &mem, const std::string &filename);

class GEMM_base  
{
    protected:
        EyerissMappingParam map;
        LinearShapeParam shape;
        PE_Array pe_array;

        unique_ptr<EyerissMapper_base> mapper;  // <-- 抽象化 mapper

        static constexpr int IF_LOAD_LAT     = 3;
        static constexpr int W_LOAD_LAT      = 12;
        static constexpr int COMPUTE_LAT     = 48;  
        static constexpr int PSUM_ACC_LAT    = 6;
        static constexpr int PSUM_STORE_LAT  = 4;

        long long total_cycles = 0;
        std::array<int, 6> w_base = {0};
        std::array<int, 6> r_base = {0};

        void setup_pe_bases() 
        {
            switch (map.mode) {
                case 1:  w_base[0] = 40;  r_base[0] = 0; break;
                case 2:  w_base = {16, 40}; r_base = {0, 24}; break;
                case 3:  w_base = {8, 24, 40}; r_base = {0, 16, 32}; break;
                case 6:
                    for (int i = 0; i < 6; i++) { w_base[i] = r_base[i] = i * 8; }
                    break;
            }
        }

    public:
        virtual ~GEMM_base() = default;

        long long get_total_cycles() const { return total_cycles; }

        virtual void create_mapper() 
        {
            mapper = make_unique<EyerissMapper_base>();  // 預設使用 base 版本
        }


        virtual void run(const LinearShapeParam& linear, const string& pattern, string log_path = "") 
        {
            create_mapper();
            shape = linear;

            mapper->run(linear, 1);

            map = {mapper->best_result.tk, mapper->best_result.tn, mapper->best_result.mode, 
                                        mapper->best_result.M, mapper->best_result.K, mapper->best_result.N};
            cout << "\n[Testbench] Initializing DUT (PE_Array)..." << endl;
            // 2. 初始化 DUT
            PE_Array dut_pe_array;
            dut_pe_array.reset();
            dut_pe_array.mode = mapper->best_result.mode;
            dut_pe_array.set_tag();
            
            pe_array = dut_pe_array;
            // 3. 準備測試資料
            vector<DataType> in_features;
            vector<DataType> weights;
            vector<DataType> psum_dut(linear.B * linear.out_features, 0);
            vector<DataType> golden;

            cout << "[Testbench] Loading Test Data..." << endl;
            
            string base_path = "Pattern/" + pattern + "/";
            load_data(in_features, base_path + "A.txt");
            load_data(weights, base_path + "B.txt");
            load_data(golden, base_path + "C_golden.txt");

            /* if padding is needed
            int padded_in_size = ((linear.in_features / 4 + 17 * mapper.best_result.mode) / 18) * 18;
            vector<DataType> padded_in_features(linear.B * padded_in_size, 0);

            if (in_features.size() > padded_in_features.size()) 
            {
                cerr << "ERROR: padded_in_features too small (" << padded_in_features.size()
                    << " < " << in_features.size() << ")" << endl;
                exit(1);
            }
            cout << "\nlinear.in_features: " << linear.in_features / 4 << ", padded_in_size: " << linear.B * padded_in_size << endl;
            copy(in_features.begin(), in_features.end(), padded_in_features.begin());

            int padded_w_size = linear.out_features * padded_in_size;
            vector<DataType> padded_weights(padded_w_size, 0);

            if (weights.size() > padded_w_size) 
            {
                cerr << "ERROR: padded_w_size too small (" << padded_weights.size()
                    << " < " << weights.size() << ")" << endl;
                exit(1);
            }
            cout << "linear.out_features: " << linear.out_features << ", padded_w_size: " << padded_w_size << endl;
            copy(weights.begin(), weights.end(), padded_weights.begin());
            */

            // 4. 執行 DUT 模擬 (Cycle-Accurate)
            cout << "\n[Testbench] Starting DUT (PE_Array) Simulation..." << endl;

            cout << "   Mapping Parameters: " << endl;
            cout << "    mode: " << map.mode << endl;
            cout << "    tk: " << map.tk << endl;
            cout << "    tn: " << map.tn << endl;
            cout << "    M: " << map.M << endl;
            cout << "    K: " << map.K << endl;
            cout << "    N: " << map.N << endl;

            run_simulation(in_features, weights, psum_dut);


            // 5. 報告與驗證
            cout << "=======================================" << endl;
            cout << "=          SIMULATION REPORT          =" << endl;
            cout << "=======================================" << endl;
            
            long long final_cycles = get_total_cycles();
            cout << "Total cycles simulated: " << final_cycles << endl;
            
            bool pass;
            pass = equal(psum_dut.begin(), psum_dut.end(), golden.begin());
            
            cout << "Result Verification: " << (pass ? "PASSED" : "FAILED") << endl;
            
            /*for(size_t i=0; i < 100; i++) 
            {
                cout << "index[" << i << "]:  DUT=" << psum_dut[i] << ", Golden=" << golden[i] << endl;
            }*/
            if (!pass) 
            {
                for(size_t i=0; i < psum_dut.size(); i++) 
                {
                    if (psum_dut[i] != golden[i]) 
                    {
                        cout << "Mismatch at index " << i << ": DUT=" << psum_dut[i] << ", Golden=" << golden[i] << endl;
                    }
                }
            }
            cout << "=======================================\n" << endl;

            mapper->best_result.cycles = final_cycles;
            mapper->mapping_to_csv_with_cycle(log_path);

        }

        //costmized simulation function
        virtual void run_simulation(const std::vector<DataType>& all_in_features,
                                    const std::vector<DataType>& all_weights,
                                    std::vector<DataType>& final_psums) = 0;
};

void load_data(std::vector<DataType> &mem, const std::string &filename)
{
    ifstream file(filename);
    if (!file.is_open()) 
    {
        cerr << "   Error opening file: " << filename << endl;
        return;
    }
    else
        cout << "   Successfully open file: " << filename << endl;
    string line;
    while (getline(file, line)) 
    {
        if (line.empty()) continue;
        int32_t val;
        stringstream ss(line);
        ss >> hex >> val;
        if (ss.fail()) 
        {
            cerr << "⚠️  Invalid line in " << filename << ": " << line << endl;
            continue;
        }
        //cout << "load value: " << val << endl;
        mem.push_back(val);
    }

    file.close();
}