#include <iostream>
#include <vector>
#include <cstdint>
#include <iomanip>
#include <sstream>
#include <string>
#include <cmath>
#include <array>

#include "../../src/PE/pe_array.cpp"
#include "../../analayzer/mapper.cpp"

using namespace std;
using DataType = int32_t;

void load_data(vector<DataType> &mem, const string &filename);

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
        long long int total_cycles = 0;
        array<int, 6> w_base = {0};
        array<int, 6> r_base = {0};

        

    public:
        TileBasedSimulator(const LinearShapeParam& s, const EyerissMappingParam& m, PE_Array& pe_arr)
            : map(m), shape(s), pe_array(pe_arr) {}

        void run_simulation(const vector<DataType>& all_in_features,
                            const vector<DataType>& all_weights,
                            vector<DataType>& final_psums)
        {
            total_cycles = 0;
            switch (map.mode)
            {
                case 1:
                {
                    w_base[0] = 40;

                    r_base[0] = 0;
                    break;
                }
                case 2:
                {
                    w_base[0] = 16;
                    w_base[1] = 40;

                    r_base[0] = 0;
                    r_base[1] = 24;
                    break;
                }
                case 3:
                {
                    w_base[0] = 8;
                    w_base[1] = 24;
                    w_base[2] = 40;

                    r_base[0] = 0;
                    r_base[1] = 16;
                    r_base[2] = 32;
                    break;
                }
                case 6:
                {
                    r_base[0] = w_base[0] = 0;
                    r_base[1] = w_base[1] = 8;
                    r_base[2] = w_base[2] = 16;
                    r_base[3] = w_base[3] = 24;
                    r_base[4] = w_base[4] = 32;
                    r_base[5] = w_base[5] = 40;
                    break;
                }
            }
            cout << "\n=== Start GEMM Tile Simulation ===" << endl;

            // 外層 tiling 順序依據 PDF：K → N → M → B → in_feature → out_feature
            int in_div4 = ceil(double(shape.in_features) / double(4));
            int n_div4  = ceil(double(shape.out_features) / double(4));
            cout << "in_div4: " << in_div4 << ", out_features: " << shape.out_features << endl;
            for (int outf = 0; outf < n_div4; outf+= map.N * 4) 
            {
                //cout << "\n--- Processing out_feature tile starting at " << outf << " ---\n";
                for (int inf = 0; inf < in_div4; inf += map.K * 3) 
                {
                    for (int b = 0; b < shape.B; b += map.M) 
                    {
                        for (int m = 0; m < map.M; m += map.mode) 
                        {
                            for (int n = 0; n < map.N * 4; n += map.tn * 4) 
                            {
                                //load pusm
                                total_cycles += PSUM_STORE_LAT * map.mode * map.tn;
                                //cout << "load psum to PE array\n";
                                for(int i = 0; i < map.tn * map.mode; i++)
                                {
                                    int num = r_base[i / 8] + i % 8;
                                    //cout << "\n=== PE[" << num << "] add psum ";
                                    for (int j = 0; j < 4; j++)
                                    {
                                        //in_idx need to be checked
                                        int in_idx = (b * shape.out_features + outf * map.N * 4 ) + (n) + m * shape.out_features + i / map.tn * shape.out_features + i * 4 + j;
                                        if (in_idx < 0 || in_idx >= final_psums.size()) 
                                        {
                                            cerr << "ERROR: in_idx out of range: " << in_idx << endl;
                                            cerr << "b: " << b << ", outf: " << outf << ", n: " << n << ", m: " << m << ", i: " << i << ", j: " << j << endl;
                                            exit(1);
                                        }
                                        //cout <<"at index["<< in_idx << "], " ;
                                        int32_t pe_input = final_psums[in_idx];
                                        pe_array.pe[num].add_ipsum(pe_input, j);
                                    }
                                    //cout << endl;
                                }
                                //cout << "read input feature\n";
                                // read input feature & weight & compute
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
                                        int idx_f = (b * in_div4 + m * in_div4 + inf) + k;
                                        for(int i = 0; i < map.tn; i++)
                                        {
                                            int pe_index = i + (l / PE::IFMAP_SIZE) * PE_Array::PE_H;
                                            int inf_index = idx_f + (l / map.tk / PE::IFMAP_SIZE * in_div4) + l % (map.tk * 3);
                                            if (pe_index >= PE_Array::NUM_PE) 
                                            {
                                                cerr << "pe_index out of range: " << pe_index << endl;
                                                exit(1);
                                            }
                                            if (inf_index >= all_in_features.size()) 
                                            {
                                                cerr << "inf_index out of range: " << inf_index << endl;
                                                cerr << "b: " << b << ", m: " << m << ", inf: " << inf << ", k: " << k << ", l: " << l << ", i: " << i << endl;
                                                exit(1);
                                            }
                                            
                                            //cout << "PE[" << pe_index << "]" <<".[" << l % PE::IFMAP_SIZE << "] " << "load in_feature from index[" << inf_index << "]\n";
                                            pe_array.pe[pe_index].in_feature_spad[l % PE::IFMAP_SIZE] = all_in_features[inf_index];                                            
                                        }

                                    }
                                    //cout << "read weight\n";
                                    //set weight
                                    for(int l = 0; l < PE::WEIGHT_SIZE * map.tn * map.tk * map.mode; l++)
                                    {
                                        int pe_index = (l / 12) % 6 * 8 + (l / 12 / 6);
                                        int idx_w = (inf * shape.out_features + outf * map.N * 4) + k * shape.out_features + n;
                                        int weight_index = idx_w + l % 4 + ((l / 4) % 18) * shape.out_features + (l / 72) * 4;

                                        if (pe_index >= PE_Array::NUM_PE) 
                                        {
                                            cerr << "pe_index out of range: " << pe_index << endl;
                                            exit(1);
                                        }
                                        if (weight_index >= all_weights.size()) 
                                        {
                                            cerr << "weight_index out of range: " << weight_index << endl;
                                            cerr << "inf: " << inf << ", outf: " << outf << ", k: " << k << ", n: " << n << ", l: " << l << endl;
                                            exit(1);
                                        }
                                        //cout << "PE[" << pe_index << "] load weight from index[" << weight_index << "]\n";
                                        pe_array.pe[pe_index].weight_spad[l % PE::WEIGHT_SIZE] = all_weights[weight_index];
                                    }

                                    //compute
                                    //cout << "start compute\n";
                                    pe_array.compute_full_all();

                                }
                                //cout << "write back psum\n";
                                // write psum(acc and store)
                                total_cycles += PSUM_ACC_LAT;
                                total_cycles += PSUM_STORE_LAT * map.mode * map.tn;
                                // accumulate psum
                                pe_array.add_ipsum_all();
                                // read psum from PE and write back to final_psums
                                for(int i = 0; i < map.tn * map.mode; i++)
                                {
                                    int num = w_base[i / 8] + i % 8;
                                    //cout << "\n=== PE[" << num << "] Output ===\n";
                                    for (int j = 0; j < 4; j++)
                                    {
                                        int32_t pe_output = pe_array.pe[num].output_psum(j);
                                        //out_idx need to be checked
                                        int out_idx = (b * shape.out_features + outf * map.N * 4 ) + (n) + m * shape.out_features + i / map.tn * shape.out_features + i * 4 + j;
                                        if (out_idx < 0 || out_idx >= final_psums.size()) 
                                        {
                                            cerr << "ERROR: out_idx out of range: " << out_idx << endl;
                                            exit(1);
                                        }
                                        final_psums[out_idx] = pe_output;
                                    }
                                    pe_array.pe[num].out_valid = false; // reset out_valid after reading
                                    pe_array.pe[num].reset_psum();
                                }
                            }
                        }
                    }
                }
            }

            cout << "=== Simulation Finished ===" << endl << endl;
            //cout << "Total cycles: " << total_cycles << endl;
        }

        long long get_total_cycles() 
        { 
            return total_cycles; 
        }
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
    cout << "[Testbench] Initializing DUT (PE_Array)..." << endl;
    PE_Array dut_pe_array;
    dut_pe_array.mode = mapper.best_result.mode;
    dut_pe_array.set_tag();
    TileBasedSimulator dut_controller(linear, mapping, dut_pe_array);

    // 3. 準備測試資料
    vector<DataType> in_features;
    vector<DataType> weights;
    vector<DataType> psum_dut(linear.B * linear.out_features, 0);
    vector<DataType> golden;

    cout << "[Testbench] Loading Test Data..." << endl;
    string pattern = "Pattern3";
    string base_path = "../Pattern/" + pattern + "/";
    load_data(in_features, base_path + "A.txt");
    load_data(weights, base_path + "B.txt");
    load_data(golden, base_path + "C_golden.txt");

    int padded_in_size = ((linear.in_features / 4 + 17) / 18) * 18;
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


    // 4. 執行 DUT 模擬 (Cycle-Accurate)
    cout << "[Testbench] Starting DUT (PE_Array) Simulation..." << endl;

    dut_controller.run_simulation(padded_in_features, padded_weights, psum_dut);


    // 5. 報告與驗證
    cout << "=======================================" << endl;
    cout << "=          SIMULATION REPORT          =" << endl;
    cout << "=======================================" << endl;
    
    long long final_cycles = dut_controller.get_total_cycles();
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
                cout << "First Mismatch at index " << i << ": DUT=" << psum_dut[i] << ", Golden=" << golden[i] << endl;
                break;
            }
        }
    }
    cout << "=======================================\n" << endl;

    mapper.best_result.cycles = final_cycles;
    mapper.mapping_to_csv_with_cycle("../../log/GEMM_no_mem_results.csv");

    return 0;
}



void load_data(vector<DataType> &mem, const string &filename)
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