#include <iostream>
#include <vector>
#include <cmath>
#include <cstdlib>
#include <ctime>
#include <numeric>
#include <algorithm>
#include <array>
#include <iomanip>
#include <fstream>
#include <string>
#include <sstream>

// 引入您確定功能正確的 PE Array 硬體模型
#include "../../src/PE/pe_array.cpp"
#include "../analayzer/mapper.cpp"

// 定義模擬所使用的資料型態
using DataType = int32_t;
using namespace std;
void load_data(vector<DataType> &mem, const string &filename);//directly load data into memory

struct index
{
    int count_if_col;
    int count_if_row;
    int count_weight_col;
    int count_weight_row;
    int count_of_col;
    int count_of_row;
};

struct EyerissMappingParam
{
    int tk; //1~6
    int tn; //1~8
    int mode;
    //1: 6個PE累加，共一組
    //2: 3個PE累加，共兩組
    //3: 2個PE累加，共三組
    //4: 1個PE累加，共六組
    int M;
    int K; 
    int N; // K * 1 * 3 + K * N * 12 < 64kb
};

// ===================================================================
// 組件 1: 高精度控制器 (Cycle-Accurate Controller)
// ===================================================================
enum class State 
{
    IDLE,
    LOADING_IF,
    LOADING_W,
    LOADING_PSUM,
    COMPUTING,
    ACUMULATING_PSUM,
    STORING_PSUM,
    FINISH
};



class CycleAccurateController 
{
    public:
        struct GEMV { int B, IN_F, OUT_F; };

    private:
        GEMV linear;
        index idx;
        EyerissMappingParam mapping;
        PE_Array& pe_array;

        // 狀態變數
        State current_state;
        long long total_cycles;
        
        int k_tile_idx;
        int n_tile_idx;

        int if_counter = 0;
        int weight_counter = 0;

        int data_load_progress;

    public:
        CycleAccurateController(const GEMV& g, const EyerissMappingParam& m, PE_Array& pe_arr)
            : linear(g), mapping(m), pe_array(pe_arr) 
        {
            current_state = State::IDLE;
            total_cycles = 0;
            k_tile_idx = 0;
            n_tile_idx = 0;
            data_load_progress = 0;
            idx = {0, 0, 0, 0, 0, 0};
        }

        bool step(
            const vector<DataType>& all_in_features, 
            const vector<DataType>& all_weights,
            vector<DataType>& final_psums
        ) 
        {
            //state transition and control PE Array
            switch (current_state) 
            {
                case State::IDLE:
                {
                    current_state = State::LOADING_IF;
                    data_load_progress = 0;
                    total_cycles++;
                    break;
                }
                case State::LOADING_IF:
                {
                    data_load_progress++;
                    if (data_load_progress >= PE::IFMAP_SIZE) 
                    {
                        //load if_data to a PE in PE array
                        if_counter++;
                        data_load_progress = 0;
                    }
                    if(if_counter >= PE_Array::NUM_PE)
                    {
                        if_counter = 0;
                        current_state = State::LOADING_W;
                    }
                    total_cycles++;
                    break;
                }
                
                case State::LOADING_W:
                {
                    data_load_progress++;
                    if (data_load_progress >= PE::WEIGHT_SIZE) 
                    {
                        //load weight_data to a PE in PE array
                        //if one PE weight load finish, start compute
                        pe_array.pe[weight_counter++].start_cycle_compute();
                        data_load_progress = 0;
                    }
                    if(weight_counter >= PE_Array::NUM_PE)
                    {
                        weight_counter = 0;
                        current_state = State::COMPUTING;
                    }
                    pe_array.step_all(); // allow PE to compute during weight loading
                    total_cycles++;
                    break;
                }
                case State::COMPUTING: 
                {
                    pe_array.step_all();
                    if (!pe_array.is_any_busy()) 
                    {
                        current_state = State::STORING_PSUM;
                    }
                    total_cycles++;
                    break;
                }

                case State::STORING_PSUM: {
                    // ... 累加 psum ...
                    
                    // ===================================================================
                    // >> COMPUTATION ORDER: for k in K, for n in N <<
                    // ===================================================================
                    // 這段邏輯完全對應了您圖片中的 k 和 n 迴圈的推進方式。
                    // 內層的 n 迴圈先推進。
                    n_tile_idx++;
                    if (n_tile_idx >= shape.OUT_F / tile.N) {
                        // n 迴圈結束，重置 n，並推進外層的 k 迴圈。
                        n_tile_idx = 0;
                        k_tile_idx++;
                    }

                    if (k_tile_idx >= shape.IN_F / tile.K) {
                        // k 迴圈也結束了，代表所有運算完成。
                        total_cycles++;
                        return true; 
                    } else {
                        // 還有 Tile 要處理，回到 IDLE 狀態，開始下一個 computation order
                        current_state = State::IDLE;
                    }
                    // ===================================================================
                    break;
                }
            }

            total_cycles++;
            return false;
        }
        
        long long get_total_cycles() const { return total_cycles; }
};


// ===================================================================
// 組件 2: 主測試平台 (Main Testbench)
// (main 函式與之前相同，此處省略以保持簡潔)
// ===================================================================
int main() 
{
    EyerissMapper mapper;
    LinearShapeParam linear;
    linear.B = 64;
    linear.in_features = 128 * 8 * 8;
    linear.out_features = 256;

    mapper.run(linear, 1);

    CycleAccurateController::GEMV shape = {linear.B, linear.in_features, linear.out_features}; // B, IN_F, OUT_F
    EyerissMappingParam mapping = {mapper.best_result.tk, mapper.best_result.tn, mapper.best_result.mode, 
                                   mapper.best_result.M, mapper.best_result.K, mapper.best_result.N};

    // 2. 初始化 DUT
    PE_Array dut_pe_array;
    dut_pe_array.mode = mapper.best_result.mode;
    dut_pe_array.set_tag();
    CycleAccurateController dut_controller(shape, mapping, dut_pe_array);

    // 3. 準備測試資料
    vector<DataType> in_features(shape.IN_F);
    vector<DataType> weights(shape.IN_F * shape.OUT_F);
    vector<DataType> psum_dut(shape.OUT_F, 0);
    vector<DataType> golden(shape.OUT_F, 0);

    load_data(in_features, "../Pattern/Pattern1/A.txt");
    load_data(weights, "../Pattern/Pattern1/B.txt");
    load_data(golden, "../Pattern/Pattern1/C_golden.txt");

    // 4. 執行 DUT 模擬 (Cycle-Accurate)
    cout << "[Testbench] Starting DUT (PE_Array) Simulation..." << endl;
    CycleAccurateController dut_controller(shape, tile, dut_pe_array);
    bool done = false;
    while (!done) 
    {
        done = dut_controller.step(in_features, weights, psum_dut);
    }


    // 6. 報告與驗證
    cout << "\n=======================================" << endl;
    cout << "=          SIMULATION REPORT          =" << endl;
    cout << "=======================================" << endl;
    
    long long final_cycles = dut_controller.get_total_cycles();
    cout << "Total cycles simulated: " << final_cycles << endl;
    
    bool pass;
    pass = equal(psum_dut.begin(), psum_dut.end(), golden.begin());
    
    cout << "Functional Verification: " << (pass ? "PASSED" : "FAILED") << endl;
    if (!pass) {
        for(size_t i=0; i < psum_dut.size(); i++) 
        {
            if (psum_dut[i] != golden[i]) 
            {
                cout << "First Mismatch at index " << i << ": DUT=" << psum_dut[i] << ", Golden=" << golden[i] << endl;
                break;
            }
        }
    }
    cout << "=======================================\n" << endl;

    return 0;
}



void load_data(vector<DataType> &mem, const string &filename)
{
    ifstream file(filename);
    if (!file.is_open()) 
    {
        cerr << "Error opening file: " << filename << endl;
        return;
    }
    else
        cout << "Successfully open file: " << filename << endl;
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