#ifndef LOAD_DATA_CPP
#define LOAD_DATA_CPP

#include <vector>
#include <string>
#include <fstream>
#include <sstream>
#include <iostream>

using namespace std;
using DataType = int32_t;

void load_data(std::vector<DataType> &mem, const std::string &filename)
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

#endif