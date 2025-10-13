#include <iostream>
#include <vector>
#include <string>
#include <cmath>

#include "mapper.cpp"
using namespace std;

int main()
{
    EyerissMapper mapper;
    LinearShapeParam linear;
    linear.B = 256;
    linear.in_features = 128 * 8 * 8;
    linear.out_features = 256;
    cout << "Batch : " << linear.B << endl;
    cout << "in_features : " << linear.in_features << endl;
    cout << "out_features : " << linear.out_features << endl;


    mapper.run(linear, 5);

    return 0;
}