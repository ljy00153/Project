#include <iostream>

//#include "OS_tb/GEMM_no_mem.cpp"
#include "OS_tb/GEMM_with_mem.cpp"

//#include "WS_tb/GEMM_no_mem.cpp"
#include "WS_tb/GEMM_with_mem.cpp"

//#include "IS_tb/GEMM_no_mem.cpp"
#include "IS_tb/GEMM_with_mem.cpp"

using namespace std;

int main()
{
    OS_Based_Simulator OS_simulator;
    LinearShapeParam linear;
    linear.B = 64;
    linear.in_features = 128 * 8 * 8;
    linear.out_features = 256;
    OS_simulator.run(linear, "Pattern3");
    return 0;
}
