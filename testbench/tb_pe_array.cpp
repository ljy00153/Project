#include <iostream>
#include "tb_WS/GEMM_with_mem.cpp"
#include "Pattern/PatternGen.hpp"

using namespace std;

int main()
{
    WS_Based_with_mem_Simulator WS_mem_simulator;
    LinearShapeParam GEMM;
    PatternGenerator gen;
    int Batch = 64;                  //調這些
    int in_features = 776;         //調這些
    int out_features = 666;         //調這些
    int prog_id = 4;                //調這些

    string GEMM_prog_path = "/prog" + to_string(prog_id);

    GEMM.B = Batch;
    GEMM.in_features = in_features;
    GEMM.out_features = out_features;
    
    string pattern = "../hardware/sim/prog" + to_string(prog_id);
    string GEMV_log_path = "../log";
    string GEMM_log_path = "../log";
    gen.run(prog_id, Batch, in_features, out_features);
    WS_mem_simulator.run(GEMM, pattern, GEMM_log_path, GEMM_prog_path);
    return 0;
}
