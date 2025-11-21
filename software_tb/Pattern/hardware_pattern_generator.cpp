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
int32_t generate_ipsum();

int32_t generate_golden_output
(const int32_t& in_feature_spad, const int32_t& weight_spad);
array<uint8_t, 4> get_bytes(int32_t value);

random_device rd;  
mt19937 rng(rd());  // random seed
uniform_int_distribution<int32_t> dist_byte(0, 32);//數字隨機範圍
uniform_int_distribution<int32_t> dist_ipsum(-32, 32); // smaller ipsum range

int main()
{
    int pattern_id = 4;//放在第幾個資料夾
    int m = 8; //GEMM now
    int n = 12;
    int p = 4;
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

    // ===== 產生 ipsum 與最終 golden C =====
    // ipsum: 與 C 大小相同的 int32 隨機數；C_golden = C + ipsum
    vector<int32_t> ipsum(m * p);
    vector<int32_t> C_golden_vec(m * p);
    for (size_t idx = 0; idx < C.size(); ++idx) {
        ipsum[idx] = generate_ipsum();
        C_golden_vec[idx] = C[idx] + ipsum[idx];
    }

    // ===== 寫入檔案 (txt) =====

    string pathA = folder + "/A.txt";
    string pathB = folder + "/B.txt";
    string pathC = folder + "/C_golden.txt";
    string pathI = folder + "/ipsum.txt";

    ofstream fa(pathA);
    ofstream fb(pathB);
    ofstream fc(pathC);
    ofstream fi(pathI);
    if(!fa.is_open() || !fb.is_open() || !fc.is_open() || !fi.is_open()) 
    {
        cerr << "❌ Cannot open output file.\n";
        return -1;
    }
    else
        cout << "✅ Output file opened: " << pathA << ", " << pathB << ", " << pathC << ", " << pathI << endl;

    // 輸出改為十進位、以逗號分隔，且沒有尾逗號
    // A 和 B: 原本每個元素為 int32 (4 bytes)，現在拆成 4 個 byte，所有 byte 以逗號分隔輸出
    bool first = true;
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n_div4; j++) {
            array<uint8_t, 4> bytes = get_bytes(A[i * n_div4 + j]);
            for (int b = 0; b < 4; ++b) {
                if (!first) fa << ',';
                fa << static_cast<int>(bytes[b]);
                first = false;
            }
        }
    }
    fa << '\n';

    first = true;
    for (int i = 0; i < n_div4; i++) {
        for (int j = 0; j < p; j++) {
            array<uint8_t, 4> bytes = get_bytes(B[i * p + j]);
            for (int b = 0; b < 4; ++b) {
                if (!first) fb << ',';
                fb << static_cast<int>(bytes[b]);
                first = false;
            }
        }
    }
    fb << '\n';

    // C_golden: 每個 int32 為一個元素，全部以逗號分隔輸出，無尾逗號
    first = true;
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < p; j++) {
            if (!first) fc << ',';
            fc << dec << C_golden_vec[i * p + j];
            first = false;
        }
    }
    fc << '\n';
    
    // ipsum: 與 C_golden 同長，十進位、逗號分隔、無尾逗號
    first = true;
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < p; j++) {
            if (!first) fi << ',';
            fi << dec << ipsum[i * p + j];
            first = false;
        }
    }
    fi << '\n';
    
    fa.close();
    fb.close();
    fc.close();
    fi.close();

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

// generate a small int32 for ipsum (small magnitude)
int32_t generate_ipsum()
{
    return static_cast<int32_t>(dist_ipsum(rng));
}