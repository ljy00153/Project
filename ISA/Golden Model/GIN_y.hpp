#pragma once
#include <vector>
#include "GIN_x.hpp"
using namespace std;

class GIN_y
{
    public:
        int num_xbus;
        vector<unique_ptr<GIN_x>> bus_x;

    
        GIN_y(int num_xbus) : num_xbus(num_xbus) 
        {
            for (int i = 0; i < num_xbus; ++i)
                bus_x.emplace_back(make_unique<GIN_x>(i));
        }

        void send(const int &y, const int &valid, const int &tag, const int &data) 
        {
            for(int i = 0; i < num_xbus; i++)
                bus_x[i]->send(y, valid, tag, data);
        }
};