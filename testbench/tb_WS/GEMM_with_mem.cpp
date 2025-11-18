#include "../GEMM_base.hpp"
#include "../../analayzer/analayzer_WS/mapper.cpp"

class WS_Based_with_mem_Simulator : public GEMM_base 
{
    public:
        void create_mapper() override 
        {
            mapper = make_unique<EyerissMapper_WS>();  // ✅ 改成 WS 版本
        }
        
        void run(const LinearShapeParam& linear, const string& pattern, string log_path = "") override
        {
            cout << "\n=======================================" << endl;
            cout << "=Weight Stationary With Mem SIMULATION=" << endl;
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
            int DRAM_ifmap_base = 0;
            int DRAM_weight_base = DRAM_ifmap_base + all_in_features.size();//in_div4 * shape.B;
            int DRAM_PSUM_base = DRAM_weight_base + all_weights.size();

            int GLB_ifmap_base = 0;
            int GLB_weight_base = GLB_ifmap_base + map.K * PE::IFMAP_SIZE * map.M;
            int GLB_psum_base = GLB_weight_base + map.K * PE::IFMAP_SIZE * map.N * PE::WEIGHT_H;

            reset_cycle();
            setup_pe_bases();
            cout << "\n=== Start GEMM Tile Simulation ===" << endl;

            // 外層 tiling 順序依據 PDF：K → N → M → B → in_feature → out_feature
            int in_div4 = ceil(double(shape.in_features) / 4);
            
            cout << "batch: " << shape.B << ", in: " << shape.in_features << ", out_features: " << shape.out_features << endl;
            load_cycles += DRAM_ACCESS * PE::IFMAP_SIZE * map.mode * map.tk * map.M;
            load_cycles += DRAM_ACCESS * PE::WEIGHT_SIZE * PE_Array::NUM_PE;
            for (int outf = 0; outf < shape.out_features; outf += map.N * PE::WEIGHT_H) 
            {
                //cout << "\n--- Processing out_feature tile starting at " << outf << " ---\n";
                //load_cycles += DRAM_ACCESS * map.K * PE::IFMAP_SIZE * map.N * PE::WEIGHT_H; // DRAM access for weight
                
                //load_cycles += DRAM_ACCESS * map.K * PE::IFMAP_SIZE * map.M; // DRAM access for input feature

                //DMA load psum tile to GLB
                int DRAM_PSUM_idx = outf;
                DMA_load_PSUM( GLB,
                               GLB_psum_base,
                               DRAM,
                               DRAM_PSUM_base,
                               DRAM_PSUM_idx,
                               map.N * PE::WEIGHT_H);

                for (int inf = 0; inf < in_div4; inf += map.K * PE::IFMAP_SIZE) 
                {
                    //DMA load weight tile to GLB
                    int DRAM_WEIGHT_idx = (inf * shape.out_features + outf);
                    DMA_load_WEIGHT( GLB,
                                     GLB_weight_base,
                                     DRAM,
                                     DRAM_weight_base,
                                     DRAM_WEIGHT_idx,
                                     map.N * PE::WEIGHT_H);

                    for (int b = 0; b < shape.B; b += map.M) 
                    {
                        //DMA load input feature tile to GLB
                        int DRAM_IFMAP_idx = b * in_div4 + inf;
                        DMA_load_IFMAP( GLB,
                                        GLB_ifmap_base,
                                        DRAM,
                                        DRAM_ifmap_base,
                                        DRAM_IFMAP_idx,
                                        map.K * PE::IFMAP_SIZE);

                        for (int k = 0; k < map.K * PE::IFMAP_SIZE; k += map.tk * PE::IFMAP_SIZE) 
                        {
                            for (int n = 0; n < map.N * PE::WEIGHT_H; n += map.tn * PE::WEIGHT_H) 
                            {
                                //cout << "read weight\n";
                                //set weight
                                load_cycles += 1202;
                                for(int l = 0; l < PE::WEIGHT_SIZE * map.tn * map.tk * map.mode; l++)
                                {
                                    int pe_index = (l / PE::WEIGHT_SIZE) % PE_Array::PE_V * PE_Array::PE_H 
                                                    + (l / PE::WEIGHT_SIZE / PE_Array::PE_V);
                                    int idx_w = GLB_weight_base + k * map.N * PE::WEIGHT_H + n;
                                    int weight_index = idx_w + l % PE::WEIGHT_H 
                                                        + ((l / PE::WEIGHT_H) % (map.tk * PE::IFMAP_SIZE)) * map.N * PE::WEIGHT_H 
                                                        + (l / PE::WEIGHT_SIZE / PE_Array::PE_V) * PE::WEIGHT_H;
                                    int weight_data;
                                    weight_data = GLB[weight_index];
                                    //cout << "PE[" << pe_index << "] load weight from index[" << weight_index << "]\n";
                                    pe_array.pe[pe_index].weight_spad[l % PE::WEIGHT_SIZE] = weight_data;
                                }
                                // load pusm and read input feature & weight & compute

                                for (int m = 0; m < map.M; m += map.mode) 
                                {
                                    //load pusm
                                    //load_cycles += GLB_ACCESS * PSUM_STORE_LAT * map.mode * map.tn;
                                    //cout << "load psum to PE array\n";
                                    for(int i = 0; i < map.tn * map.mode; i++)
                                    {
                                        int num = r_base[i / PE_Array::PE_H] + i % PE_Array::PE_H;
                                        //cout << "\n=== PE[" << num << "] add psum ";
                                        for (int j = 0; j < PE::WEIGHT_H; j++)
                                        {
                                            //in_idx need to be checked
                                            int in_idx = GLB_psum_base + (b * map.N * PE::WEIGHT_H) 
                                                        + (n) + m * map.N * PE::WEIGHT_H + i / map.tn * map.N * PE::WEIGHT_H + (i % map.tn) * PE::WEIGHT_H + j;
                                            int32_t pe_input;

                                            pe_input = GLB[in_idx];
                                            //cout <<"at index["<< in_idx << "], " ;
                                            pe_array.pe[num].add_ipsum(pe_input, j);
                                        }
                                        //cout << endl;

                                    }
                                    
                                    //cout << "read input feature\n";
                                    // 模擬 tile loading
                                    //load_cycles += GLB_ACCESS * map.mode * map.tk * IF_LOAD_LAT;
                        
                                    // 模擬 tile compute (乘加)
                                    //compute_cycles += COMPUTE_LAT;

                                    //呼叫 PE 模型做實際運算

                                    //set input feature
                                    //cout << "read in_feature\n";
                                    for(int l = 0; l < PE::IFMAP_SIZE * map.tk * map.mode; l++)
                                    {
                                        int idx_f = GLB_ifmap_base + m * map.K * PE::IFMAP_SIZE + k;
                                        //cout << "GLB_ifmap_base: " << GLB_ifmap_base << ", m: " << m << ", map.K: " << map.K << ", PE::IFMAP_SIZE: " << PE::IFMAP_SIZE << ", k: " << k << endl;
                                        for(int i = 0; i < map.tn; i++)
                                        {
                                            int pe_index = i + (l / PE::IFMAP_SIZE) * PE_Array::PE_H;
                                            int inf_index = idx_f + (l / map.tk / PE::IFMAP_SIZE * map.K * PE::IFMAP_SIZE) + l % (map.tk * PE::IFMAP_SIZE);
                                            int in_data;
                                            in_data = GLB[inf_index];
                                            //cout << "GLB[" << inf_index << "]: " << in_data << endl;
                                            //cout << "PE[" << pe_index << "]" <<".[" << l % PE::IFMAP_SIZE << "] " << "load in_feature from index[" << inf_index << "]\n";
                                            pe_array.pe[pe_index].in_feature_spad[l % PE::IFMAP_SIZE] = in_data;                                            
                                        }

                                    }

                                    //compute
                                    //cout << "start compute\n";
                                    pe_array.compute_full_all();

                                    //cout << "write back psum\n";
                                    // write psum(acc and store)
                                    compute_cycles += (m >= 1)? 64 : 0;
                                    //load_cycles += GLB_ACCESS * PSUM_STORE_LAT * map.mode * map.tn;
                                    // accumulate psum
                                    pe_array.out_valid_all();
                                    pe_array.add_ipsum_all();

                                    //write back to GLB
                                    for(int i = 0; i < map.tn * map.mode; i++)
                                    {
                                        int num = w_base[i / PE_Array::PE_H] + i % PE_Array::PE_H;
                                        //cout << "\n=== PE[" << num << "] Output ===\n";
                                        for (int j = 0; j < PE::WEIGHT_H; j++)
                                        {
                                            int32_t pe_output = pe_array.pe[num].output_psum(j);
                                            //out_idx need to be checked
                                            int out_idx = GLB_psum_base + (b * map.N * PE::WEIGHT_H) 
                                                        + (n) + m * map.N * PE::WEIGHT_H + i / map.tn * map.N * PE::WEIGHT_H + (i % map.tn) * PE::WEIGHT_H + j;
                                            
                                            GLB[out_idx] = pe_output;
                                            //cout << "GLB[" << out_idx << "] = " << pe_output << endl;
                                            
                                        }
                                        pe_array.pe[num].out_valid = false; // reset out_valid after reading
                                        pe_array.pe[num].reset_psum();
                                    }
                                }

                            }
                        }
                        //load_cycles += DRAM_ACCESS * map.K * PE::IFMAP_SIZE * map.M; // DRAM access for input feature
                    }
                    //load_cycles += DRAM_ACCESS * map.K * PE::IFMAP_SIZE * map.M; // DRAM access for input feature
                    //load_cycles += DRAM_ACCESS * map.K * PE::IFMAP_SIZE * map.N * PE::WEIGHT_H; // DRAM access for weight
                }

                //DMA write back psum tile to DRAM
                DMA_write_PSUM( DRAM,
                                DRAM_PSUM_base,
                                GLB,
                                GLB_psum_base,
                                DRAM_PSUM_idx,
                                map.N * PE::WEIGHT_H);

                load_cycles += DRAM_ACCESS * shape.B * map.N * PE::WEIGHT_H; // DRAM access for psum
                //cout << "load_cycle += " << DRAM_ACCESS * shape.B * map.N * PE::WEIGHT_H << endl;
            }
            total_cycles = load_cycles + compute_cycles ;
            cout << "=== Simulation Finished ===" << endl << endl;
            //cout << "Total cycles: " << total_cycles << endl;
        }
};

