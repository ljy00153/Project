#include <iostream>
#include <vector>
#include <cstdint>
#include <iomanip>
#include <cstring>
#include <array>
#include "pe.cpp"
using namespace std;

class PE_Array 
{
    public:
        static constexpr int NUM_PE = 48;
        int mode;
        //1: 6個PE累加，共一組
        //2: 3個PE累加，共兩組
        //3: 2個PE累加，共三組
        //4: 1個PE累加，共六組

        PE pe[NUM_PE];

        PE_Array() 
        {
            // constructor
            reset();
        }

        // reset all PEs
        void reset() 
        {
            for (int i = 0; i < NUM_PE; i++) 
            {
                pe[i].reset();
            }
        }
        //set tag for a specific PE
        void set_tag() 
        {
            //pe[pe_index].set_tag(t);
            switch (mode)
            {
                case 1:
                {   //1: 6個PE累加，共一組
                    for(int i = 0; i < PE_Array::NUM_PE; i++)
                        pe[i].tag = i % 8; // set same tag for PE[0]~PE[7]
                    break;
                }
                case 2:
                {   //2: 3個PE累加，共兩組
                    for(int i = 0; i < PE_Array::NUM_PE; i++)
                    {
                        if(i < 24)
                            pe[i].tag = i % 8;
                        else
                            pe[i].tag = i % 8 + 8;
                    }
                    break;
                }
                case 3:
                {   //3: 2個PE累加，共三組
                    for(int i = 0; i < PE_Array::NUM_PE; i++)
                    {
                        if(i < 16)
                            pe[i].tag = i % 8;
                        else if(i >= 16 && i < 32)
                            pe[i].tag = i % 8 + 8;
                        else
                            pe[i].tag = i % 8 + 16;
                    }
                    break;
                }
                case 6:
                {   //4: 1個PE累加，共六組
                    for(int i = 0; i < PE_Array::NUM_PE; i++)
                        pe[i].tag = i;
                    break;
                }
            }
        }

        // dump all PEs
        void dump_all() const 
        {
            for (int i = 0; i < NUM_PE; i++) 
            {
                cout << "PE[" << i << "] state:\n";
                pe[i].dump();
                cout << "---------------------\n";
            }
        }
        void dump(int pe_index) const 
        {
            if (!check_valid_pe(pe_index)) 
            {
                cerr << "Invalid PE index\n";
                return;
            }
            cout << "PE[" << pe_index << "] state:\n";
            pe[pe_index].dump();
            cout << "---------------------\n";
        }
        //set input feature for a specific PE
        void set_input_feature(int pe_index, const array<int32_t, PE::IFMAP_SIZE>& input_feature) 
        {
            if (!check_valid_pe(pe_index)) 
            {
                cerr << "Invalid PE index\n";
                return;
            }
            if (input_feature.size() != PE::IFMAP_SIZE) 
            {
                cerr << "Input feature size mismatch\n";
                return;
            }
            for (int i = 0; i < PE::IFMAP_SIZE; i++) 
            {
                pe[pe_index].in_feature_spad[i] = input_feature[i];
            }
        }
        //set weights for a specific PE
        void set_weights(int pe_index, const array<int32_t, PE::WEIGHT_SIZE>& weights) 
        {
            if (!check_valid_pe(pe_index)) 
            {
                cerr << "Invalid PE index\n";
                return;
            }
            if (weights.size() != PE::WEIGHT_SIZE) 
            {
                cerr << "Weights size mismatch\n";
                return;
            }
            for (int i = 0; i < PE::WEIGHT_SIZE; i++) 
            {
                pe[pe_index].weight_spad[i] = weights[i];
            }
        }

        // full compute on all PEs and NOC
        void compute_full(int pe_index) 
        {
            pe[pe_index].compute_full();
        }

        void compute_full_all() 
        {
            for (int i = 0; i < NUM_PE; i++) 
                pe[i].compute_full();
        }

        void add_ipsum_all() 
        {
            for (int i = 0; i < NUM_PE; i++) 
            {
                if(i > 7)
                {
                    if(pe[i].tag == pe[i-8].tag)
                    {
                        cout << "PE[" << i << "] accumulates from PE[" << i-8 << "]\n";
                        for(int j = 0; j < PE::PSUM_SIZE; j++)
                        {
                            if(pe[i-8].out_valid)
                                pe[i].add_ipsum(pe[i-8].output_psum(j), j);
                            //cout << pe[i-8].output_psum(j) << " added to PE[" << i << "] PSUM[" << j << "]\n";
                            //cout << "After accumulation, PE[" << i << "] PSUM[" << j << "] = " << pe[i].psum_spad[j] << "\n";
                        }
                        pe[i-8].out_valid = false; // reset out_valid after accumulation
                        pe[i-8].reset_psum(); // reset psum_spad after accumulation
                    }
                }
            }
        }


        // check if any PE is busy
        bool is_any_busy() const 
        {
            for (int i = 0; i < NUM_PE; i++) 
            {
                if (pe[i].is_busy()) return true;
            }
            return false;
        }

        // step all PEs by one cycle
        void step_all() 
        {
            for (int i = 0; i < NUM_PE; i++) 
            {
                pe[i].step_cycle();
            }
        }

        bool check_valid_pe(int pe_index) const 
        {
            return (pe_index >= 0 && pe_index < NUM_PE);
        }

};