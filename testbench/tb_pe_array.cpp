#include <iostream>

#include "tb_OS/GEMM_no_mem.cpp"
//#include "tb_OS/GEMM_with_mem.cpp"

//#include "tb_WS/GEMM_no_mem.cpp"
#include "tb_WS/GEMM_with_mem.cpp"

//#include "tb_IS/GEMM_no_mem.cpp"
#include "tb_IS/GEMM_with_mem.cpp"

using namespace std;

int main()
{
    OS_Based_Simulator OS_simulator;
    WS_Based_Simulator WS_simulator;
    IS_Based_Simulator IS_simulator;
    LinearShapeParam linear;
    linear.B = 64;
    linear.in_features = 128 * 8 * 8;
    linear.out_features = 256;
    string pattern = "Pattern3";
    string log_path = "../log/GEMM_no_mem.csv";

    cout << "=======================================" << endl;
    cout << "=     Output Stationary SIMULATION    =" << endl;
    cout << "=======================================" << endl;
    OS_simulator.run(linear, pattern, log_path);
    cout << "=======================================" << endl << endl;

    cout << "=======================================" << endl;
    cout << "=     Weight Stationary SIMULATION    =" << endl;
    cout << "=======================================" << endl;
    //WS_simulator.run(linear, pattern, log_path);
    cout << "=======================================" << endl << endl;

    cout << "=======================================" << endl;
    cout << "=     Input Stationary SIMULATION     =" << endl;
    cout << "=======================================" << endl;
    //IS_simulator.run(linear, pattern, log_path);
    return 0;
}
