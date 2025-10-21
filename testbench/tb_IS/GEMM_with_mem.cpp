#include "../GEMM_base.hpp"
#include "../../analayzer/analayzer_IS/mapper.cpp"

class IS_Based_with_mem_Simulator : public GEMM_base 
{
    public:
        void create_mapper() override 
        {
            mapper = make_unique<EyerissMapper_IS>();  // ✅ 改成 IS 版本
        }
        
        void run(const LinearShapeParam& linear, const string& pattern, string log_path = "") override
        {
            cout << "\n=======================================" << endl;
            cout << "=Input Stationary With Mem SIMULATION=" << endl;
            cout << "=======================================" << endl;
            cout << "\n[Testbench] Initializing DUT (PE_Array)..." << endl;
            GEMM_base::run(linear, pattern, log_path);
        }

    protected:
        static constexpr int GLB_ACCESS  = 2;
        static constexpr int DRAM_ACCESS  = 5;

        void run_simulation(const vector<DataType>& all_in_features,
                            const vector<DataType>& all_weights,
                            vector<DataType>& final_psums) override
        {
            total_cycles = 0;
            setup_pe_bases();
            cout << "\n=== Start GEMM Tile Simulation ===" << endl;

            // 外層 tiling 順序依據 PDF：K → N → M → B → in_feature → out_feature
            int in_div4 = ceil(double(shape.in_features) / double(PE::WEIGHT_H));
            
            cout << "in_div4: " << in_div4 << ", out_features: " << shape.out_features << endl;
            for (int outf = 0; outf < shape.out_features; outf += map.N * PE::WEIGHT_H) 
            {
                //cout << "\n--- Processing out_feature tile starting at " << outf << " ---\n";
                total_cycles += DRAM_ACCESS * shape.B * map.N * PE::WEIGHT_H; // DRAM access for weight
                total_cycles += DRAM_ACCESS * map.K * PE::IFMAP_SIZE * map.M; // DRAM access for input feature
                for (int inf = 0; inf < in_div4; inf += map.K * PE::IFMAP_SIZE) 
                {
                    for (int b = 0; b < shape.B; b += map.M) 
                    {
                        for (int m = 0; m < map.M; m += map.mode) 
                        {
                            for (int n = 0; n < map.N * PE::WEIGHT_H; n += map.tn * PE::WEIGHT_H) 
                            {
                                //load pusm
                                if(inf != 0)
                                {
                                    total_cycles += GLB_ACCESS * PSUM_STORE_LAT * map.mode * map.tn;
                                    //cout << "load psum to PE array\n";
                                    for(int i = 0; i < map.tn * map.mode; i++)
                                    {
                                        int num = r_base[i / PE_Array::PE_H] + i % PE_Array::PE_H;
                                        //cout << "\n=== PE[" << num << "] add psum ";
                                        for (int j = 0; j < PE::WEIGHT_H; j++)
                                        {
                                            //in_idx need to be checked
                                            int in_idx = (b * shape.out_features + outf) 
                                                            + (n) + m * shape.out_features + i / map.tn * shape.out_features + (i % map.tn) * PE::WEIGHT_H + j;
                                            int32_t pe_input;
                                            if (in_idx < 0 || in_idx >= final_psums.size()) 
                                            {
                                                pe_input = 0;
                                                //cout << "ERROR: in_idx out of range: " << in_idx << endl;
                                                //cerr << "b: " << b << ", outf: " << outf << ", n: " << n << ", m: " << m << ", i: " << i << ", j: " << j << endl;
                                                //exit(1);
                                            }
                                            else
                                            {
                                                pe_input = final_psums[in_idx];
                                            }
                                            //cout <<"at index["<< in_idx << "], " ;
                                            pe_array.pe[num].add_ipsum(pe_input, j);
                                        }
                                        //cout << endl;
                                    } 
                                }
                                //cout << "read input feature\n";
                                // read input feature & weight & compute
                                for (int k = 0; k < map.K * PE::IFMAP_SIZE; k += map.tk * PE::IFMAP_SIZE) 
                                {
                                    // 模擬 tile loading
                                    total_cycles += GLB_ACCESS * map.mode * map.tk * IF_LOAD_LAT;//read in_feature
                                    total_cycles += GLB_ACCESS * PE_Array::NUM_PE * W_LOAD_LAT;//read weight

                                    // 模擬 tile compute (乘加)
                                    total_cycles += COMPUTE_LAT;

                                    //呼叫 PE 模型做實際運算
                                    //set input feature
                                    //cout << "read in_feature\n";
                                    for(int l = 0; l < PE::IFMAP_SIZE * map.tk * map.mode; l++)
                                    {
                                        int idx_f = (b * in_div4 + m * in_div4 + inf) + k;
                                        for(int i = 0; i < map.tn; i++)
                                        {
                                            int pe_index = i + (l / PE::IFMAP_SIZE) * PE_Array::PE_H;
                                            int inf_index = idx_f + (l / map.tk / PE::IFMAP_SIZE * in_div4) + l % (map.tk * PE::IFMAP_SIZE);
                                            int in_data;
                                            if (pe_index >= PE_Array::NUM_PE) 
                                            {
                                                cerr << "pe_index out of range: " << pe_index << endl;
                                                exit(1);
                                            }
                                            if (inf_index >= all_in_features.size()) 
                                            {
                                                in_data = 0;
                                                //cout << "inf_index out of range: " << inf_index << endl;
                                                //cerr << "b: " << b << ", m: " << m << ", inf: " << inf << ", k: " << k << ", l: " << l << ", i: " << i << endl;
                                                //exit(1);
                                            }
                                            else
                                            {
                                                in_data = all_in_features[inf_index];
                                            }
                                            
                                            //cout << "PE[" << pe_index << "]" <<".[" << l % PE::IFMAP_SIZE << "] " << "load in_feature from index[" << inf_index << "]\n";
                                            pe_array.pe[pe_index].in_feature_spad[l % PE::IFMAP_SIZE] = in_data;                                            
                                        }

                                    }
                                    //cout << "read weight\n";
                                    //set weight
                                    for(int l = 0; l < PE::WEIGHT_SIZE * map.tn * map.tk * map.mode; l++)
                                    {
                                        int pe_index = (l / PE::WEIGHT_SIZE) % PE_Array::PE_V * PE_Array::PE_H 
                                                        + (l / PE::WEIGHT_SIZE / PE_Array::PE_V);
                                        int idx_w = (inf * shape.out_features + outf) + k * shape.out_features + n;
                                        int weight_index = idx_w + l % PE::WEIGHT_H 
                                                            + ((l / PE::WEIGHT_H) % (map.tk * PE::IFMAP_SIZE)) * shape.out_features 
                                                            + (l / PE::WEIGHT_SIZE / PE_Array::PE_V) * PE::WEIGHT_H;
                                        int weight_data;
                                        if (pe_index >= PE_Array::NUM_PE) 
                                        {
                                            cerr << "pe_index out of range: " << pe_index << endl;
                                            exit(1);
                                        }
                                        if (weight_index >= all_weights.size()) 
                                        {
                                            weight_data = 0;
                                            //cout << "weight_index out of range: " << weight_index << endl;
                                            //cerr << "inf: " << inf << ", outf: " << outf << ", k: " << k << ", n: " << n << ", l: " << l << endl;
                                            //exit(1);
                                        }
                                        else
                                        {
                                            weight_data = all_weights[weight_index];
                                        }
                                        //cout << "PE[" << pe_index << "] load weight from index[" << weight_index << "]\n";
                                        pe_array.pe[pe_index].weight_spad[l % PE::WEIGHT_SIZE] = weight_data;
                                    }

                                    //compute
                                    //cout << "start compute\n";
                                    pe_array.compute_full_all();

                                }
                                //cout << "write back psum\n";
                                // write psum(acc and store)
                                total_cycles += PSUM_ACC_LAT;
                                //write back psum to GLB
                                total_cycles += GLB_ACCESS * PSUM_STORE_LAT * map.mode * map.tn;
                                // accumulate psum
                                pe_array.out_valid_all();
                                pe_array.add_ipsum_all();
                                // read psum from PE and write back to final_psums
                                for(int i = 0; i < map.tn * map.mode; i++)
                                {
                                    int num = w_base[i / PE_Array::PE_H] + i % PE_Array::PE_H;
                                    //cout << "\n=== PE[" << num << "] Output ===\n";
                                    for (int j = 0; j < PE::WEIGHT_H; j++)
                                    {
                                        int32_t pe_output = pe_array.pe[num].output_psum(j);
                                        //out_idx need to be checked
                                        int out_idx = (b * shape.out_features + outf) + (n) + m * shape.out_features + i / map.tn * shape.out_features + (i % map.tn) * PE::WEIGHT_H + j;
    
                                        if (out_idx < final_psums.size()) 
                                        {
                                            final_psums[out_idx] = pe_output;
                                        }
                                        else
                                        {
                                            //cout << "ERROR: out_idx out of range: " << out_idx << endl;
                                            //exit(1);
                                        }
                                        
                                    }
                                    pe_array.pe[num].out_valid = false; // reset out_valid after reading
                                    pe_array.pe[num].reset_psum();
                                }
                            }
                        }
                        total_cycles += DRAM_ACCESS * map.K * PE::IFMAP_SIZE * map.M; // DRAM access for input feature
                    }
                    total_cycles += DRAM_ACCESS * map.K * PE::IFMAP_SIZE * map.M; // DRAM access for input feature
                    total_cycles += DRAM_ACCESS * map.K * PE::IFMAP_SIZE * map.N * PE::WEIGHT_H; // DRAM access for weight
                }
            }

            cout << "=== Simulation Finished ===" << endl << endl;
            //cout << "Total cycles: " << total_cycles << endl;
        }
};

