#include <thread>
#include <chrono>
#include <iostream>

#include "GIN_y.hpp"
#include "PE.hpp"

using namespace std;

int main()
{
    int ROW = 6;
    int COL = 8;    
    GIN_y weight_bus(ROW);
    GIN_y ifmap_bus(ROW);
    GIN_y ipsum_bus(ROW);


    vector<vector<PE>> PE_array(ROW, vector<PE>(COL));

    for(int i = 0; i < ROW; i++)
    {
        for(int j = 0; j < COL; j++)
        {
            PE_array[i][j].reset();
            PE_array[i][j].connect_weight_bus(weight_bus.bus_x[i].get());
            PE_array[i][j].connect_ifmap_bus(ifmap_bus.bus_x[i].get());
            PE_array[i][j].connect_ipsum_bus(ipsum_bus.bus_x[i].get());
            PE_array[i][j].set_tag(i * ROW + j, i, (i < 1)? 1 : 0);//weight_tag, ifmap_tag, ipsum_tag
        }        
    }

    
    vector<thread> pe_threads;

    for(int i = 0; i < ROW; i++)
    {
        for(int j = 0; j < COL; j++)
        {
            pe_threads.emplace_back(&PE::run, &PE_array[i][j]);
        }
    }
    // 傳 12 個 weight 給 row 3 的 PE
    for(int idx = 0; idx < 12; idx++)
    {
        int tag = 0;      // 每個資料用不同 tag
        int data = idx;
        weight_bus.send(0, true, tag, data); // 發送到 row0 的 bus

        cout << "[BUS] Sent weight: tag=" << tag << " data=" << data << endl;

        // 等 PE 讀完再送下一個
        bool sent_done = false;
        while(!sent_done)
        {
            lock_guard<mutex> lock(weight_bus.bus_x[0]->mtx);
            sent_done = !weight_bus.bus_x[0]->bus_valid; // 被 PE 清掉表示已讀
        }
    }
    PE_array[0][0].dump();
        // === 結束測試 ===
    cout << "Press CTRL+C to stop." << endl;

    for(auto &t : pe_threads)
        t.join();
    
    return 0;
}