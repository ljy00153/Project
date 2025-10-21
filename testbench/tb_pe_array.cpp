#include <iostream>

#include "tb_OS/GEMM_no_mem.cpp"
#include "tb_OS/GEMM_with_mem.cpp"

#include "tb_WS/GEMM_no_mem.cpp"
#include "tb_WS/GEMM_with_mem.cpp"

#include "tb_IS/GEMM_no_mem.cpp"
#include "tb_IS/GEMM_with_mem.cpp"

using namespace std;

int main()
{
    OS_Based_no_mem_Simulator OS_no_mem_simulator;
    OS_Based_with_mem_Simulator OS_mem_simulator;
    
    WS_Based_no_mem_Simulator WS_no_mem_simulator;
    WS_Based_with_mem_Simulator WS_mem_simulator;

    IS_Based_no_mem_Simulator IS_no_mem_simulator;
    IS_Based_with_mem_Simulator IS_mem_simulator;
    LinearShapeParam GEMV;
    LinearShapeParam GEMM;
    GEMV.B = 1;
    GEMV.in_features = 128 * 8 * 8;
    GEMV.out_features = 256;

    GEMM.B = 64;
    GEMM.in_features = 128 * 8 * 8;
    GEMM.out_features = 256;
    string pattern = "Pattern3";
    string GEMV_log_path = "../log/GEMV.csv";
    string GEMM_log_path = "../log/GEMM.csv";
    int a[4] = {1, 32, 64, 256};
    //OS_no_mem_simulator.run(GEMV, pattern, GEMV_log_path);
    //OS_mem_simulator.run(GEMV, pattern, GEMV_log_path);

    //IS_no_mem_simulator.run(GEMM, pattern, GEMM_log_path);
    //IS_mem_simulator.run(GEMM, pattern, GEMM_log_path);

    OS_no_mem_simulator.run(GEMM, pattern, GEMM_log_path);
    OS_mem_simulator.run(GEMM, pattern, GEMM_log_path);

    //WS_no_mem_simulator.run(GEMV, pattern, GEMV_log_path);
    //IS_no_mem_simulator.run(GEMV, pattern, GEMV_log_path);
    return 0;
}
