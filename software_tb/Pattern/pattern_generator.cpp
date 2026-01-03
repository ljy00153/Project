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
int8_t generate_in_data_A();
int8_t generate_in_data_B();
int32_t generate_ipsum();
int32_t generate_golden_output
(const uint8_t& in_feature_spad, const int8_t& weight_spad);

array<uint8_t, 4> get_bytes(int32_t value);

random_device rd;  
mt19937 rng(rd());  // random seed
uniform_int_distribution<uint8_t> dist_A(0, 255);//數字隨機範圍
uniform_int_distribution<int8_t> dist_B(-128, 127);//數字隨機範圍
uniform_int_distribution<int32_t> dist_ipsum(-32, 32);//數字隨機範圍

int main()
{
    int pattern_id = 7;//放在第幾個資料夾
    int m = 64; //GEMM now
    int n = 72;
    int p = 64;
    //int n_div4 = n / 4;
    // A: m * n
    // B: n * p
    // C: m * p
    string folder = "Pattern" + to_string(pattern_id);

    // ===== 建立矩陣 =====
    array<int32_t, IFMAP_SIZE> in_feature_spad;
    array<int32_t, TOTAL_WEIGHT> weight_spad;
    array<int32_t, NUM_WEIGHT> golden_output;
    array<array<int32_t, NUM_WEIGHT>, 8 * MODE> golden_output_all = {0};

    vector<uint8_t> A(m * n);
    vector<int8_t> B(n * p);
    vector<int8_t> Bt(p * n);
    vector<int32_t> C(m * p);

    // ===== 產生 A 和 B =====
    cout << "✅ Generating random matrices A and B..." << endl;
    for(int i = 0; i < m * n; i++)
        A[i] = generate_in_data_A();
        

    for(int i= 0; i < n * p; i++)
        B[i] = generate_in_data_B();
    //transpose
    for (int i = 0; i < n; i++) 
        for (int j = 0; j < p; j++) 
            Bt[j * n + i] = B[i * p + j];

    // ===== 計算 C = A × B =====
    for (int i = 0; i < m; i++) 
    {
        for (int j = 0; j < p; j++) 
        {
            int32_t sum = 0;
            for (int k = 0; k < n; k++) 
                sum += generate_golden_output((A[i * n + k]), B[k * p + j]);
    
            C[i * p + j] = sum;
            //cout << "C = " << i * p + j<< endl;
        }
    }

    cout << "✅ Matrix Multiplication Done!" << endl;

    vector<int32_t> ipsum(m * p);
    vector<int32_t> C_golden(m * p);
    for (size_t idx = 0; idx < C.size(); idx++) 
    {
        ipsum[idx] = generate_ipsum();
        C_golden[idx] = C[idx] + ipsum[idx];
    }
    // ===== 寫入檔案 (txt) =====

    string pathA = folder + "/A.txt";
    string pathB = folder + "/B.txt";
    string pathI = folder + "/ipsum.txt";
    string pathC = folder + "/C_golden.txt";

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

    fa << hex << uppercase << setfill('0');;
    fb << hex << uppercase << setfill('0');;
    fi << hex << uppercase << setfill('0');
    fc << hex << uppercase << setfill('0');
    for (int i = 0; i < m; i++) 
        for (int j = 0; j < n; j++)
            fa << setw(2) << (int)(uint8_t)A[i * n + j] << "\n";

    for (int i = 0; i < p; i++) 
        for (int j = 0; j < n; j++)
            fb << setw(2) << (int)(uint8_t)Bt[i * n + j] << "\n";
    array<uint8_t, 4> bytes{};
    for (int i = 0; i < m; i++) 
        for (int j = 0; j < p; j++)
        {
            bytes = get_bytes(ipsum[i * p + j]);
            for(int k = 0; k < 4; k++)
                fi << setw(2) << (int)(uint8_t)bytes[k] << "\n";
        }
            

    for (int i = 0; i < m; i++) 
        for (int j = 0; j < p; j++)
        {
            bytes = get_bytes(C_golden[i * p + j]);
            for(int k = 0; k < 4; k++)
                fc << setw(2) << (int)(uint8_t)bytes[k] << "\n";
        }
    

    fa.close();
    fb.close();
    fi.close();
    fc.close();

    cout << "✅ Done: A.txt, B.txt, ipsum.txt and C_golden.txt generated in '" << folder << "/'" << endl;
    cout << "\n--- Matrix Dimensions (at uint8_t level) ---" << endl;
    cout << "  A: " << m << " x " << n << endl;
    cout << "  Bt: " << p << " x " << n << endl;
    cout << " ipsum: " << m << " x " << p << endl;
    cout << "  C: " << m << " x " << p << endl;
    cout << "\n--- Vector Sizes (element count of int32_t) ---" << endl;
    cout << "  A size: " << A.size() << " bytes" << endl;
    cout << "  Bt size: " << Bt.size() << " bytes" << endl;
    cout << "ipsum size: " << ipsum.size() * 4 << " bytes" << endl;
    cout << "  C size: " << C.size() * 4 << " bytes" << endl;

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

int8_t generate_in_data_A()
{
    int8_t in_data;
    //array<uint8_t, 4> in_data_bytes;

    //for (int b = 0; b < 4; b++)
        //in_data_bytes[b] = dist_A(rng);
    in_data = dist_A(rng);
    return in_data;
}

int8_t generate_in_data_B()
{
    int8_t in_data;
    //array<int8_t, 4> in_data_bytes;
    /*for (int b = 0; b < 4; b++)
    {
        in_data_bytes[b] = dist_B(rng);
        //cout << "Generated weight byte " << b << ": " << static_cast<int>(in_data_bytes[b]) << endl;
    }*/
        
    in_data = dist_B(rng);
    //cout << "Generated weight int32: " << in_data << endl;
    return in_data;
}



int32_t generate_ipsum()
{
    return static_cast<int32_t>(dist_ipsum(rng));
}


int32_t generate_golden_output(const uint8_t& in_feature_spad, const int8_t& weight_spad)
{
    //array<int8_t, 4> in_feature_bytes = get_bytes_deq(in_feature_spad);
    //array<int8_t, 4> weight_bytes = get_bytes_no_deq(weight_spad);

    int32_t in_feature_byte = int32_t(int8_t(in_feature_spad ^ 0x80));// dequantize
    int32_t weight_byte = int32_t(weight_spad);
    int32_t golden_output = 0;
    /*for (int j = 0; j < 4; j++) 
    {
        golden_output += in_feature_bytes[j] * weight_bytes[j];
        //cout << "in_feature_bytes[" << j << "] = " << static_cast<int>(in_feature_bytes[j]) 
        //     << ", weight_bytes[" << j << "] = " << static_cast<int>(weight_bytes[j]) << endl;
    }*/
    golden_output = in_feature_byte * weight_byte;
    //cout << "Golden output: " << golden_output << endl;
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