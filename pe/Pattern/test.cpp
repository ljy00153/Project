#include <iostream>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <string>
#include <vector>
#include <array>

using namespace std;

#define IFMAP_SIZE 3   // 3 個輸入 (12 bytes)
#define NUM_WEIGHT 4   // 4 組 filter
#define TOTAL_WEIGHT (IFMAP_SIZE * NUM_WEIGHT)  // 12 個 int32_t
#define MODE 1

vector<int32_t> read_hex_file(const string& filename);
array<int32_t, NUM_WEIGHT> generate_golden_output
(const array<int32_t, IFMAP_SIZE>& in_feature_spad, const array<int32_t, TOTAL_WEIGHT>& weight_spad);
array<uint8_t, 4> get_bytes(int32_t value);

int main() 
{
    int pattern_id = 3;
    int m = 1;
    int n = 128 * 8 * 8;
    int p = 256;

    string folder = "Pattern" + to_string(pattern_id);

    // 檔案名稱
    string fileA = folder + "/A.txt";
    string fileB = folder + "/B.txt";
    string fileGolden = folder + "/C_golden.txt";

    // 讀取
    auto A = read_hex_file(fileA);
    auto B = read_hex_file(fileB);
    auto golden = read_hex_file(fileGolden);

    //cout << "A[0]: "<< golden.size()<<endl;
    //cout << "golden[" << 1 * 4 << "]: "<< golden[1 * 4]<<endl;

    array<int32_t, IFMAP_SIZE> in_feature_spad;
    array<int32_t, TOTAL_WEIGHT> weight_spad;

    bool all_pass = true;

    for (int i = 0; i < m; i++) 
    {
        for (int j = 0; j < p / 4; j++) 
        {
            array<int32_t, NUM_WEIGHT> C;
            array<int32_t, NUM_WEIGHT> sum = {0};
            for (int k = 0; k < n / 4; k++) 
            {
                for(int l = 0; l < 3; l++)
                {
                    int idxA = i * n + 3 * k + l;
                    if(idxA >= A.size()) 
                    { 
                        //cerr << "A index out of range\n"; 
                        in_feature_spad[l] = 0;
                    }
                    else
                        in_feature_spad[l] = A[idxA];
                }
                    
                //cout << "in_feature_spad[0]: "<< in_feature_spad[0]<<endl;
                //連續取A3筆資料
                for(int l = 0; l < 3; l++)
                    for(int o=0; o < 4; o++)
                    {
                        int idxB = (3*k+l) * p + 4*j + o;
                        if(idxB >= B.size()) 
                        { 
                            //cerr << "B index out of range\n"; 
                            weight_spad[l*4+o] = 0;
                        }
                        else
                            weight_spad[l*4+o] = B[idxB];
                    }
                //cout << "weight_spad[0]: "<< weight_spad[0]<<endl;
                //取B12筆，為3*4
                C = generate_golden_output(in_feature_spad, weight_spad);
                //cout << "C[0]: "<< C[0]<<endl;
                for(int l = 0; l < NUM_WEIGHT; l++)
                    sum[l] += C[l];
            }

            for(int l = 0; l < 4; l++)
            {
                //cout <<"sum[" << l <<"]: " << sum[l]<< endl;
                //cout <<"golden[" << j * 4 + l <<"]: " << golden[j * 4 + l]<< endl;
                if (sum[l] != golden[j * 4 + l]) 
                {
                    cout << "❌ Mismatch at index " << j * 4 + l << endl;
                    cout << "Got=" << sum[l] << " "
                    << "Expected=" << golden[j * 4 + l] << endl;
                    all_pass = false;
                }
            }
        }
    }

    if (all_pass)
        cout << "✅ All results match golden!" << endl;
    else
        cout << "⚠️  Some mismatches found." << endl;
    
    
    return 0;
}

vector<int32_t> read_hex_file(const string& filename) 
{
    ifstream fin(filename);
    if (!fin.is_open()) 
    {
        cerr << "❌ Cannot open file: " << filename << endl;
        return {};
    }
    vector<int32_t> data;
    string line;
    while (getline(fin, line)) 
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
        data.push_back(val);
    }
    return data;
}

array<int32_t, NUM_WEIGHT> generate_golden_output(const array<int32_t, IFMAP_SIZE>& in_feature_spad, const array<int32_t, TOTAL_WEIGHT>& weight_spad)
{
    array<array<uint8_t, 4>, IFMAP_SIZE> in_feature_bytes = {get_bytes(in_feature_spad[0]),
                                                             get_bytes(in_feature_spad[1]),
                                                             get_bytes(in_feature_spad[2])};
    array<array<uint8_t, 4>, TOTAL_WEIGHT> weight_bytes = {get_bytes(weight_spad[0]),  get_bytes(weight_spad[1]),
                                                            get_bytes(weight_spad[2]),  get_bytes(weight_spad[3]),
                                                            get_bytes(weight_spad[4]),  get_bytes(weight_spad[5]),
                                                            get_bytes(weight_spad[6]),  get_bytes(weight_spad[7]),
                                                            get_bytes(weight_spad[8]),  get_bytes(weight_spad[9]),
                                                            get_bytes(weight_spad[10]), get_bytes(weight_spad[11])};
    
    array<int32_t, NUM_WEIGHT> golden_output = {0};
    for (int j = 0; j < NUM_WEIGHT; j++) 
    {
        for (int i = 0; i < IFMAP_SIZE; i++) 
        {
            int idx = i * NUM_WEIGHT + j;
            //cout << "in_feature_bytes["<<i<<"][0]: "<<int(in_feature_bytes[i][0])<<endl;
            golden_output[j] += in_feature_bytes[i][0] *
                                weight_bytes[idx][0] +
                                in_feature_bytes[i][1] *
                                weight_bytes[idx][1] +
                                in_feature_bytes[i][2] *
                                weight_bytes[idx][2] +
                                in_feature_bytes[i][3] *
                                weight_bytes[idx][3];
        }
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