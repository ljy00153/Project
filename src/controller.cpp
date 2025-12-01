#include <bits/stdc++.h>
#include <fstream>
using namespace std;

static int DMA_cycle = 5; 
static int GLB_cycle = 2; // 每個 element 的 GLB latency

// === Opcode (對齊 controller_ISA.txt) ===
enum Opcode : uint8_t {
    // 00000x
    OP_NOP                = 0b000000,
    OP_CFG_SET            = 0b000001,
    OP_SET_ID             = 0b000010,

    // 0001xx
    OP_DMA_LOAD_IFMAP     = 0b000100,
    OP_DMA_LOAD_WEIGHT    = 0b000101,
    OP_DMA_LOAD_PSUM      = 0b000110,
    OP_DMA_STORE_OFMAP    = 0b000111,

    // 00100x
    OP_G2P                = 0b001000,
    OP_P2G_OPSUM          = 0b001001,

    // 0100xx
    OP_CPT_INDEX          = 0b010000,

    // 011000
    OP_CPT_TAGXY          = 0b011000,

    // 0111xx
    OP_COMPUTE            = 0b011100,
    OP_WAIT               = 0b011101,
    OP_JUMP               = 0b011110,
    OP_LOOP               = 0b011111,

    // 10000x / 1001xx
    OP_ADDI               = 0b100001, // FMT-ALU-I
    OP_ADD                = 0b100100, // FMT-ALU
    OP_MUL                = 0b100101, // FMT-ALU

    // 111111
    OP_END                = 0b111111
};

enum InstrFormat {
    FMT_CFG,      // NOP, CFG_SET
    FMT_DMA,      // DMA_LOAD / STORE
    FMT_STREAM,   // G2P / P2G_OPSUM
    FMT_IDX,      // CPT_INDEX
    FMT_TAG,      // CPT_TAGXY
    FMT_PEARRAY,  // COMPUTE / SET_ID
    FMT_WAIT,     // WAIT
    FMT_JUMP,     // JUMP
    FMT_LOOP,     // LOOP
    FMT_ALU,      // ADDI / ADD / MUL
    FMT_END,      // END
    FMT_UNKNOWN
};

static inline int32_t sign_extend(uint32_t x, int bits) {
    uint32_t mask = 1u << (bits - 1);
    return (int32_t)((x ^ mask) - mask);
}

InstrFormat get_format(uint8_t op) {
    if (op == OP_END) return FMT_END;

    if (op == OP_NOP || op == OP_CFG_SET)
        return FMT_CFG;

    if (op == OP_DMA_LOAD_IFMAP || op == OP_DMA_LOAD_WEIGHT ||
        op == OP_DMA_LOAD_PSUM  || op == OP_DMA_STORE_OFMAP)
        return FMT_DMA;

    if (op == OP_G2P || op == OP_P2G_OPSUM)
        return FMT_STREAM;

    if (op == OP_CPT_INDEX)
        return FMT_IDX;

    if (op == OP_CPT_TAGXY)
        return FMT_TAG;

    if (op == OP_COMPUTE || op == OP_SET_ID)
        return FMT_PEARRAY;

    if (op == OP_WAIT)
        return FMT_WAIT;

    if (op == OP_JUMP)
        return FMT_JUMP;

    if (op == OP_LOOP)
        return FMT_LOOP;

    if (op == OP_ADDI || op == OP_ADD || op == OP_MUL)
        return FMT_ALU;

    return FMT_UNKNOWN;
}

struct ISASim {
    static const int CSR_NUM = 32;
    static const int REG_NUM = 32;

    vector<uint32_t> CSR = vector<uint32_t>(CSR_NUM, 0);
    vector<uint32_t> REG = vector<uint32_t>(REG_NUM, 0);

    // tag 狀態（簡單保留）
    uint8_t tagX_ifmap{}, tagY_ifmap{};
    uint8_t tagX_weight{}, tagY_weight{};
    uint8_t tagX_ipsum{}, tagY_ipsum{};
    uint8_t tagX_opsum{}, tagY_opsum{};

    uint32_t PC = 0;
    bool running = true;

    // 全域 cycle 計數（模擬 clock）
    uint64_t cur_cycle = 0;
    uint32_t stall_cycle = 0; 

    // DMA 狀態
    bool dma_busy = false;
    uint64_t dma_done_cycle = 0; // DMA 完成的 cycle

    // GLB 狀態（給 G2P / P2G 用）
    bool glb_busy = false;
    uint64_t glb_done_cycle = 0; // GLB 完成的 cycle

    vector<uint32_t> program; // 指令記憶體

    bool load_program_txt(const string& filename) {
        ifstream fin(filename);
        if (!fin.is_open()) {
            cerr << "Cannot open " << filename << endl;
            return false;
        }
        program.clear();
        string line;
        while (fin >> line) {
            uint32_t inst = stoul(line, nullptr, 16);
            program.push_back(inst);
        }
        fin.close();
        cout << "Loaded " << program.size() << " instructions from " << filename << "\n";
        return true;
    }

    // ===== stub: 這些是輸出行為（你之後可以接真實硬體） =====
    void dma_read(uint32_t dram_addr, uint32_t size) {
        cout << "[DMA READ] addr=" << dram_addr << " size=" << size << "\n";
    }
    void dma_write(uint32_t dram_addr, uint32_t size) {
        cout << "[DMA WRITE] addr=" << dram_addr << " size=" << size << "\n";
    }
    void glb_to_pe(uint32_t addr, uint8_t tagX, uint8_t tagY, uint32_t size) {
        cout << "[G2P] addr=" << addr << " tag=("
             << (int)tagX << "," << (int)tagY << ") size=" << size << "\n";
    }
    void pe_to_glb(uint32_t addr, uint8_t tagX, uint8_t tagY, uint32_t size) {
        cout << "[P2G] addr=" << addr << " tag=("
             << (int)tagX << "," << (int)tagY << ") size=" << size << "\n";
    }
    void wait_dma_msg() { cout << "[WAIT DMA]\n"; }
    void wait_glb_msg() { cout << "[WAIT GLB]\n"; }
    void wait_pe_array() { cout << "[WAIT PE_ARRAY]\n"; }
    void set_pe_en(uint8_t valid_e) {
        cout << "[COMPUTE] valid_e=" << (int)valid_e << "\n";
    }
    void set_id() {
        cout << "[SET_ID] (call PE array config module)\n";
    }

    void step() {
        if (!running) return;
        if (PC >= program.size()) {
            cerr << "PC out of range\n";
            running = false;
            return;
        }

        // 更新 DMA_done 狀態
        if (dma_busy && cur_cycle >= dma_done_cycle) {
            dma_busy = false;
            // cout << "    [DMA_DONE at cycle " << cur_cycle << "]\n";
        }
        // 更新 GLB_done 狀態
        if (glb_busy && cur_cycle >= glb_done_cycle) {
            glb_busy = false;
            // cout << "    [GLB_DONE at cycle " << cur_cycle << "]\n";
        }

        uint32_t insn = program[PC];
        uint8_t opcode = insn & 0x3F;
        InstrFormat fmt = get_format(opcode);

        cout << "PC=0x"
             << std::hex << std::setw(4) << std::setfill('0') << PC
             << std::dec << " ";
        cout << "OPCODE=0x"
             << std::hex << std::setw(2) << std::setfill('0')
             << static_cast<int>(opcode)
             << std::dec << " ";

        uint32_t nextPC = PC + 1;

        switch (fmt) {
        // ---------------- FMT_CFG: NOP / CFG_SET ----------------
        case FMT_CFG: {
            // 31:14 reserved, 13:10 csr_id, 9:6 type, 5:0 opcode
            uint8_t csr_id = (insn >> 10) & 0xF;
            uint8_t type   = (insn >> 6)  & 0xF;

            if (opcode == OP_NOP) {
                cout << "[NOP]\n";
            } else if (opcode == OP_CFG_SET) {
                // 這裡先 stub 成「依 type 塞一個假值」，真正硬體是從外面寫入
                uint32_t value = 0;
                switch (type) {
                case 0:  value = 0x10000000; break; // DRAM_IFMAP_BASE
                case 1:  value = 0x20000000; break; // DRAM_WEIGHT_BASE
                case 2:  value = 0x30000000; break; // DRAM_OFMAP_BASE
                case 3:  value = 0x00000000; break; // GLB_IFMAP_BASE
                case 4:  value = 0x00001000; break; // GLB_WEIGHT_BASE
                case 5:  value = 0x00002000; break; // GLB_OPSUM_BASE
                case 6:  value = 2; break; // OF_SIZE
                case 7:  value = 59; break; // IF_SIZE
                case 8:  value = 1; break; // B_SIZE
                case 9:  value = 2; break;   // K_SIZE
                case 10: value = 4; break;    // N_SIZE
                case 11: value = 32; break;    // M_SIZE
                case 12: value = 1; break;    // MODE(FC)
                case 13: value = 0; break;    // DATAFLOW 先不管
                default: value = (uint32_t)type;     break;
                }
                CSR[csr_id] = value;
                cout << "[CFG_SET] CSR[" << (int)csr_id << "] <= type("
                     << (int)type << ") -> 0x" << hex << value << dec << "\n";
            } else {
                cout << "\n";
            }
            break;
        }

        // ---------------- FMT_DMA ----------------
        case FMT_DMA: {
            // 31:14 size18, 13:10 csr_id, 9:6 rs, 5:0 opcode
            uint32_t size18 = (insn >> 14) & ((1u << 18) - 1);
            uint8_t csr_id  = (insn >> 10) & 0xF;
            uint8_t rs      = (insn >> 6)  & 0xF;
            uint32_t addr   = CSR[csr_id] + REG[rs];
            uint32_t size   = size18;

            // 啟動 DMA，並根據 size 設定 DMA 完成時間
            uint64_t latency = (uint64_t)size * (uint64_t)DMA_cycle;
            if (latency == 0)dma_busy =false; // size=0 不啟動 DMA
            else{
                dma_busy = true;
                dma_done_cycle = cur_cycle + latency;
                stall_cycle = cur_cycle; // DMA 啟動時的 PC（debug 用）
                } 
           

            switch (opcode) {
            case OP_DMA_LOAD_IFMAP:
            case OP_DMA_LOAD_WEIGHT:
            case OP_DMA_LOAD_PSUM:
                dma_read(addr, size);
                break;
            case OP_DMA_STORE_OFMAP:
                dma_write(addr, size);
                break;
            default:
                cout << "\n";
                break;
            }
            break;
        }

        // ---------------- FMT_STREAM: G2P / P2G_OPSUM ----------------
        case FMT_STREAM: {
            // 31:14 size18, 13:10 csr_id, 9:6 rs, 5:0 opcode
            uint32_t size18 = (insn >> 14) & ((1u << 18) - 1);
            uint8_t csr_id  = (insn >> 10) & 0xF;
            uint8_t rs      = (insn >> 6)  & 0xF;
            uint32_t addr   = CSR[csr_id] + REG[rs];
            uint32_t size   = size18;

            // 模擬 GLB ↔ PE 的 latency：size * GLB_cycle
            uint64_t latency = (uint64_t)size * (uint64_t)GLB_cycle;
            if (latency == 0)glb_busy =false; // size=0 不啟動 DMA
            else{
                glb_busy = true;
                glb_done_cycle = cur_cycle + latency;
                stall_cycle = cur_cycle; // DMA 啟動時的 PC（debug 用）
                } 
           
            // 這裡 tagX/tagY 真正應該由 CPT_TAGXY 控、加 TAG[]，
            // 目前簡化先印 0
            uint8_t tagX = 0, tagY = 0;

            if (opcode == OP_G2P) {
                glb_to_pe(addr, tagX, tagY, size);
            } else if (opcode == OP_P2G_OPSUM) {
                pe_to_glb(addr, tagX, tagY, size);
            } else {
                cout << "\n";
            }
            break;
        }

        // ---------------- FMT_IDX: CPT_INDEX ----------------
        case FMT_IDX: {
            // 31:14 imm18, 13:10 rs, 9:6 rd, 5:0 opcode
            uint32_t raw_imm = (insn >> 14) & ((1u << 18) - 1);
            int32_t imm = sign_extend(raw_imm, 18);
            uint8_t rs = (insn >> 10) & 0xF;
            uint8_t rd = (insn >> 6)  & 0xF;

            REG[rd] = (uint32_t)((int32_t)REG[rs] + imm);

            cout << "[CPT_INDEX] REG[" << (int)rd << "] = REG[" << (int)rs
                 << "] + " << imm << " -> " << REG[rd] << "\n";
            break;
        }

        // ---------------- FMT_TAG: CPT_TAGXY ----------------
        case FMT_TAG: {
            // 31:8 reserved, 7:6 type, 5:0 opcode
            uint8_t type = (insn >> 6) & 0x3;
            uint8_t tagX = 0, tagY = 0; // 真實硬體會用 TAG[] counter 來更新

            switch (type) {
            case 0: tagX_ifmap = tagX; tagY_ifmap = tagY; break;
            case 1: tagX_weight = tagX; tagY_weight = tagY; break;
            case 2: tagX_ipsum = tagX; tagY_ipsum = tagY; break;
            case 3: tagX_opsum = tagX; tagY_opsum = tagY; break;
            }
            cout << "[CPT_TAGXY] type=" << (int)type
                 << " tag=(" << (int)tagX << "," << (int)tagY << ")\n";
            break;
        }

        // ---------------- FMT_PEARRAY: COMPUTE / SET_ID ----------------
        case FMT_PEARRAY: {
            if (opcode == OP_COMPUTE) {
                // 新版 ISA: valid_e 在 REG[7]
                uint8_t valid_e = REG[7] & 0x7;
                set_pe_en(valid_e);
            } else if (opcode == OP_SET_ID) {
                set_id();
            } else {
                cout << "\n";
            }
            break;
        }

        // ---------------- FMT_WAIT ----------------
        case FMT_WAIT: {
            // 31:8 reserved, 7:6 type(2 bits), 5:0 opcode
            uint8_t type = (insn >> 6) & 0x3;
            
            switch (type) {
            case 0:  // GLB
                wait_glb_msg();
                if (glb_busy) {
                    cout << "    [WAIT GLB] still busy, stall at cycle "
                         << stall_cycle << "\n";
                    nextPC = PC; // 停在同一條
                } else {
                    cout << "    [WAIT GLB] done, continue\n";
                }
                break;
            case 1:  // DMA
                wait_dma_msg();
                if (dma_busy) {
                    // 還沒 done → 停在同一條指令，不前進 PC
                    cout << "    [WAIT DMA] still busy, stall at cycle "
                         << stall_cycle << "\n";
                    nextPC = PC; // 不變
                } else {
                    // 已經 done → 正常往下一條
                    cout << "    [WAIT DMA] done, continue\n";
                }
                break;
            case 2:  // PE_ARRAY
                wait_pe_array();
                break;
            default:
                cout << "[WAIT] unknown type=" << (int)type << "\n";
                break;
            }
            break;
        }

        // ---------------- FMT_JUMP ----------------
        case FMT_JUMP: {
            // 31:6 jump_addr26, 5:0 opcode
            uint32_t raw = (insn >> 6) & ((1u << 26) - 1);
            // 新版 spec: PC = PC + jump_addr，這裡用有號位移，方便往回跳
            int32_t off = sign_extend(raw, 26);
            nextPC = (uint32_t)((int32_t)PC + off);
            cout << "[JUMP] PC += " << off << " -> " << nextPC << "\n";
            break;
        }

        // ---------------- FMT_LOOP ----------------
        case FMT_LOOP: {
            // 31:20 offset12, 19:14 target6, 13:10 csr_id, 9:6 loopReg, 5:0 op
            uint32_t raw_off = (insn >> 20) & ((1u << 12) - 1);
            int32_t offset   = sign_extend(raw_off, 12);
            uint8_t target   = (insn >> 14) & 0x3F;
            uint8_t csr_id   = (insn >> 10) & 0xF;
            uint8_t loopReg  = (insn >> 6)  & 0xF;
            
            REG[loopReg] = (uint32_t)((int32_t)REG[loopReg] + offset);

            if (REG[loopReg] < CSR[csr_id]) {
                nextPC = target;
            } else {
                nextPC = PC + 1;
            }

            cout << "[LOOP] REG[" << (int)loopReg << "]+=" << offset
                 << " -> " << REG[loopReg]
                 << ", nextPC=" << nextPC << "\n";
            break;
        }

        // ---------------- FMT_ALU: ADDI / ADD / MUL ----------------
        case FMT_ALU: {
            if (opcode == OP_ADDI) {
                // FMT-ALU-I: 31:14 imm18, 13:10 rs, 9:6 rd, 5:0 opcode
                uint32_t raw_imm = (insn >> 14) & ((1u << 18) - 1);
                int32_t imm = sign_extend(raw_imm, 18);
                uint8_t rs = (insn >> 10) & 0xF;
                uint8_t rd = (insn >> 6)  & 0xF;
                REG[rd] = (uint32_t)((int32_t)REG[rs] + imm);
                cout << "[ADDI] REG[" << (int)rd << "] = REG[" << (int)rs
                     << "] + " << imm << " -> " << REG[rd] << "\n";
            } else if (opcode == OP_ADD || opcode == OP_MUL) {
                // FMT-ALU: 31:18 reserved, 17:14 rs2, 13:10 rs1, 9:6 rd, 5:0 op
                uint8_t rs2 = (insn >> 14) & 0xF;
                uint8_t rs1 = (insn >> 10) & 0xF;
                uint8_t rd  = (insn >> 6)  & 0xF;
                if (opcode == OP_ADD) {
                    REG[rd] = REG[rs1] + REG[rs2];
                    cout << "[ADD] REG[" << (int)rd << "] = REG[" << (int)rs1
                         << "] + REG[" << (int)rs2 << "] -> " << REG[rd] << "\n";
                } else {
                    REG[rd] = REG[rs1] * REG[rs2];
                    cout << "[MUL] REG[" << (int)rd << "] = REG[" << (int)rs1
                         << "] * REG[" << (int)rs2 << "] -> " << REG[rd] << "\n";
                }
            } else {
                cout << "\n";
            }
            break;
        }

        // ---------------- FMT_END ----------------
        case FMT_END: {
            cout << "[END]\n";
            running = false;
            break;
        }

        default:
            cerr << "Unknown format / opcode=" << (int)opcode << "\n";
            running = false;
            break;
        }

        PC = nextPC;
    }

    void run(int max_steps = 10000000) {
        int steps = 0;
        while (running && steps < max_steps) {
            cout << "cycle " << cur_cycle << ": ";
            step();
            ++cur_cycle;
            ++steps;
        }
        if (steps >= max_steps) {
            cerr << "Max steps reached\n";
        }
    }
};

int main() {
    ISASim sim;
    sim.load_program_txt("example.hex"); // assembler 出來的 program.hex 改名或直接用這個檔名
    sim.run();
    return 0;
}
