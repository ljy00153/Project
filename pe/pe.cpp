#include <iostream>
#include <vector>
#include <cstdint>
#include <iomanip>
#include <cstring>
#include <array>
using namespace std;

class PE 
{
    public:
        static constexpr int IFMAP_SIZE  = 3;  // 4 bytes
        static constexpr int WEIGHT_SIZE = 12;  // 4 bytes
        static constexpr int PSUM_SIZE   = 4;  // 4 bytes (store 4x int32)

        // scratchpad memories
        // in_feature use 12 bytes
        // weight use 48 bytes and reuse 12 bytes of in_feature
        int32_t  in_feature_spad[IFMAP_SIZE];
        int32_t  weight_spad[WEIGHT_SIZE];
        int32_t psum_spad[PSUM_SIZE];

        //tag
        int tag;

        // internal state for cycle simulation
        int weight_idx;   // current filter index
        int if_idx;       // current input feature index
        int cal_idx;      // current calculation index (0~3)
        bool busy;
        bool out_valid;

        int cycle; // current cycle

        PE() 
        {
            reset();
        }

        // reset everything
        void reset() 
        {
            memset(in_feature_spad, 0, sizeof(in_feature_spad));
            memset(weight_spad, 0, sizeof(weight_spad));
            memset(psum_spad, 0, sizeof(psum_spad));
            weight_idx = 0;
            if_idx = 0;
            cal_idx = 0;
            busy = false;
            out_valid = false;
            tag = 0;
            cycle = 0;
        }
        //set tag
        void set_tag(int t) 
        {
            tag = t;
        }

        // show spad contents
        void dump() const 
        {
            cout << "IFMAP: "<< "\n";
            for (int i = 0; i < IFMAP_SIZE; i++) 
            {
                for(int j = 0; j < 4; j++)
                    cout << setw(10) << (int)((in_feature_spad[i] >> 8*j)  & 0xFF);
                cout << "\n";
            }
            cout << "\nFILTER:"<< "\n";
            for (int i = 0; i < WEIGHT_SIZE; i++) 
            {
                for(int j = 0; j < 4; j++)
                    cout << setw(10) << (int)((weight_spad[i] >> 8*j)  & 0xFF);
                cout << "\n";
            }
            cout << "\nPSUM:  "<< "\n";
            for (int i = 0; i < PSUM_SIZE; i++) 
            {
                cout << setw(10) << psum_spad[i];
            }
            cout << "\n";
        }

        // compute in one shot (mode=0 use input psum, mode=1 accumulate into psum_spad)
        void compute_full() 
        {
            if(out_valid)
            {
                cerr << "Warning: PE compute_full() called but output not read yet!\n";
                return;
            }
                
            for(int i = 0; i < IFMAP_SIZE; i++) 
            {
                array<uint8_t, 4> in_feature_byte = get_bytes(in_feature_spad[i]);
                //in_feature_byte[0] = (in_feature_byte[i] >> 0)  & 0xFF;  // 取最低 8 bit
                //in_feature_byte[1] = (in_feature_byte[i] >> 8)  & 0xFF;  // 取第 8~15 bit
                //in_feature_byte[2] = (in_feature_byte[i] >> 16) & 0xFF;  // 取第 16~23 bit
                //in_feature_byte[3] = (in_feature_byte[i] >> 24) & 0xFF;  // 取最高 8 bit

                for(int j = 0; j <= WEIGHT_SIZE / 4; j++)
                {
                    array<uint8_t, 4> weight_byte = get_bytes(weight_spad[i * PSUM_SIZE + j]);
                    //weight_byte[0] =(weight_byte[i + j * 3] >> 0)  & 0xFF;  // 取最低 8 bit
                    //weight_byte[1] =(weight_byte[i + j * 3] >> 8)  & 0xFF;  // 取第 8~15 bit
                    //weight_byte[2] =(weight_byte[i + j * 3] >> 16) & 0xFF;  // 取第 16~23 bit
                    //weight_byte[3] =(weight_byte[i + j * 3] >> 24) & 0xFF;  // 取最高 8 bit

                    for(int k = 0; k < 4; k++)
                    {
                        int prod = in_feature_byte[k] * weight_byte[k];
                        psum_spad[j] += prod;
                        cycle++;
                    }
                }
            }
            out_valid = true;
        }
        int get_cycle() const 
        {
            return cycle;
        }

        // start cycle-based compute
        void start_cycle_compute() 
        {
            weight_idx = 0;
            busy = true;
        }

        // do one MAC per cycle
        // mode=0: use input psum, mode=1: accumulate
        void step_cycle()
        {
            if (!busy) return;

            int i = if_idx;
            int j = weight_idx;
            int k = cal_idx;
            
            array<uint8_t, 4> in_feature_byte = get_bytes(in_feature_spad[i]);

            array<uint8_t, 4> weight_byte = get_bytes(weight_spad[i * PSUM_SIZE + j]);

            int prod = in_feature_byte[k] * weight_byte[k];

            psum_spad[weight_idx] += prod;

            cal_idx++;
            if (cal_idx == 4) 
            {
                cal_idx = 0;
                weight_idx++;
            }
            if (weight_idx == 4)
            {
                weight_idx = 0;
                if_idx++;
            }
            if (if_idx == IFMAP_SIZE) 
            {
                busy = false; // done
                out_valid = true;
                if_idx = 0;
                cal_idx = 0;
                weight_idx = 0;
            }

            cycle++;
        }
        
        bool is_busy() const 
        {
            return busy;
        }

        int32_t output_psum(int op_idx)  
        {
            return psum_spad[op_idx];
        }

        void reset_psum() 
        {
            memset(psum_spad, 0, sizeof(psum_spad));
        }

        void add_ipsum(int32_t psum_input, int ip_idx)
        {
            psum_spad[ip_idx] += psum_input;
        }

        array<uint8_t, 4> get_bytes(int32_t value) 
        {
            array<uint8_t, 4> bytes{};
            for (int i = 0; i < 4; ++i)
                bytes[i] = (value >> (8 * i)) & 0xFF;
            //may need to dequantize here
            return bytes;
        }

};
