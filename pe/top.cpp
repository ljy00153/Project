#include <iostream>
#include <vector>
#include <cstdint>
#include <iomanip>
#include <cstring>
#include <array>
#include <random>
#include "pe_array.cpp"
using namespace std;

#define IFMAP_SIZE 3   // 3 個輸入 (12 bytes)
#define NUM_WEIGHT 4   // 4 組 filter
#define TOTAL_WEIGHT (IFMAP_SIZE * NUM_WEIGHT)  // 12 個 int32_t
#define MODE 1
//1: 6個PE累加，共一組
//2: 3個PE累加，共兩組
//3: 2個PE累加，共三組
//4: 1個PE累加，共六組


int32_t make_int32_from_bytes(uint8_t b0, uint8_t b1, uint8_t b2, uint8_t b3);
array<int32_t, IFMAP_SIZE> generate_in_feature();
array<int32_t, TOTAL_WEIGHT> generate_weight();
array<int32_t, NUM_WEIGHT> generate_golden_output
(const array<int32_t, IFMAP_SIZE>& in_feature_spad, const array<int32_t, TOTAL_WEIGHT>& weight_spad);
array<uint8_t, 4> get_bytes(int32_t value);

random_device rd;  
mt19937 rng(rd());  // random seed
uniform_int_distribution<int32_t> dist_byte(0, 255);

int main() 
{
    PE_Array pe_array;
    // reset all PEs
    pe_array.reset();

    pe_array.mode = MODE;
    pe_array.set_tag();


    array<int32_t, IFMAP_SIZE> in_feature_spad;
    array<int32_t, TOTAL_WEIGHT> weight_spad;
    array<int32_t, NUM_WEIGHT> golden_output;
    array<array<int32_t, NUM_WEIGHT>, 8 * MODE> golden_output_all = {0};
    // 48 PEs, 根據不同mode輸出
    for(int i = 0; i < PE_Array::NUM_PE; i++)
    {
        // === 產生 Input Feature ===
        in_feature_spad = generate_in_feature();
        // === 產生 Weight (12x int32_t) ===
        weight_spad = generate_weight();
        // === 計算 Golden Output ===
        golden_output = generate_golden_output(in_feature_spad, weight_spad);
        // === 計算最後的 Golden Output (6 PEs accumulation) ===
        for(int j = 0; j < NUM_WEIGHT; j++)
        {
            golden_output_all[pe_array.pe[i].tag][j] += golden_output[j];
        }
            
        // === 將 Input Feature 與 Weight 載入 PE Array ===
        pe_array.set_input_feature(i, in_feature_spad);
        pe_array.set_weights(i, weight_spad);

    }

    // full compute
    pe_array.compute_full_all();
    pe_array.add_ipsum_all();
    //pe_array.dump(0);

    //check results
    int errors = 0;
    cout << "\n=== Checking Results ===\n";
    array<int, 6> base = {0};
    switch (MODE)
    {
        case 1:
        {
            base[0] = 40;
            break;
        }
        case 2:
        {
            base[0] = 16;
            base[1] = 40;
            break;
        }
        case 3:
        {
            base[0] = 8;
            base[1] = 24;
            base[2] = 40;
            break;
        }
        case 6:
        {
            base[0] = 0;
            base[1] = 8;
            base[2] = 16;
            base[3] = 24;
            base[4] = 32;
            base[5] = 40;
        }
    }

    for(int i = 0; i < 8 * MODE; i++)
    {
        int num = base[i / 8] + i % 8;
        cout << "\n=== PE[" << num << "] Output ===\n";
        bool match = true;
        for (int j = 0; j < NUM_WEIGHT; j++)
        {
            int32_t pe_output = pe_array.pe[num].output_psum(j);

            if(pe_output != golden_output_all[i][j])
            {
                cout << "PE[" << num << "] out[" << j << "] = " << dec << pe_output;
                //cout << " (Golden: " << golden_output_all[i][j] << ")";
                match = false;
                errors++;
                cout << " <-- MISMATCH!";
            }
            cout << " (Golden: " << golden_output_all[i][j] << ")";
        }
        cout << "\n";
        if(match)
            cout << "PE[" << num << "] Output matches Golden Output!\n";
        else
        {
            cout << "PE[" << num << "] Output does NOT match Golden Output!\n";
            cout << "Expected: " ;
            for (int j = 0; j < NUM_WEIGHT; j++)
                cout << golden_output_all[i][j] << " ";
            cout << "\n\n";
        }
    }

    if(errors == 0)
        cout << "\nAll outputs match golden results!";
    else
        cout << "\nTotal " << errors << " outputs mismatch!";

    return 0;
}

int32_t make_int32_from_bytes(uint8_t b0, uint8_t b1, uint8_t b2, uint8_t b3) 
{
    // 小端序組合成 int32_t
    return static_cast<int32_t>(
        (static_cast<uint32_t>(b3) << 24) |
        (static_cast<uint32_t>(b2) << 16) |
        (static_cast<uint32_t>(b1) << 8)  |
        static_cast<uint32_t>(b0)
    );
}

array<int32_t, IFMAP_SIZE> generate_in_feature()
{
    array<int32_t, IFMAP_SIZE> in_feature_spad;
    array<array<uint8_t, 4>, IFMAP_SIZE> in_feature_bytes;

    for (int i = 0; i < IFMAP_SIZE; i++) 
    {
        for (int b = 0; b < 4; b++)
            in_feature_bytes[i][b] = static_cast<uint8_t>(dist_byte(rng));

        in_feature_spad[i] = make_int32_from_bytes(
            in_feature_bytes[i][0], in_feature_bytes[i][1],
            in_feature_bytes[i][2], in_feature_bytes[i][3]
        );
    }
    return in_feature_spad;
}

array<int32_t, TOTAL_WEIGHT> generate_weight()
{
    array<int32_t, TOTAL_WEIGHT> weight_spad;
    array<array<uint8_t, 4>, TOTAL_WEIGHT> weight_bytes;

   for (int i = 0; i < TOTAL_WEIGHT; i++) 
    {
        for (int b = 0; b < 4; b++)
            weight_bytes[i][b] = static_cast<uint8_t>(dist_byte(rng));

        weight_spad[i] = make_int32_from_bytes(
            weight_bytes[i][0], weight_bytes[i][1],
            weight_bytes[i][2], weight_bytes[i][3]
        );
    }
    return weight_spad;
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