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

int32_t make_int32_from_bytes_A(uint8_t b0, uint8_t b1, uint8_t b2, uint8_t b3);
int32_t make_int32_from_bytes_B(int8_t b0, int8_t b1, int8_t b2, int8_t b3);
int32_t generate_in_data_A();
int32_t generate_in_data_B();
int32_t generate_ipsum();
int32_t generate_golden_output
(const int32_t& in_feature_spad, const int32_t& weight_spad);
array<uint8_t, 4> get_bytes(int32_t value);
array<int8_t, 4> get_bytes_deq(int32_t value);
array<int8_t, 4> get_bytes_no_deq(int32_t value);

random_device rd;  
mt19937 rng(rd());  // random seed
uniform_int_distribution<uint8_t> dist_A(0, 255);//數字隨機範圍
uniform_int_distribution<int8_t> dist_B(-128, 127);//數字隨機範圍
uniform_int_distribution<int32_t> dist_ipsum(-32, 32);//數字隨機範圍

int main()
{
    int pattern_id = 6;//放在第幾個資料夾
    int m = 64; //GEMM now
    int n = 12;
    int p = 4;
    int n_div4 = n / 4;
    // A: m * n
    // B: n * p
    // C: m * p
    string folder = "Pattern" + to_string(pattern_id);

    // ===== 建立矩陣 =====
    vector<int32_t> A(m * n_div4);
    vector<int32_t> B(n_div4 * p);
    vector<int32_t> C(m * p);

    // ===== 產生 A 和 B =====
    cout << "✅ Generating random matrices A and B..." << endl;
    for(int i = 0; i < m * n_div4; i++)
        A[i] = generate_in_data_A();
        

    for(int i= 0; i < p * n_div4; i++)
        B[i] = generate_in_data_B();
    cout << "✅ Random matrices A and B generated." << endl;
    // ===== 計算 C = A × B =====
    for (int i = 0; i < m; i++) 
    {
        for (int j = 0; j < p; j++) 
        {
            int32_t sum = 0;
            for (int k = 0; k < n_div4; k++) 
                sum += generate_golden_output((A[i * n_div4 + k]), B[j * n_div4 + k]);
    
            C[i * p + j] = sum;
            //cout << "C = " << i * p + j<< endl;
        }
    }

    cout << "✅ Matrix Multiplication Done!" << endl;

    // ===== 產生 ipsum 與最終 golden C =====
    // ipsum: 與 C 大小相同的 int32 隨機數；C_golden = C + ipsum
    vector<int32_t> ipsum(m * p);
    vector<int32_t> C_golden(m * p);
    for (size_t idx = 0; idx < C.size(); ++idx) 
    {
        ipsum[idx] = generate_ipsum();
        C_golden[idx] = C[idx] + ipsum[idx];
    }

    // ===== 寫入檔案 (txt) =====

    string pathA = folder + "/ifmap_tb4.txt";
    string pathB = folder + "/filter_tb4.txt";
    string pathI = folder + "/ipsum_tb4.txt";
    string pathC = folder + "/ofmap_tb4.txt";

    ofstream fa(pathA);
    ofstream fb(pathB);
    ofstream fi(pathI);
    ofstream fc(pathC);
    if(!fa.is_open() || !fb.is_open() || !fc.is_open() || !fi.is_open()) 
    {
        cerr << "❌ Cannot open output file.\n";
        return -1;
    }
    else
        cout << "✅ Output file opened: " << pathA << ", " << pathB << ", " << pathI << ", " << pathC << endl;

    // 輸出改為十進位、以逗號分隔，且沒有尾逗號
    // A 和 B: 原本每個元素為 int32 (4 bytes)，現在拆成 4 個 byte，所有 byte 以逗號分隔輸出
    bool first = true;
    for (int i = 0; i < m; i++) 
    {
        for (int j = 0; j < n_div4; j++) 
        {
            array<uint8_t, 4> bytes = get_bytes(A[i * n_div4 + j]);
            for (int b = 0; b < 4; ++b) 
            {
                if (!first) fa << ',';
                fa << static_cast<int>(bytes[b]);
                first = false;
            }
        }
    }
    fa << '\n';

    first = true;
    for (int i = 0; i < n_div4; i++) 
    {
        for (int j = 0; j < p; j++) 
        {
            array<int8_t, 4> bytes = get_bytes_no_deq(B[i * p + j]);
            for (int b = 0; b < 4; ++b) 
            {
                if (!first) fb << ',';
                fb << static_cast<int>(bytes[b]);
                first = false;
            }
        }
    }
    fb << '\n';

    // ipsum: 與 C_golden 同長，十進位、逗號分隔、無尾逗號
    first = true;
    for (int i = 0; i < m; i++) 
    {
        for (int j = 0; j < p; j++) 
        {
            if (!first) fi << ',';
            fi << dec << ipsum[i * p + j];
            first = false;
        }
    }
    fi << '\n';

    // C_golden: 每個 int32 為一個元素，全部以逗號分隔輸出，無尾逗號
    first = true;
    for (int i = 0; i < m; i++) 
    {
        for (int j = 0; j < p; j++) 
        {
            if (!first) fc << ',';
            fc << dec << C_golden[i * p + j];
            first = false;
        }
    }
    fc << '\n';
    

    fa.close();
    fb.close();
    fi.close();
    fc.close();

    cout << "✅ Done: A.txt, B.txt, ipsum.txt and C_golden.txt generated in '" << folder << "/'" << endl;
    cout << "\n--- Matrix Dimensions (at uint8_t level) ---" << endl;
    cout << "  A: " << m << " x " << n << endl;
    cout << "  B: " << n << " x " << p << endl;
    cout << " ipsum: " << m << " x " << p << endl;
    cout << "  C: " << m << " x " << p << endl;
    cout << "\n--- Vector Sizes (element count of int32_t) ---" << endl;
    cout << "  A size: " << A.size() * 4 << " bytes" << endl;
    cout << "  B size: " << B.size() * 4 << " bytes" << endl;
    cout << "ipsum size: " << ipsum.size() * 4 << " bytes" << endl;
    cout << "  C size: " << C.size() * 4 << " bytes" << endl;

    return 0;
}

int32_t make_int32_from_bytes_A(const std::array<uint8_t, 4>& bytes) 
{
    // 小端序組合成 int32_t
    int byte[4];
    for(int i = 0; i < 4; i++)
        byte[i] = static_cast<uint8_t>(bytes[i]);
    int word = (int32_t(byte[3]) << 24) | 
                (int32_t(byte[2]) << 16) | 
                (int32_t(byte[1]) << 8)  | 
                (int32_t(byte[0]));
    return word;
}

int32_t make_int32_from_bytes_B(const std::array<int8_t, 4>& bytes) 
{
    // 小端序組合成 int32_t
    uint8_t byte[4];
    for(int i = 0; i < 4; i++)
        byte[i] = static_cast<uint8_t>(bytes[i]);
    int word = (int32_t(byte[3]) << 24) | 
                (int32_t(byte[2]) << 16) | 
                (int32_t(byte[1]) << 8)  | 
                (int32_t(byte[0]));
    return word;
}

int32_t generate_in_data_A()
{
    int32_t in_data;
    array<uint8_t, 4> in_data_bytes;

    for (int b = 0; b < 4; b++)
        in_data_bytes[b] = dist_A(rng);
    in_data = make_int32_from_bytes_A(in_data_bytes);
    return in_data;
}

int32_t generate_in_data_B()
{
    int32_t in_data;
    array<int8_t, 4> in_data_bytes;
    for (int b = 0; b < 4; b++)
    {
        in_data_bytes[b] = dist_B(rng);
        //cout << "Generated weight byte " << b << ": " << static_cast<int>(in_data_bytes[b]) << endl;
    }
        
    in_data = make_int32_from_bytes_B(in_data_bytes);
    //cout << "Generated weight int32: " << in_data << endl;
    return in_data;
}



int32_t generate_ipsum()
{
    return static_cast<int32_t>(dist_ipsum(rng));
}


int32_t generate_golden_output(const int32_t& in_feature_spad, const int32_t& weight_spad)
{
    array<int8_t, 4> in_feature_bytes = get_bytes_deq(in_feature_spad);
    array<int8_t, 4> weight_bytes = get_bytes_no_deq(weight_spad);
    
    int32_t golden_output = 0;
    for (int j = 0; j < 4; j++) 
    {
        golden_output += in_feature_bytes[j] * weight_bytes[j];
        //cout << "in_feature_bytes[" << j << "] = " << static_cast<int>(in_feature_bytes[j]) 
        //     << ", weight_bytes[" << j << "] = " << static_cast<int>(weight_bytes[j]) << endl;
    }
    //cout << "Golden output: " << golden_output << endl;
    return golden_output;
}

array<uint8_t, 4> get_bytes(int32_t value) 
{                                   
    array<uint8_t, 4> bytes{};
    for (int i = 0; i < 4; ++i)
    {
        bytes[i] = (value >> (8 * i)) & 0xFF;
    }
    return bytes;
}

array<int8_t, 4> get_bytes_deq(int32_t value) 
{                                   
    array<int8_t, 4> bytes{};
    for (int i = 0; i < 4; ++i)
    {
        bytes[i] = (value >> (8 * i)) & 0xFF;
        bytes[i] ^= 0x80;// dequantize
        //cout << "Dequantized Byte " << i << ": " << static_cast<int>(bytes[i]) << endl;
    }
    return bytes;
}

array<int8_t, 4> get_bytes_no_deq(int32_t value) 
{                                   
    array<int8_t, 4> bytes{};
    for (int i = 0; i < 4; ++i)
    {
        bytes[i] = (value >> (8 * i)) & 0xFF;
    }
    return bytes;
}