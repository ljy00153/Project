#include <iostream>


#include "analayzer_OS/mapper.cpp"
#include "analayzer_WS/mapper.cpp"
#include "analayzer_IS/mapper.cpp"
using namespace std;

int main()
{
    EyerissMapper_OS mapper_OS;
    EyerissMapper_WS mapper_WS;
    EyerissMapper_IS mapper_IS;
    LinearShapeParam linear;
    linear.B = 256;
    linear.in_features = 128 * 8 * 8;
    linear.out_features = 256;
    cout << "Batch : " << linear.B << endl;
    cout << "in_features : " << linear.in_features << endl;
    cout << "out_features : " << linear.out_features << endl;


    mapper_OS.run(linear, 1, "../log/result_no_cycle.csv");
    mapper_WS.run(linear, 1, "../log/result_no_cycle.csv");
    mapper_IS.run(linear, 1, "../log/result_no_cycle.csv");

    return 0;
}