#include <iostream>
#include <vector>
#include <stdexcept>


using namespace std;

class memory 
{
    public:
        int access_cycles;
        int read_cycles = 0;
        int write_cycles = 0;
        int size;
        bool read_busy = false;
        bool write_busy = false;
        bool read_done = false;
        bool write_done = false;
        
        vector<int> mem;
        int read_value = 0;
        memory(int access_cycles) : access_cycles(access_cycles)
        {
           
        }

        void write(int address, int data) 
        {
            if(read_done)
                read_done = false;
            if (address >= 0 && address < size) 
            {
                write_busy = true;
                mem[address] = data;
            } 
            else 
            {
                cerr << "Write Error: Address out of bounds" << endl;
            }
        }

        void read(int address) 
        {
            if(read_done)
                read_done = false;
            if (address >= 0 && address < size) 
            {
                read_busy = true;
                read_value = mem[address];
            } 
            else 
            {
                cerr << "Read Error: Address out of bounds" << endl;
            }
        }

        void step_cycle()
        {
            if(read_busy)
                read_cycles++;

            if(write_busy)
                write_cycles++;

            if(read_cycles == access_cycles) 
            {
                if(read_busy)
                {
                    read_done = true;
                    read_busy = false;
                }
                read_cycles = 0;
            }

            if(write_cycles == access_cycles) 
            {
                if(write_busy)
                {
                    write_done = true;
                    write_busy = false;
                }
                write_cycles = 0;
            }

            //cout << "read_cycle: " << read_cycles << endl;
            //cout << "write_cycle: " << write_cycles << endl;
        }
};