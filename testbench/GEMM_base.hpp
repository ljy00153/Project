#pragma once
#include <iostream>
#include <vector>
#include <array>
#include <string>
#include <fstream>
#include <sstream>
#include "../src/PE/pe_array.cpp"

#include "../analayzer/Mapper_base.hpp"

using namespace std;
using DataType = int32_t;
void load_ifmap(vector<int32_t> &mem, const string &filename);
void load_weight(vector<int32_t> &mem, const string &filename);
void load_ipsum_golden(vector<int32_t> &mem, const string &filename);

class GEMM_base  
{
    protected:
        EyerissMappingParam map;
        LinearShapeParam shape;
        PE_Array pe_array;

        static constexpr size_t GLB_SIZE = 64 * 1024;

        vector<DataType> DRAM;
        vector<DataType> GLB;
        vector<int32_t> in_features;
        vector<int32_t> weights;
        vector<int32_t> ipsums;
        vector<int32_t> golden;

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
            {
                cout << "glb_addr: " << glb_addr << ", size: " << size << ", GLB.size(): " << GLB.size() << endl;
                throw runtime_error("GLB load overflow!");
            }
                

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
            // 1. 計算 DRAM (目的端) 剩餘空間
            size_t dram_available = 0;
            if (dram_addr < DRAM.size()) {
                dram_available = DRAM.size() - dram_addr;
            }

            // 2. 決定實際寫入長度
            // 取 min：如果 size 超過剩餘空間，就只寫剩餘空間那麼多 (截斷)
            size_t write_size = min(size, dram_available);

            // 如果沒有空間可寫，直接結束
            if (write_size == 0) return;

            // 3. 安全檢查：確保來源端 (GLB) 有足夠的資料可以讀
            // 雖然 DRAM 空間夠，但我們還是不能讀取 GLB 超出範圍的記憶體
            if (glb_addr + write_size > GLB.size())
            {
                cout << "glb_addr: " << glb_addr << ", write_size: " << write_size 
                     << ", GLB.size(): " << GLB.size() << endl;
                throw runtime_error("GLB read overflow during DMA_write!");
            }

            // 4. 執行複製
            // 只複製 write_size 的長度，超過 DRAM 範圍的部分自動被忽略
            memcpy(&DRAM[dram_addr], &GLB[glb_addr], write_size * sizeof(int));
        }

        virtual void DMA_load_PSUM( vector<DataType>& GLB,
                                    size_t glb_addr,
                                    const vector<DataType>& DRAM,
                                    size_t DRAM_PSUM_base,
                                    size_t DRAM_PSUM_idx,
                                    size_t size)
        {
            size_t size_min = min(size_t(size), size_t(shape.out_features * 4));
            for(int l = 0; l < shape.B; l++)
            {
                DMA_load( GLB,
                          glb_addr + l * map.N * PE::WEIGHT_H * 4,
                          DRAM,
                          DRAM_PSUM_base + l * shape.out_features * 4 + DRAM_PSUM_idx,
                          size_min);
                //cout << "glb_addr: " << glb_addr + l * map.N * PE::WEIGHT_H * 4;
                //cout << "  dram_addr: " << DRAM_PSUM_base + l * shape.out_features * 4 + DRAM_PSUM_idx;
                //cout << "  size: " << size_min << endl;
            }
            //for(int i = 216 + 128 * 72; i < 216 + 128 * 72 + 3 * 12 * 4; i++)
            //  cout << dec << "GLB[" << i << "]: " << hex << GLB[i] << endl;
        }

        virtual void DMA_load_IFMAP( vector<DataType>& GLB,
                                     size_t glb_addr,
                                     const vector<DataType>& DRAM,
                                     size_t DRAM_IFMAP_base,
                                     size_t DRAM_IFMAP_idx,
                                     size_t size)
        {
            //int in_div4 = ceil(double(shape.in_features) / 4);
            for(int l = 0; l < map.M; l++)
            {
                size_t size_min = min(size_t(size), size_t(shape.in_features));
                DMA_load( GLB,
                          glb_addr + l * map.K * PE::IFMAP_SIZE * 4,
                          DRAM,
                          DRAM_IFMAP_base + l * shape.in_features + DRAM_IFMAP_idx,
                          size_min);
                //cout << "glb_addr: " << glb_addr + l * map.K * PE::IFMAP_SIZE * 4;
                //cout << "  dram_addr: " << DRAM_IFMAP_base + l * shape.in_features + DRAM_IFMAP_idx;
                //cout << "  size: " << size_min << endl;
            }
            //for(int i = 0; i < 216; i++)
            //  cout << dec << "GLB[" << i << "]: " << hex << GLB[i] << endl;
        }

        virtual void DMA_load_WEIGHT( vector<DataType>& GLB,
                                     size_t glb_addr,
                                     const vector<DataType>& DRAM,
                                     size_t DRAM_WEIGHT_base,
                                     size_t DRAM_WEIGHT_idx,
                                     size_t size)
        {
            size_t size_min = min(size_t(size), size_t(shape.out_features));
            size_t size_min2 = min(size_t(size), size_t(shape.in_features));
            size_t k_min = min(size_t(map.K * PE::IFMAP_SIZE * 4), size_t(shape.in_features));
            size_t n_min = min(size_t(map.N * PE::WEIGHT_H), size_t(shape.out_features));
            for(int l = 0; l < n_min; l++)
            {
                DMA_load( GLB,
                          glb_addr + l * map.K * PE::IFMAP_SIZE * 4,
                          DRAM,
                          DRAM_WEIGHT_base + l * shape.in_features + DRAM_WEIGHT_idx,
                          size_min2);
                //cout << "glb_addr: " << l * map.K * PE::IFMAP_SIZE * 4;
                //cout << "  dram_addr: " << l * shape.in_features + DRAM_WEIGHT_idx;
                //cout << "  size: " << size_min2 << endl;
            }
            //for(int i = map.M * map.K * 3 * 4; i < map.M * map.K * 3 + map.K * 3 * 4 * map.N * 4 * 4; i++)
            //    cout << dec << "GLB[" << i << "]: " << hex << GLB[i] << endl;
        }

        virtual void DMA_write_PSUM( vector<DataType>& DRAM,
                                     size_t DRAM_PSUM_base,
                                     size_t DRAM_PSUM_idx,
                                     const vector<DataType>& GLB,
                                     size_t glb_addr,
                                     size_t size)
        {
            int offset = shape.out_features * 4 - DRAM_PSUM_idx % (shape.out_features * 4);
            size_t size_min1 = min(size_t(size), size_t(offset));
            size_t size_min2 = min(size_t(size_min1), size_t(shape.out_features * 4));
            for(int l = 0; l < shape.B; l++)
            {
                DMA_write( DRAM,
                           DRAM_PSUM_base + l * shape.out_features * 4 + DRAM_PSUM_idx,
                           GLB,
                           glb_addr + l * map.N * PE::WEIGHT_H * 4,
                           size_min2);
                //cout << dec <<"glb_addr: " << glb_addr + l * map.N * PE::WEIGHT_H * 4;
                //cout << "  dram_addr: " << DRAM_PSUM_base + l * shape.out_features * 4+ DRAM_PSUM_idx;
                //cout << "  DRAM_PSUM_idx: " << DRAM_PSUM_idx;
                //cout << "  size: " << offset << endl;
                //for(int i = 0; i < size_min; i++)
                //    cout << "  GLB[" << glb_addr + l * map.N * PE::WEIGHT_H * 4 + i << "] = " 
                //         << GLB[glb_addr + l * map.N * PE::WEIGHT_H * 4 + i] << endl;
            }
            //for(int i = 60; i < 60 + 36; i++)
            //    cout << dec << "DRAM[" << i << "]: " << hex << DRAM[i] << endl;
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


        virtual void run(const LinearShapeParam& linear, const string& pattern, string log_path = "", string prog_path = "") 
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
            in_features = vector<int32_t>();
            weights = vector<int32_t>();
            ipsums = vector<int32_t>();
            golden = vector<int32_t>();

            cout << "[Testbench] Loading Test Data..." << endl;
            
            string base_path = pattern + "/";
            load_ifmap(in_features, base_path + "A.txt");
            load_weight(weights, base_path + "B.txt");
            load_ipsum_golden(ipsums, base_path + "ipsum.txt");
            load_ipsum_golden(golden, base_path + "C_golden.txt");

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
            DRAM = vector<DataType>(); // clear DRAM
            GLB = vector<DataType>(GLB_SIZE, 0); // reset GLB
            size_t total_size = in_features.size() + weights.size() + ipsums.size();
            DRAM.resize(total_size, 0);   // 先分配好整塊空間
            

            // copy in_features 到 DRAM 起始
            copy(in_features.begin(), in_features.end(), DRAM.begin());

            // copy weights 到 in_features 後面
            copy(weights.begin(), weights.end(), DRAM.begin() + in_features.size());

            copy(ipsums.begin(), ipsums.end(), DRAM.begin() + in_features.size() + weights.size());

            run_simulation();

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
            if(!pass) 
            {
                
                for(size_t i=0; i < linear.B * linear.out_features * 4; i++) 
                {
                    if (DRAM[i + in_features.size() + weights.size()] != golden[i]) 
                    {
                        cout << "Mismatch at index " << dec << i << ": DUT=" 
                        << hex << DRAM[i + in_features.size() + weights.size()] << ", Golden=" << golden[i] << endl;
                    }
                }
            }
            else
            {
                mapper->best_result.cycles = total_cycles;
                mapper->mapping_to_csv_with_cycle(log_path);
                mapper->generate_assembly("../ISA", "../hardware/sim" + prog_path);
            }
            cout << "=======================================\n" << endl;
        }

        //costmized simulation function
        virtual void run_simulation() = 0;
};

void load_ifmap(vector<int32_t> &mem, const string &filename)
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
        int tmp;
        stringstream ss(line);
        ss >> hex >> tmp;
        if (ss.fail()) 
        {
            cerr << "⚠️  Invalid line in " << filename << ": " << line << endl;
            continue;
        }
        uint8_t val = static_cast<uint8_t>(tmp);
        //cout << "load value: " << static_cast<int32_t>(val) << endl;
        mem.push_back(static_cast<int32_t>(val));
    }

    file.close();
}

void load_weight(vector<int32_t> &mem, const string &filename)
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
        int tmp;
        stringstream ss(line);
        ss >> hex >> tmp;
        if (ss.fail()) 
        {
            cerr << "⚠️  Invalid line in " << filename << ": " << line << endl;
            continue;
        }
        int8_t val = static_cast<int8_t>(tmp);
        //cout << "load value: " << int32_t(val) << endl;
        mem.push_back(static_cast<int32_t>(val));
    }

    file.close();
}

void load_ipsum_golden(vector<int32_t> &mem, const string &filename)
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
        uint32_t tmp;
        int32_t val;
        stringstream ss(line);
        ss >> hex >> tmp;
        if (ss.fail()) 
        {
            cerr << "⚠️  Invalid line in " << filename << ": " << line << endl;
            continue;
        }
        val = static_cast<int32_t>(tmp);
        //cout << "load value: " << val << endl;
        mem.push_back(val);
    }

    file.close();
}