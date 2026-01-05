#include <iostream>
#include <vector>
#include <cstdint>
#include <iomanip>
#include <cstring>
#include <array>
#include <thread>
#include <chrono>
#include "GIN_x.hpp"
using namespace std;

class PE 
{
    public:
        static constexpr int IFMAP_SIZE  = 3;  // 4 bytes
        static constexpr int WEIGHT_H  = 4;  // 4 bytes
        static constexpr int WEIGHT_V  = IFMAP_SIZE;  // 4 bytes
        static constexpr int WEIGHT_SIZE = 12;  // 4 bytes
        static constexpr int PSUM_SIZE   = 4;  // 4 bytes (store 4x int32)

        // scratchpad memories
        // in_feature use 12 bytes
        // weight use 48 bytes and reuse 12 bytes of in_feature
        int32_t  in_feature_spad[IFMAP_SIZE];
        int32_t  weight_spad[WEIGHT_SIZE];
        int32_t psum_spad[PSUM_SIZE];

        //tag
        int weight_tag;
        int ifmap_tag;
        int ipsum_tag;

        // internal state for cycle simulation
        int weight_idx = 0;   // current filter index
        int if_idx = 0;       // current input feature index
        int ipsum_idx = 0;
        int opsum_idx = 0;
        int cal_idx;      // current calculation index (0~3)
        bool busy;
        bool out_valid;

        int cycle = 0; // current cycle

        //bus signals
        GIN_x* weight_bus_x = nullptr;
        GIN_x* ifmap_bus_x  = nullptr;
        GIN_x* ipsum_bus_x  = nullptr;
        int bus_weight_tag, bus_ifmap_tag, bus_ipsum_tag;

        bool opsum_valid; int opsum_data;

        bool ifmap_req;
        bool weight_req;
        bool ipsum_req;
        bool opsum_req;

        bool weight_done = false;
        bool ifmap_done = false;
        bool ipsum_done = false;
        bool opsum_done = false;

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
            weight_tag = 0;
            ifmap_tag = 0;
            ipsum_tag = 0;
            cycle = 0;
        }
        //set tag
        void set_tag(int weight_t, int ifmap_t, int ipsum_t)
        {
            weight_tag = weight_t;
            ifmap_tag = ifmap_t;
            ipsum_tag = ipsum_t;
        }

        void connect_weight_bus(GIN_x* bx)
        {
            weight_bus_x = bx;
        }

        void connect_ifmap_bus(GIN_x* bx)
        {
            ifmap_bus_x = bx;
        }

        void connect_ipsum_bus(GIN_x* bx)
        {
            ipsum_bus_x = bx;
        }

        void run()
        {
            const int MAX_CYCLE = 200000;
            int local_cycle = 0;

            while(local_cycle < MAX_CYCLE)
            {
                int weight_data_local = 0;
                int ifmap_data_local = 0;
                int ipsum_data_local = 0;

                bool got_weight = false;
                bool got_ifmap = false;
                bool got_ipsum = false;

                // 嘗試從 bus 讀資料，最多等 1ms 避免永久阻塞
                if(weight_bus_x)
                {
                    unique_lock<mutex> lock(weight_bus_x->mtx);
                    if(weight_bus_x->cv.wait_for(lock, chrono::milliseconds(1),
                                                [&]{ return weight_bus_x->bus_tag == weight_tag && weight_bus_x->bus_valid; }))
                    {
                        weight_data_local = weight_bus_x->bus_data;
                        weight_bus_x->bus_valid = false; // 標記已被讀
                        got_weight = true;
                    }
                }

                if(ifmap_bus_x)
                {
                    unique_lock<mutex> lock(ifmap_bus_x->mtx);
                    if(ifmap_bus_x->cv.wait_for(lock, chrono::milliseconds(1),
                                                [&]{ return ifmap_bus_x->bus_tag == ifmap_tag && ifmap_bus_x->bus_valid; }))
                    {
                        ifmap_data_local = ifmap_bus_x->bus_data;
                        ifmap_bus_x->bus_valid = false;
                        got_ifmap = true;
                    }
                }

                if(ipsum_bus_x)
                {
                    unique_lock<mutex> lock(ipsum_bus_x->mtx);
                    if(ipsum_bus_x->cv.wait_for(lock, chrono::milliseconds(1),
                                                [&]{ return ipsum_bus_x->bus_tag == ipsum_tag && ipsum_bus_x->bus_valid; }))
                    {
                        ipsum_data_local = ipsum_bus_x->bus_data;
                        ipsum_bus_x->bus_valid = false;
                        got_ipsum = true;
                    }
                }

                // 將讀到的資料寫入 local buffer
                read_data(got_weight, weight_data_local,
                        got_ifmap, ifmap_data_local,
                        got_ipsum, ipsum_data_local);

                // 如果所有資料完成就計算
                if(ipsum_done)
                {
                    compute_full();
                }

                // 重置 done flag，準備下一輪
                if(opsum_done)
                {
                    weight_done = false;
                    ifmap_done = false;
                    ipsum_done = false;
                    opsum_done = false;
                }

                local_cycle++;

                // 模擬 1 cycle
                this_thread::sleep_for(chrono::nanoseconds(1));
            }

            cout << "[PE] Finished run after " << local_cycle << " cycles\n";
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

        void read_data(const bool &weight_valid, const int &weight_data,
                       const bool &ifmap_valid, const int &ifmap_data,
                       const bool &psum_valid, const int &psum_data)
        {
            if(!weight_done)
            {
                weight_req = 1;
                if(weight_valid)
                {
                    cout << "[PE] PE received weight data: " << weight_data << "\n";
                    cout << "[PE] weight_idx: " << weight_idx << "\n";
                    weight_spad[weight_idx] = weight_data;
                    weight_idx++;
                    if(weight_idx == WEIGHT_SIZE)
                    {
                        weight_done = true;
                        weight_req = 0;
                        weight_idx = 0;
                    }
                }
            }
            else if(!ifmap_done)
            {
                ifmap_req = 1;
                if(ifmap_valid)
                {
                    cout << "[PE] PE received ifmap data: " << ifmap_data << "\n";
                    in_feature_spad[if_idx] = ifmap_data;
                    if_idx++;
                    if(if_idx == IFMAP_SIZE)
                    {
                        ifmap_done = true;
                        ifmap_req = 0;
                        if_idx = 0;
                    }
                }
            }
            else if(!ipsum_done)
            {
                ipsum_req = 1;
                if(psum_valid)
                {
                    cout << "[PE] PE received ipsum data: " << psum_data << "\n";
                    psum_spad[ipsum_idx] = psum_data;
                    ipsum_idx++;
                    if(ipsum_idx == PSUM_SIZE)
                    {
                        ipsum_done = true;
                        ipsum_req = 0;
                        ipsum_idx = 0;
                    }
                }
            }
        }

        void output_data(bool &opsum_valid, int &opsum_data)
        {
            static int opsum_idx = 0;
            if(opsum_idx < PSUM_SIZE)
            {
                opsum_req = 1;
                opsum_valid = 1;
                opsum_data = psum_spad[opsum_idx];
                opsum_idx++;
                if(opsum_idx == PSUM_SIZE)
                {
                    opsum_req = 0;
                    opsum_idx = 0;
                }
            }
            else
            {
                opsum_valid = 0;
            }
        }

        // compute in one shot (mode=0 use input psum, mode=1 accumulate into psum_spad)
        void compute_full() 
        {
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
