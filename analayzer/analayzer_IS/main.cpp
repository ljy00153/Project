#include <iostream>
#include <vector>
#include <string>
#include <cmath>

#include "mapper.cpp"
using namespace std;

int main()
{
    EyerissMapper_IS mapper;
    LinearShapeParam linear;
    linear.B = 1;
    linear.in_features = 128 * 8 * 8;
    linear.out_features = 256;
    cout << "Batch : " << linear.B << endl;
    cout << "in_features : " << linear.in_features << endl;
    cout << "out_features : " << linear.out_features << endl;


    mapper.run(linear, 1, "log/result_no_cycle.csv");

    return 0;
}