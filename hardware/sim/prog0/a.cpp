#include <iostream>
#include <vector>
#include <cstdint>
#include <iomanip> // 用於 hex, setw, setfill
#include <fstream>
#include <string>
#include <sstream>
#include <algorithm>

using namespace std;

// ==========================================
// 1. 設定矩陣維度
// ==========================================
const int M = 64; // A 的列數
const int N = 8192; // A 的行數 / B 的列數
const int P = 256; // B 的行數
// ==========================================

// 2. 核心運算函數
int32_t generate_golden_output(const uint8_t& in_feature_spad, const int8_t& weight_spad)
{
    int32_t in_feature_byte = int32_t(int8_t(in_feature_spad ^ 0x80));
    int32_t weight_byte = int32_t(weight_spad);
    return in_feature_byte * weight_byte;
}

// 3. 判斷是否為 Hex 字串
bool is_hex_string(const string& s) {
    if (s.empty() || s.length() > 2) return false;
    return s.find_first_not_of("0123456789abcdefABCDEF") == string::npos;
}

// 4. 讀檔函數
vector<uint8_t> read_file_to_vector(const string& filename) {
    ifstream infile(filename);
    vector<uint8_t> data;
    string word;

    if (!infile) {
        cerr << "[錯誤] 無法開啟檔案: " << filename << endl;
        return data;
    }

    cout << "正在讀取 " << filename << " ... ";
    while (infile >> word) {
        if (is_hex_string(word)) {
            try {
                int val = stoi(word, nullptr, 16);
                data.push_back(static_cast<uint8_t>(val));
            } catch (...) {}
        }
    }
    cout << "讀取到 " << data.size() << " 個數值。" << endl;
    return data;
}

int main() {
    // 設定檔案名稱
    string file_A_name = "A.txt";
    string file_B_name = "B.txt";

    vector<uint8_t> raw_A = read_file_to_vector(file_A_name);
    vector<uint8_t> raw_B = read_file_to_vector(file_B_name);

    // 檢查資料是否足夠
    if (raw_A.size() < M * N) {
        cerr << "A 檔案資料不足！" << endl;
        return 1;
    }
    if (raw_B.size() < N * P) {
        cerr << "B 檔案資料不足！" << endl;
        return 1;
    }

    vector<uint8_t> A = raw_A; 
    vector<int8_t> B(raw_B.size());
    vector<int32_t> C(M * P, 0);

    // B 轉型為 int8
    for(size_t i = 0; i < raw_B.size(); i++) {
        B[i] = static_cast<int8_t>(raw_B[i]);
    }

    cout << "開始計算..." << endl;

    // 計算矩陣乘法
    for (int i = 0; i < M; i++) 
    {
        for (int j = 0; j < P; j++) 
        {
            int32_t sum = 0;
            for (int k = 0; k < N; k++) 
            {
                // A[i][k] * B[k][j]
                sum += generate_golden_output(A[i * N + k], B[j * N + k]);
            }
            C[i * P + j] = sum;
        }
    }
    
    
            // ==========================================
    // 單獨除錯某一行、某一列的乘積細節
    // ==========================================
    
    // 設定你想觀察的 A 的列 (Row i) 和 B 的行 (Col j)
    int target_i = 0;  // 你程式碼中的 i
    int target_j = 64;  // 你程式碼中的 j (注意: 若 P=32, 索引範圍是 0~31)
 
    // 檢查範圍避免當機
    if (target_i >= M || target_j >= P) {
        cout << "[警告] Index 超出範圍！請檢查 target_i 和 target_j" << endl;
    } else {
        ofstream outfile("C[0][64]_Hex.txt");
        outfile << hex << uppercase; // 檔案輸出也設定為 Hex
        outfile << "\n================ DEBUG INFO ================" << endl;
        outfile << "觀察對象: C[" << dec << target_i << "][" << target_j << "]" << endl;
        outfile << "公式: sum += A[" << target_i << "][k] * B[k][" << target_j << "]" << endl;
        outfile << "--------------------------------------------" << endl;
        outfile << " k |  A_val (Hex) |  B_val (Hex) |     Product      |   Current Sum" << endl;
        outfile << "---|--------------|--------------|------------------|------------------" << endl;

        int32_t debug_test = 0;
       
        // 這裡假設 N 是你的維度 (例如 32)
        // 如果你只想跑前 12 個，就把 N 改成 12
        for (int k = 0; k < N; k++) 
        {
            // 取得 A 和 B 的值
            uint8_t val_a = A[target_i * N + k];
            
            // 【注意】標準矩陣乘法抓取 B 的第 j 行 (Column) 是 B[k * P + j]
            // 如果你的 B 已經轉置過，請自行修改為 B[j * N + k]
            int8_t val_b = B[target_j * N + k]; 

            // 計算乘積
            int32_t product = generate_golden_output(val_a, val_b);
            debug_test += product;
            if((k+1)%72==0){ 
                outfile << dec << setw(2) << k << " | " 
                 << hex << uppercase << setw(8) << (int)val_a << "   | " 
                 << setw(8) << (int)(uint8_t)val_b << "   | " 
                 << setw(16) << product << " | " 
                 << setw(16) << debug_test << endl;}
            if((k+1)%72==0){ 
                outfile << dec << setw(2) << k << " | " 
                 << hex << uppercase << setw(8) << (int)val_a << "   | " 
                 << setw(8) << (int)(uint8_t)val_b << "   | " 
                 << setw(16) << product << " | " 
                 << setw(16) << debug_test << endl;}
                 // 輸出詳細資訊 (設定寬度以便對齊)

           
        }
        
        

        outfile << "--------------------------------------------" << endl;
        outfile << "最終結果 (Hex): " << hex << uppercase << debug_test << endl;
        outfile << "============================================" << endl;
    }
    // ==========================================
    // 輸出設定：十六進位 (HEX)
    // ==========================================
    
    

    // 寫入檔案 Result_Hex.txt
    ofstream outfile("Result_Hex.txt");
    outfile << hex << uppercase; // 檔案輸出也設定為 Hex

    for (int i = 0; i < M; i++) {
        for (int j = 0; j < P; j++) {
            outfile << C[i * P + j] << " "; // 用空格分隔
        }
        outfile << endl; // 換行
    }
    outfile.close();
    
    // 恢復為十進位顯示這行訊息
    cout << dec << "完整 HEX 結果已寫入 Result_Hex.txt" << endl;

    return 0;
}