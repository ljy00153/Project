#pragma once
#include <vector>
#include <mutex>
#include <condition_variable>

using namespace std;

class GIN_x 
{
    private:
        int yid = 0;

    public:
        bool bus_valid = false;
        int bus_tag = 0;
        int bus_data = 0;
        mutex mtx;
        condition_variable cv;

        GIN_x(int Y): yid(Y){}

        void send(int y, int tag, bool valid, int data) 
        {
            if(yid == y)
            {
                {
                    lock_guard<std::mutex> lock(mtx);
                    bus_tag = tag;
                    bus_data = data;
                    bus_valid = valid;
                }
                cv.notify_all();  // 通知所有等待的 PE                
            }
        }

        void wait_and_read(int expected_tag, int &out_data) 
        {
            unique_lock<std::mutex> lock(mtx);
            cv.wait(lock, [&]{ return bus_tag == expected_tag; });
            out_data = bus_data;
            bus_valid = false;  // 標記已被讀
        }
};