#include <iostream>
#include <vector>
#include <cstdint>
#include <iomanip>
#include <cstring>
#include <array>
#include <random>
#include <fstream>
#include <string>

using namespace std;

#define IFMAP_SIZE 1   // 3 個輸入 (12 bytes)
#define NUM_WEIGHT 1   // 4 組 filter
#define TOTAL_WEIGHT (IFMAP_SIZE * NUM_WEIGHT)  // 12 個 int32_t

#define MODE 1
//1: 6個PE累加，共一組
//2: 3個PE累加，共兩組
//3: 2個PE累加，共三組
//4: 1個PE累加，共六組

int32_t make_int32_from_bytes(uint8_t b0, uint8_t b1, uint8_t b2, uint8_t b3);
int32_t generate_in_data();

int32_t generate_golden_output
(const int32_t& in_feature_spad, const int32_t& weight_spad);
array<uint8_t, 4> get_bytes(int32_t value);

random_device rd;  
mt19937 rng(rd());  // random seed
uniform_int_distribution<int32_t> dist_byte(0, 32);//數字隨機範圍

int main()
{
    int pattern_id = 3;//放在第幾個資料夾
    int m = 256; //GEMM now
    int n = 128 * 8 * 8;
    int p = 256;
    int n_div4 = n / 4;
    // A: m * n
    // B: n * p
    // C: m * p
    string folder = "Pattern" + to_string(pattern_id);

    // ===== 建立矩陣 =====
    array<int32_t, IFMAP_SIZE> in_feature_spad;
    array<int32_t, TOTAL_WEIGHT> weight_spad;
    array<int32_t, NUM_WEIGHT> golden_output;
    array<array<int32_t, NUM_WEIGHT>, 8 * MODE> golden_output_all = {0};

    vector<int32_t> A(m * n_div4);
    vector<int32_t> B(n_div4 * p);
    vector<int32_t> C(m * p);

    // ===== 產生 A 和 B =====
    cout << "✅ Generating random matrices A and B..." << endl;
    for(int i = 0; i < m * n_div4; i++)
        A[i] = generate_in_data();

    for(int i= 0; i < n_div4 * p; i++)
        B[i] = generate_in_data();
    cout << "✅ Random matrices A and B generated." << endl;
    // ===== 計算 C = A × B =====
    for (int i = 0; i < m; i++) 
    {
        for (int j = 0; j < p; j++) 
        {
            int32_t sum = 0;
            for (int k = 0; k < n_div4; k++) 
                sum += generate_golden_output((A[i * n_div4 + k]), B[k * p + j]);
    
            C[i * p + j] = sum;
            //cout << "C = " << i * p + j<< endl;
        }
    }

    cout << "✅ Matrix Multiplication Done!" << endl;

    // ===== 寫入檔案 (txt) =====

    string pathA = folder + "/A.txt";
    string pathB = folder + "/B.txt";
    string pathC = folder + "/C_golden.txt";

    ofstream fa(pathA);
    ofstream fb(pathB);
    ofstream fc(pathC);
    if(!fa.is_open() || !fb.is_open() || !fc.is_open()) 
    {
        cerr << "❌ Cannot open output file.\n";
        return -1;
    }
    else
        cout << "✅ Output file opened: " << pathA << ", " << pathB << ", " << pathC << endl;

    fa << hex << uppercase << setfill('0');
    fb << hex << uppercase << setfill('0');
    fc << hex << uppercase << setfill('0');
    for (int i = 0; i < m; i++) 
        for (int j = 0; j < n_div4; j++)
            fa << setw(8) << A[i * n_div4 + j] << "\n";

    for (int i = 0; i < n_div4; i++) 
        for (int j = 0; j < p; j++)
            fb << setw(8) << B[i * p + j] << "\n";

    for (int i = 0; i < m; i++) 
        for (int j = 0; j < p; j++)
            fc << setw(8) << C[i * p + j] << "\n";
    

    fa.close();
    fb.close();
    fc.close();

    cout << "✅ Done: A.txt, B.txt, and C_golden.txt generated in '" << folder << "/'" << endl;
    cout << "\n--- Matrix Dimensions (at uint8_t level) ---" << endl;
    cout << "  A: " << m << " x " << n << endl;
    cout << "  B: " << n << " x " << p << endl;
    cout << "  C: " << m << " x " << p << endl;
    cout << "\n--- Vector Sizes (element count of int32_t) ---" << endl;
    cout << "  A size: " << A.size() << " (" << A.size() * 4 << " bytes)" << endl;
    cout << "  B size: " << B.size() << " (" << B.size() * 4 << " bytes)" << endl;
    cout << "  C size: " << C.size() << " (" << C.size() * 4 << " bytes)" << endl;

    return 0;
}

int32_t make_int32_from_bytes(const std::array<uint8_t, 4>& bytes) 
{
    // 小端序組合成 int32_t
    return static_cast<int32_t>(
        (bytes[3] << 24) |
        (bytes[2] << 16) |
        (bytes[1] << 8)  |
        (bytes[0])
    );
}

int32_t generate_in_data()
{
    int32_t in_data;
    array<uint8_t, 4> in_data_bytes;

    for (int b = 0; b < 4; b++)
        in_data_bytes[b] = uint8_t(dist_byte(rng));

    in_data = make_int32_from_bytes(in_data_bytes);
    return in_data;
}


int32_t generate_golden_output(const int32_t& in_feature_spad, const int32_t& weight_spad)
{
    array<uint8_t, 4> in_feature_bytes = get_bytes(in_feature_spad);
    array<uint8_t, 4> weight_bytes = get_bytes(weight_spad);
    
    int32_t golden_output = 0;
    for (int j = 0; j < 4; j++) 
    {
            golden_output += in_feature_bytes[j] * weight_bytes[j];
    }
    return golden_output;
}

array<uint8_t, 4> get_bytes(int32_t value) 
{                                   
    array<uint8_t, 4> bytes{};
    for (int i = 0; i < 4; ++i)
        bytes[i] = (value >> (8 * i)) & 0xFF;
    //may need to dequantize here
    return bytes;
}