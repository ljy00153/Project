#include <iostream>

#include "tb_pe_array/GEMM_no_mem.cpp"
//#include "tb_pe_array/GEMM_with_mem.cpp"


using namespace std;

int main()
{
    TileBasedSimulator simulator;
    //GEMM_no_mem
    LinearShapeParam linear;
    linear.B = 64;
    linear.in_features = 128 * 8 * 8;
    linear.out_features = 256;
    simulator.run(linear, "Pattern1");
    return 0;
}
