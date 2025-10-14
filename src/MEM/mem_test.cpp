#include <iostream>
#include <vector>
#include <sstream>
#include <string>
#include <fstream>

#include "memory.cpp"
#include "../PE/pe_array.cpp"

using namespace std;

long long int cycle = 0;
void load_data(memory &mem, const string &filename);//directly load data into memory
void read_data(memory &mem, int address);//read data from memory, need to wait until read_done is true
void write_data(memory &mem, int address, int data);//write data to memory, need to wait until write_done is true

PE_Array pe_array;

int main()
{
    memory mem(2); // Example: memory of size 1024 with 2 access cycles
    
    string pattern = "Pattern1";
    string in_feature = "../../testbench/Pattern/" + pattern + "/A.txt"; 
    string weight = "../../testbench/Pattern/" + pattern + "/B.txt";
    string golden = "../../testbench/Pattern/" + pattern + "/C_golden.txt";
    load_data(mem, in_feature);
    load_data(mem, weight);
    load_data(mem, golden);
    cout << "memory size: " << mem.mem.size() << endl;
    int read_val;

    // Example read and write operations
    cout << endl << "=== Memory Read Test Start ===" << endl;
    cout << "Cycle before read: " << cycle << endl;
    read_data(mem, 0);   // Read from address 0
    cout << "expected: " << mem.mem[0] << endl;
    read_data(mem, 10);  // Read from address 10
    cout << "expected: " << mem.mem[10] << endl;
    read_data(mem, 20);  // Read from address 20
    cout << "expected: " << mem.mem[20] << endl;
    cout << "Cycle after read now: " << cycle << endl;
    cout << "=== Memory Read Test Done ===" << endl;

    cout << endl << "=== Memory Write Test Start ===" << endl;
    cout << "Cycle before write: " << cycle << endl;
    write_data(mem, 30, 777);
    cout << "expected: " << mem.mem[30] << endl;
    write_data(mem, 40, 666);
    cout << "expected: " << mem.mem[40] << endl;
    write_data(mem, 50, 888);
    cout << "expected: " << mem.mem[50] << endl;
    cout << "Cycle after write now: " << cycle << endl;
    cout << "=== Memory Write Test Done ===" << endl;

    cout << endl << "=== Parallel Test Start ===" << endl;
    pe_array.reset();

    pe_array.mode = 1;
    pe_array.set_tag();

    return 0;
}

void load_data(memory &mem, const string &filename)
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
        mem.mem.push_back(val);
    }

    file.close();
}

void read_data(memory &mem, int address)
{
    mem.read(address);
    int read_val = 0;
    int counter = 0;
    while(counter != mem.access_cycles)
    {
        mem.step_cycle();
        //pe_array.step_all();
        //cout << "cycle: " << cycle << endl;
        cycle++;        
        counter++;

    }
    read_val = (mem.read_done)? mem.read_value : -1;
    cout << "address: " << address << " ";
    cout << "read_value: " << read_val << endl;
}

void write_data(memory &mem, int address, int data)
{
    mem.write(address, data);
    int counter = 0;
    while(counter != mem.access_cycles)
    {
        mem.step_cycle();
        //pe_array.step_all();
        //cout << "cycle: " << cycle << endl;
        cycle++;        
        counter++;

    }
    if(!mem.write_done)
        cerr << "Write Error" << endl;
    else
        cout << "mem[" << address << "]" << "now is: " << mem.mem[address] << endl;
}