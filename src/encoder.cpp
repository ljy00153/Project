// encoder.cpp - ISA encoder for controller
// 產生 program.txt，每行一個 32-bit 機器碼 (hex)

#include <iostream>
#include <vector>
#include <cstdint>
#include <iomanip>
#include <fstream>

using namespace std;

// ======================= CSR / REG / Opcode =======================

// CSR mapping (最新版 ISA)
enum CSR_ID : uint8_t {
    CSR_DRAM_IFMAP_BASE = 0,
    CSR_DRAM_WEIGHT_BASE= 1,
    CSR_DRAM_OFMAP_BASE = 2,

    CSR_GLB_IFMAP_BASE  = 3,
    CSR_GLB_WEIGHT_BASE = 4,
    CSR_GLB_OPSUM_BASE  = 5,

    CSR_OF_SIZE         = 6,
    CSR_IF_SIZE         = 7,
    CSR_B_SIZE          = 8,
    CSR_K_SIZE          = 9,
    CSR_N_SIZE          = 10,
    CSR_M_SIZE          = 11,

    CSR_MODE            = 12,
    CSR_DATA_FLOW       = 13
};

// REG mapping (loop + compute)
enum REG_ID : uint8_t {
    REG_LOOP_outf = 0,
    REG_LOOP_inf  = 1,
    REG_LOOP_b    = 2,
    REG_LOOP_k    = 3,
    REG_LOOP_n    = 4,
    REG_LOOP_m    = 5,
    REG_VALID_E   = 6      // valid_e for COMPUTE
    // 7~15: general registers
};

enum Opcode : uint8_t {
    // 00000x
    OP_NOP                = 0b000000,
    OP_CFG_SET            = 0b000001,

    // 0001xx
    OP_DMA_LOAD_IFMAP     = 0b000100,
    OP_DMA_LOAD_WEIGHT    = 0b000101,
    OP_DMA_LOAD_PSUM      = 0b000110,
    OP_DMA_STORE_OFMAP    = 0b000111,

    // 0010xx (新版：只有一條 G2P + 一條 P2G_OPSUM)
    OP_G2P                = 0b001000,
    OP_P2G_OPSUM          = 0b001001,

    // 0100xx
    OP_CPT_IFIDX          = 0b010000,
    OP_CPT_WTIDX          = 0b010001,
    OP_CPT_IPIDX          = 0b010010,
    OP_CPT_OPIDX          = 0b010011,

    // 011000
    OP_CPT_TAGXY          = 0b011000,

    // 0111xx
    OP_COMPUTE            = 0b011100,
    OP_WAIT               = 0b011101,
    OP_JUMP               = 0b011110,
    OP_LOOP               = 0b011111,

    // 100xxx
    OP_LOADI              = 0b100000,
    OP_ADDI               = 0b100001,

    // 111111
    OP_END                = 0b111111
};

// ======================= ISA Encoder =======================

struct ISAEncoder {

    // ---------- FMT-CFG ----------
    // 31:14 reserved, 13:10 csr_id, 9:6 type, 5:0 opcode
    uint32_t CFG_SET(uint8_t type, uint8_t csr_id) {
        return ( (uint32_t)(csr_id & 0xF) << 10 ) |
               ( (uint32_t)(type   & 0xF) <<  6 ) |
               OP_CFG_SET;
    }

    // ---------- FMT-DMA ----------
    // 31:14 size18, 13:10 csr_id, 9:6 rs, 5:0 opcode
    uint32_t DMA(uint8_t opcode, uint8_t csr_id, uint8_t rs, uint32_t size) {
        return ( (uint32_t)(size   & 0x3FFFF) << 14 ) |
               ( (uint32_t)(csr_id & 0xF)     << 10 ) |
               ( (uint32_t)(rs     & 0xF)     <<  6 ) |
               opcode;
    }

    // ---------- FMT-STREAM ----------
    // 31:14 size18, 13:10 csr_id, 9:6 rs, 5:0 opcode
    // G2P / P2G_OPSUM 都是這個 format，type 由 CSR 決定，不在指令裡
    uint32_t STREAM(uint8_t opcode, uint8_t csr_id, uint8_t rs, uint32_t size) {
        return ( (uint32_t)(size   & 0x3FFFF) << 14 ) |
               ( (uint32_t)(csr_id & 0xF)     << 10 ) |
               ( (uint32_t)(rs     & 0xF)     <<  6 ) |
               opcode;
    }

    // ---------- FMT-IDX (也兼 FMT-ALU) ----------
    // 31:14 imm18, 13:10 rs, 9:6 rd, 5:0 opcode
    uint32_t IDX_ALU(uint8_t opcode, uint8_t rd, uint8_t rs, int32_t imm) {
        uint32_t uimm = (uint32_t)imm & 0x3FFFF;
        return ( uimm << 14 ) |
               ( (uint32_t)(rs & 0xF) << 10 ) |
               ( (uint32_t)(rd & 0xF) <<  6 ) |
               opcode;
    }

    // ---------- FMT-TAG ----------
    // 31:8 reserved, 7:6 type, 5:0 opcode
    // type: IFMAP/WEIGHT/IPSUM/OPSUM，TAG[] & count_xxx_* 在硬體裡實作
    uint32_t CPT_TAGXY(uint8_t type) {
        return ( (uint32_t)(type & 0x3) << 6 ) | OP_CPT_TAGXY;
    }

    // ---------- FMT-COMPUTE ----------
    // 31:6 reserved, 5:0 opcode
    // valid_e 存在 REG[6]，指令本身不帶參數
    uint32_t COMPUTE() {
        return OP_COMPUTE;
    }

    // ---------- FMT-WAIT ----------
    // 31:8 reserved, 7:6 DMA/GLB, 5:0 opcode
    // spec: DMA = 1, GLB = 0（這裡放在 bit6）
    uint32_t WAIT(bool isDMA) {
        uint8_t val = isDMA ? 1 : 0;
        return ( (uint32_t)(val & 0x1) << 6 ) | OP_WAIT;
    }

    // ---------- FMT-JUMP ----------
    // 31:6 jump_addr26, 5:0 opcode
    uint32_t JUMP(int32_t offset26) {
        uint32_t uoff = (uint32_t)offset26 & 0x3FFFFFF;
        return (uoff << 6) | OP_JUMP;
    }

    // ---------- FMT-LOOP ----------
    // 31:20 offset12, 19:14 target6, 13:10 csr_id, 9:6 loopReg, 5:0 opcode
    uint32_t LOOP(int32_t offset12, uint8_t target,
                  uint8_t csr_id, uint8_t loopReg) {
        uint32_t uoff = (uint32_t)offset12 & 0xFFF;
        return ( uoff << 20 ) |
               ( (uint32_t)(target  & 0x3F) << 14 ) |
               ( (uint32_t)(csr_id  & 0xF ) << 10 ) |
               ( (uint32_t)(loopReg & 0xF ) <<  6 ) |
               OP_LOOP;
    }

    // ---------- FMT-ALU ----------
    uint32_t LOADI(uint8_t rd, int32_t imm) {
        // rs 不用 → 填 0
        return IDX_ALU(OP_LOADI, rd, 0, imm);
    }

    uint32_t ADDI(uint8_t rd, uint8_t rs, int32_t imm) {
        return IDX_ALU(OP_ADDI, rd, rs, imm);
    }

    // ---------- END ----------
    uint32_t END() { return OP_END; }

    // ================= Friendly APIs（比較好記） =================

    // CFG_SET type 對應（照你 ISA 的註解）：
    // 0: DATA_FLOW, 1: TILE, 2: DRAM_IFM_ADDR, 3: DRAM_W_ADDR, 4: DRAM_OFM_ADDR
    // 5: GLB_IFMAP_ADDR, 6: GLB_WEIGHT_ADDR, 7: GLB_OPSUM_ADDR
    // 8: GLB_IFMAP_BASE, 9: GLB_WEIGHT_BASE, 10: GLB_OPSUM_BASE

    uint32_t CFG_DATAFLOW(uint8_t csr_id)    { return CFG_SET(0, csr_id); }
    uint32_t CFG_TILE(uint8_t csr_id)        { return CFG_SET(1, csr_id); }
    uint32_t CFG_DRAM_IFM(uint8_t csr_id)    { return CFG_SET(2, csr_id); }
    uint32_t CFG_DRAM_W(uint8_t csr_id)      { return CFG_SET(3, csr_id); }
    uint32_t CFG_DRAM_OFM(uint8_t csr_id)    { return CFG_SET(4, csr_id); }
    uint32_t CFG_GLB_IFMAP(uint8_t csr_id)   { return CFG_SET(5, csr_id); }
    uint32_t CFG_GLB_WEIGHT(uint8_t csr_id)  { return CFG_SET(6, csr_id); }
    uint32_t CFG_GLB_OPSUM(uint8_t csr_id)   { return CFG_SET(7, csr_id); }
    uint32_t CFG_GLB_IFMAP_BASE(uint8_t csr_id){ return CFG_SET(8, csr_id); }
    uint32_t CFG_GLB_WEIGHT_BASE(uint8_t csr_id){return CFG_SET(9, csr_id); }
    uint32_t CFG_GLB_OPSUM_BASE(uint8_t csr_id){ return CFG_SET(10, csr_id); }

    // DMA
    uint32_t OP_DMA_IFM(uint8_t csr_id, uint8_t rs, uint32_t size) {
        return DMA(OP_DMA_LOAD_IFMAP, csr_id, rs, size);
    }
    uint32_t OP_DMA_W(uint8_t csr_id, uint8_t rs, uint32_t size) {
        return DMA(OP_DMA_LOAD_WEIGHT, csr_id, rs, size);
    }
    uint32_t OP_DMA_PSUM(uint8_t csr_id, uint8_t rs, uint32_t size) {
        return DMA(OP_DMA_LOAD_PSUM, csr_id, rs, size);
    }
    uint32_t OP_DMA_STORE(uint8_t csr_id, uint8_t rs, uint32_t size) {
        return DMA(OP_DMA_STORE_OFMAP, csr_id, rs, size);
    }

    // STREAM
    uint32_t OP_G2P_STREAM(uint8_t csr_id, uint8_t rs, uint32_t size) {
        return STREAM(OP_G2P, csr_id, rs, size);
    }
    uint32_t OP_P2G_OPSUM_STREAM(uint8_t csr_id, uint8_t rs, uint32_t size) {
        return STREAM(OP_P2G_OPSUM, csr_id, rs, size);
    }

    // IDX
    uint32_t OP_CPT_IFIDX(uint8_t rd, uint8_t rs, int32_t imm) {
        return IDX_ALU(OP_CPT_IFIDX, rd, rs, imm);
    }
    uint32_t OP_CPT_WTIDX(uint8_t rd, uint8_t rs, int32_t imm) {
        return IDX_ALU(OP_CPT_WTIDX, rd, rs, imm);
    }
    uint32_t OP_CPT_IPIDX(uint8_t rd, uint8_t rs, int32_t imm) {
        return IDX_ALU(OP_CPT_IPIDX, rd, rs, imm);
    }
    uint32_t OP_CPT_OPIDX(uint8_t rd, uint8_t rs, int32_t imm) {
        return IDX_ALU(OP_CPT_OPIDX, rd, rs, imm);
    }
};

// ======================= Example main =======================

int main() {
    ISAEncoder enc;
    vector<uint32_t> program;

    // 這裡只是示範，你之後可以自己改成真正的 microcode

    // 設定 DRAM IFMAP base 對應的 CSR
    program.push_back(enc.CFG_DRAM_IFM(CSR_DRAM_IFMAP_BASE));
    program.push_back(enc.CFG_DRAM_W(CSR_DRAM_WEIGHT_BASE));
    program.push_back(enc.CFG_DRAM_OFM(CSR_DRAM_OFMAP_BASE));
    
    program.push_back(ADDI)

    program.push_back(enc.(CSR_DATA_FLOW));
    // DMA load IFMAP: CSR[DRAM_IFMAP_BASE] + REG[2]，size=128
    program.push_back(enc.OP_DMA_IFM(CSR_DRAM_IFMAP_BASE, /*rs=*/2, /*size=*/128));
    program.push_back(enc.WAIT(1));// DMA wait
    program.push_back(enc.OP_DMA_W(CSR_DRAM_WEIGHT_BASE, /*rs=*/2, /*size=*/128));
    program.push_back(enc.WAIT(1));// DMA wait
    // 設定 valid_e 之前，你應該會先用 LOADI/ADDI 把 REG[6] 設好
    // 這裡只示範發出一條 COMPUTE
    program.push_back(enc.COMPUTE());

    // END
    program.push_back(enc.END());

    // 寫到 program.txt
    ofstream fout("program.txt");
    if (!fout.is_open()) {
        cerr << "Cannot open program.txt\n";
        return 1;
    }

    for (uint32_t inst : program) {
        fout << hex << setw(8) << setfill('0') << inst << "\n";
    }

    fout.close();
    cout << "program.txt generated (" << program.size() << " instructions)\n";
    return 0;
}
