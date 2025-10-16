#include <iostream>
#include <vector>
#include <cstdint>
#include <iomanip>
#include <sstream>
#include <string>
#include <cmath>

#include "../../src/PE/pe_array.cpp"
#include "../analayzer/mapper.cpp"

using namespace std;
using DataType = int32_t;



class TileBasedSimulator 
{
    private:
        EyerissMappingParam map;
        LinearShapeParam shape;
        PE_Array& pe_array;

        // latency 模型 (可微調)
        static constexpr int IF_LOAD_LAT     = 3;
        static constexpr int W_LOAD_LAT      = 12;
        static constexpr int COMPUTE_LAT     = 48;  // 每個K step
        static constexpr int PSUM_ACC_LAT    = 6;
        static constexpr int PSUM_STORE_LAT  = 4;

        long long total_cycles = 0;

    public:
        TileBasedSimulator(const LinearShapeParam& s, const EyerissMappingParam& m, PE_Array& pe_arr)
            : map(m), shape(s), pe_array(pe_arr) {}

        void run_simulation(const vector<DataType>& all_in_features,
                            const vector<DataType>& all_weights,
                            vector<DataType>& final_psums)
        {
            total_cycles = 0;
            cout << "=== Start GEMM Tile Simulation ===" << endl;

            // 外層 tiling 順序依據 PDF：K → N → M → B → in_feature → out_feature
            int in_div4 = ceil(double(shape.in_features) / double(4));
            int n_div4  = ceil(double(shape.out_features) / double(4));
            for (int outf = 0; outf < shape.out_features; outf++) 
            {
                for (int inf = 0; inf < shape.in_features; inf++) 
                {
                    for (int b = 0; b < shape.B; b++) 
                    {
                        for (int m = 0; m < map.M; m += map.mode) 
                        {
                            for (int n = 0; n < map.N * 4; n += map.tn) 
                            {
                                for (int k = 0; k < map.K * 3; k += map.tk * 3) 
                                {
                                    // 模擬 tile loading
                                    total_cycles += map.tk * IF_LOAD_LAT;
                                    total_cycles += map.tk * W_LOAD_LAT;

                                    // 模擬 tile compute (乘加)
                                    total_cycles += COMPUTE_LAT;

                                    //呼叫 PE 模型做實際運算
                                    //set input feature
                                    for(int l = 0; l < PE::IFMAP_SIZE * map.tk * map.mode; l++)
                                    {
                                        int idx_f = (b * in_div4 + m * in_div4 + inf * map.K * 3) + k;
                                        for(int i = 0; i < map.tn; i++)
                                            pe_array.pe[i + (l / PE::IFMAP_SIZE) * PE_Array::PE_H].in_feature_spad[l % PE::IFMAP_SIZE] = 
                                            all_in_features[idx_f + (l / map.tk / PE::IFMAP_SIZE * in_div4) + l % (map.tk * 3)];
                                    }

                                    //set weight
                                    for(int l = 0; l < PE::WEIGHT_SIZE * map.tn * map.tk * map.mode; l++)
                                    {
                                        int idx_w = (inf * n_div4 + outf * map.N * 4) + k * n_div4 + n * map.N * 4;
                                        pe_array.pe[(l / 12) * 8 + (l / 12 / 6)].weight_spad[l % PE::WEIGHT_SIZE] = 
                                        all_weights[idx_w + l % 4 + (l / 4) % 18 * n_div4 + (l / 72) * 4];
                                    }

                                    //compute
                                    pe_array.compute_full_all();

                                }
                                // write psum
                                total_cycles += PSUM_ACC_LAT;
                                total_cycles += PSUM_STORE_LAT * map.mode * map.tn;
                            }
                        }
                    }
                    //load pusm
                    total_cycles += PSUM_STORE_LAT * map.mode * map.tn;
                }
            }

            cout << "=== Simulation Finished ===" << endl;
            cout << "Total cycles: " << total_cycles << endl;
        }

        long long get_total_cycles() const { return total_cycles; }
};


int main() 
{
    EyerissMapper mapper;
    LinearShapeParam linear;
    linear.B = 64;
    linear.in_features = 128 * 8 * 8;
    linear.out_features = 256;

    mapper.run(linear, 1);

    EyerissMappingParam mapping = {mapper.best_result.tk, mapper.best_result.tn, mapper.best_result.mode, 
                                   mapper.best_result.M, mapper.best_result.K, mapper.best_result.N};

    // 2. 初始化 DUT
    PE_Array dut_pe_array;
    dut_pe_array.mode = mapper.best_result.mode;
    dut_pe_array.set_tag();
    TileBasedSimulator dut_controller(linear, mapping, dut_pe_array);

    // 3. 準備測試資料
    vector<DataType> in_features;
    vector<DataType> weights;
    vector<DataType> psum_dut(linear.out_features, 0);
    vector<DataType> golden(linear.out_features, 0);

    load_data(in_features, "../Pattern/Pattern1/A.txt");
    load_data(weights, "../Pattern/Pattern1/B.txt");
    load_data(golden, "../Pattern/Pattern1/C_golden.txt");

    // 4. 執行 DUT 模擬 (Cycle-Accurate)
    cout << "[Testbench] Starting DUT (PE_Array) Simulation..." << endl;

    dut_controller.run_simulation(in_features, weights, psum_dut);


    // 6. 報告與驗證
    cout << "\n=======================================" << endl;
    cout << "=          SIMULATION REPORT          =" << endl;
    cout << "=======================================" << endl;
    
    long long final_cycles = dut_controller.get_total_cycles();
    cout << "Total cycles simulated: " << final_cycles << endl;
    
    bool pass;
    pass = equal(psum_dut.begin(), psum_dut.end(), golden.begin());
    
    cout << "Functional Verification: " << (pass ? "PASSED" : "FAILED") << endl;
    if (!pass) 
    {
        for(size_t i=0; i < psum_dut.size(); i++) 
        {
            if (psum_dut[i] != golden[i]) 
            {
                cout << "First Mismatch at index " << i << ": DUT=" << psum_dut[i] << ", Golden=" << golden[i] << endl;
                break;
            }
        }
    }
    cout << "=======================================\n" << endl;

    return 0;
}



void load_data(vector<DataType> &mem, const string &filename)
{
    ifstream file(filename);
    if (!file.is_open()) 
    {
        cerr << "Error opening file: " << filename << endl;
        return;
    }
    else
        cout << "Successfully open file: " << filename << endl;
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