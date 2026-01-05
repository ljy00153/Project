#ifndef PATTERN_GEN_HPP
#define PATTERN_GEN_HPP

#include <iostream>
#include <vector>
#include <cstdint>
#include <iomanip>
#include <cstring>
#include <array>
#include <random>
#include <fstream>
#include <string>
#include <filesystem> // C++17 標準庫，用於建立資料夾

// 為了保持 header 乾淨，不在全域使用 using namespace std;
// 但在實作內部我們會使用它來保持與您原本程式碼的相容性

class PatternGenerator {
private:
    std::mt19937 rng;
    std::uniform_int_distribution<uint8_t> dist_A;
    std::uniform_int_distribution<int8_t> dist_B;
    std::uniform_int_distribution<int32_t> dist_ipsum;

public:
    // 建構子：初始化隨機數種子與分佈範圍
    PatternGenerator() 
        : rng(std::random_device{}()), 
          dist_A(0, 255), 
          dist_B(-128, 127), 
          dist_ipsum(-32, 32) {}

    /**
     * 主要執行函數
     * @param pattern_id : 資料夾編號 (例如 5 -> Pattern5)
     * @param m : Batch Size
     * @param n : IFMAP Size (K)
     * @param p : OFMAP Size (N)
     */
    void run(int pattern_id, int m, int n, int p) {
        using namespace std; // 僅在此函數範圍內使用 std，避免汙染引用者

        string folder = "../hardware/sim/prog" + to_string(pattern_id);

        // ===== 核心修改：自動建立資料夾 (C++17) =====
        try {
            if (!filesystem::exists(folder)) {
                filesystem::create_directories(folder);
                cout << "📁 Created directory: " << folder << endl;
            }
        } catch (const filesystem::filesystem_error& e) {
            cerr << "❌ Error creating directory: " << e.what() << endl;
            return;
        }

        // ===== 建立矩陣 =====
        vector<uint8_t> A(m * n);
        vector<int8_t> B(n * p);
        vector<int8_t> Bt(p * n);
        vector<int32_t> C(m * p);

        // ===== 產生 A 和 B =====
        cout << "✅ [" << folder << "] Generating random matrices (" 
             << m << "x" << n << " * " << n << "x" << p << ")..." << endl;

        for(int i = 0; i < m * n; i++)
            A[i] = generate_in_data_A();
            
        for(int i= 0; i < n * p; i++)
            B[i] = generate_in_data_B();

        // Transpose B -> Bt
        for (int i = 0; i < n; i++) 
            for (int j = 0; j < p; j++) 
                Bt[j * n + i] = B[i * p + j];

        // ===== 計算 C = A × B =====
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < p; j++) {
                int32_t sum = 0;
                for (int k = 0; k < n; k++) 
                    sum += generate_golden_output((A[i * n + k]), B[k * p + j]);
                C[i * p + j] = sum;
            }
        }

        // ===== 加入 Ipsum =====
        vector<int32_t> ipsum(m * p);
        vector<int32_t> C_golden(m * p);
        for (size_t idx = 0; idx < C.size(); idx++) {
            ipsum[idx] = generate_ipsum();
            C_golden[idx] = C[idx] + ipsum[idx];
        }

        // ===== 寫入檔案 =====
        string pathA = folder + "/A.txt";
        string pathB = folder + "/B.txt";
        string pathI = folder + "/ipsum.txt";
        string pathC = folder + "/C_golden.txt";

        ofstream fa(pathA);
        ofstream fb(pathB);
        ofstream fi(pathI);
        ofstream fc(pathC);

        if(!fa.is_open() || !fb.is_open() || !fc.is_open() || !fi.is_open()) {
            cerr << "❌ Cannot open output file in " << folder << endl;
            return;
        }

        // 設定格式
        auto setup_fmt = [](ofstream& fs) { fs << hex << uppercase << setfill('0'); };
        setup_fmt(fa); setup_fmt(fb); setup_fmt(fi); setup_fmt(fc);

        // 寫入 A
        for (int i = 0; i < m; i++) 
            for (int j = 0; j < n; j++)
                fa << setw(2) << (int)(uint8_t)A[i * n + j] << "\n";

        // 寫入 Bt
        for (int i = 0; i < p; i++) 
            for (int j = 0; j < n; j++)
                fb << setw(2) << (int)(uint8_t)Bt[i * n + j] << "\n";

        // 寫入 ipsum
        array<uint8_t, 4> bytes{};
        for (int i = 0; i < m; i++) 
            for (int j = 0; j < p; j++) {
                bytes = get_bytes(ipsum[i * p + j]);
                for(int k = 0; k < 4; k++)
                    fi << setw(2) << (int)(uint8_t)bytes[k] << "\n";
            }
            
        // 寫入 C_golden
        for (int i = 0; i < m; i++) 
            for (int j = 0; j < p; j++) {
                bytes = get_bytes(C_golden[i * p + j]);
                for(int k = 0; k < 4; k++)
                    fc << setw(2) << (int)(uint8_t)bytes[k] << "\n";
            }

        fa.close(); fb.close(); fi.close(); fc.close();

        cout << "✅ Done. Files generated in '" << folder << "'" << endl;
    }

private:
    // --- Helper Functions (保持您原本的邏輯) ---

    int8_t generate_in_data_A() {
        return dist_A(rng);
    }

    int8_t generate_in_data_B() {
        return dist_B(rng);
    }

    int32_t generate_ipsum() {
        return static_cast<int32_t>(dist_ipsum(rng));
    }

    int32_t generate_golden_output(const uint8_t& in_feature_spad, const int8_t& weight_spad) {
        // Dequantize logic: (A ^ 0x80) * B
        int32_t in_feature_byte = int32_t(int8_t(in_feature_spad ^ 0x80));
        int32_t weight_byte = int32_t(weight_spad);
        return in_feature_byte * weight_byte;
    }

    std::array<uint8_t, 4> get_bytes(int32_t value) {
        std::array<uint8_t, 4> bytes{};
        for (int i = 0; i < 4; ++i)
            bytes[i] = (value >> (8 * i)) & 0xFF;
        return bytes;
    }
};

#endif // PATTERN_GEN_HPP