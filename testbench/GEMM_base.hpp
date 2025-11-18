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

        static constexpr size_t GLB_SIZE = 64 * 1024;

        vector<DataType> DRAM;
        vector<DataType> GLB;

        unique_ptr<EyerissMapper_base> mapper;  // <-- 抽象化 mapper

        static constexpr int IF_LOAD_LAT     = 3;
        static constexpr int W_LOAD_LAT      = 12;
        static constexpr int COMPUTE_LAT     = 48;  
        static constexpr int PSUM_ACC_LAT    = 4;
        static constexpr int PSUM_STORE_LAT  = 4;

        long long load_cycles = 0;
        long long compute_cycles = 0;
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
        GEMM_base() : DRAM(), GLB(GLB_SIZE, 0) {}
        virtual ~GEMM_base() = default;

        virtual void DMA_load(  vector<DataType>& GLB,
                        size_t glb_addr,
                        const vector<DataType>& DRAM,
                        size_t dram_addr,
                        size_t size)
        {
            if (glb_addr + size > GLB.size())
                throw runtime_error("GLB overflow!");

            // 計算 DRAM 可用 bytes
            size_t dram_available = 0;
            if (dram_addr < DRAM.size())
                dram_available = DRAM.size() - dram_addr;

            // 可 copy 的真實大小（取 min）
            size_t copy_size = min(size, dram_available);
            //cout << "copy_size: " << copy_size << endl;
            // 先 copy DRAM 範圍內的資料
            if (copy_size > 0)
                memcpy(&GLB[glb_addr], &DRAM[dram_addr], copy_size * sizeof(int));

            // 如果不足就填 0
            size_t pad_size = size - copy_size;
            if (pad_size > 0)
                memset(&GLB[glb_addr + copy_size], 0, pad_size * sizeof(int));
                
        }

        virtual void DMA_write( vector<DataType>& DRAM,
                          size_t dram_addr,
                          const vector<DataType>& GLB,
                          size_t glb_addr,
                          size_t size)
        {
            if (dram_addr + size > DRAM.size())
                throw runtime_error("DRAM overflow!");

            if (glb_addr + size > GLB.size())
                throw runtime_error("GLB overflow!");

            memcpy(&DRAM[dram_addr], &GLB[glb_addr], size * sizeof(int));
        }

        virtual void DMA_load_PSUM( vector<DataType>& GLB,
                                    size_t glb_addr,
                                    const vector<DataType>& DRAM,
                                    size_t DRAM_PSUM_base,
                                    size_t DRAM_PSUM_idx,
                                    size_t size)
        {
            for(int l = 0; l < shape.B; l++)
            {
                DMA_load( GLB,
                          glb_addr + l * map.N * PE::WEIGHT_H,
                          DRAM,
                          DRAM_PSUM_base + l * shape.out_features + DRAM_PSUM_idx,
                          size);
            }
        }

        virtual void DMA_load_IFMAP( vector<DataType>& GLB,
                                     size_t glb_addr,
                                     const vector<DataType>& DRAM,
                                     size_t DRAM_IFMAP_base,
                                     size_t DRAM_IFMAP_idx,
                                     size_t size)
        {
            int in_div4 = ceil(double(shape.in_features) / 4);
            for(int l = 0; l < map.M; l++)
            {
                DMA_load( GLB,
                          glb_addr + l * map.K * PE::IFMAP_SIZE,
                          DRAM,
                          DRAM_IFMAP_base + l * in_div4 + DRAM_IFMAP_idx,
                          size);
            }
        }

        virtual void DMA_load_WEIGHT( vector<DataType>& GLB,
                                     size_t glb_addr,
                                     const vector<DataType>& DRAM,
                                     size_t DRAM_WEIGHT_base,
                                     size_t DRAM_WEIGHT_idx,
                                     size_t size)
        {
            for(int l = 0; l < map.K * PE::IFMAP_SIZE; l++)
            {
                DMA_load( GLB,
                          glb_addr + l * map.N * PE::WEIGHT_H,
                          DRAM,
                          DRAM_WEIGHT_base + l * shape.out_features + DRAM_WEIGHT_idx,
                          size);
            }
        }

        virtual void DMA_write_PSUM( vector<DataType>& DRAM,
                                     size_t DRAM_PSUM_base,
                                     const vector<DataType>& GLB,
                                     size_t glb_addr,
                                     size_t DRAM_PSUM_idx,
                                     size_t size)
        {
            for(int l = 0; l < shape.B; l++)
            {
                DMA_write( DRAM,
                           DRAM_PSUM_base + l * shape.out_features + DRAM_PSUM_idx,
                           GLB,
                           glb_addr + l * map.N * PE::WEIGHT_H,
                           size);
            }
        }

        void reset_cycle()
        { 
            total_cycles = 0;
            load_cycles = 0;
            compute_cycles = 0;
        }

        virtual void create_mapper() 
        {
            mapper = make_unique<EyerissMapper_base>();  // 預設使用 base 版本
        }


        virtual void run(const LinearShapeParam& linear, const string& pattern, string log_path = "") 
        {
            create_mapper();
            shape = linear;
            total_cycles = 0;
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

            size_t total_size = in_features.size() + weights.size() + linear.B * linear.out_features;
            DRAM.resize(total_size, 0);   // 先分配好整塊空間

            // copy in_features 到 DRAM 起始
            copy(in_features.begin(), in_features.end(), DRAM.begin());

            // copy weights 到 in_features 後面
            copy(weights.begin(), weights.end(), DRAM.begin() + in_features.size());

            run_simulation(in_features, weights, psum_dut);


            // 5. 報告與驗證
            cout << "=======================================" << endl;
            cout << "=          SIMULATION REPORT          =" << endl;
            cout << "=======================================" << endl;
            
            cout << "Total MACs: " << mapper->analyzer->macs_per_layer() << endl;
            cout << "Total cycles simulated: " << total_cycles << endl;
            cout << "Total load cycles: " << load_cycles << endl;
            cout << "Total compute cycles: " << compute_cycles << endl;
            printf("Performance: %.2f MACs/cycle\n",
                    double(mapper->analyzer->macs_per_layer()) / double(total_cycles));
            
            
            bool pass;
            pass = equal(DRAM.begin() + in_features.size() + weights.size(), DRAM.end(), golden.begin());
            
            cout << "Result Verification: " << (pass ? "PASSED" : "FAILED") << endl;
            
            /*for(size_t i=0; i < 100; i++) 
            {
                cout << "index[" << i << "]:  DUT=" << psum_dut[i] << ", Golden=" << golden[i] << endl;
            }*/
            if (!pass) 
            {
                
                for(size_t i=0; i < linear.B * linear.out_features; i++) 
                {
                    if (DRAM[i + in_features.size() + weights.size()] != golden[i]) 
                    {
                        cout << "Mismatch at index " << i << ": DUT=" << DRAM[i + in_features.size() + weights.size()] << ", Golden=" << golden[i] << endl;
                    }
                }
            }
            else
            {
                mapper->best_result.cycles = total_cycles;
                mapper->mapping_to_csv_with_cycle(log_path);
            }
            cout << "=======================================\n" << endl;
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