#include <bits/stdc++.h>
#include <fstream>
using namespace std;

// === LOGGING: 同時輸出到 stdout 與 controller.log ===
ofstream logger("controller.log");

struct DualOut {
    std::ostream &a;
    std::ostream &b;

    template <typename T>
    DualOut &operator<<(const T &v) {
        a << v;
        b << v;
        return *this;
    }

    // 支援 std::endl、std::hex 這種 manipulator
    DualOut &operator<<(std::ostream &(*manip)(std::ostream &)) {
        manip(a);
        manip(b);
        return *this;
    }
};

DualOut dlog{cout, logger};

static int DMA_cycle = 5;
static int GLB_cycle = 2; // 每個 element 的 GLB latency

// === Opcode (對齊 controller_ISA.txt) ===
enum Opcode : uint8_t {
    // 00000x
    OP_NOP                = 0b000000, // no operation
    OP_CFG_SET            = 0b000001, // SET CSR
    OP_SET_ID             = 0b000010, // SET_LN、SET_XID、SET_YID

    // 0001xx
    OP_DMA_LOAD_IFMAP     = 0b000100, // DMA read ifmap
    OP_DMA_LOAD_WEIGHT    = 0b000101, // DMA read weights
    OP_DMA_LOAD_PSUM      = 0b000110, // DMA read psum
    OP_DMA_STORE_OFMAP    = 0b000111, // DMA write ofmap

    // 00100x
    OP_G2P                = 0b001000, // GLB → PE
    OP_P2G_OPSUM          = 0b001001, // PE → GLB opsum

    // 0100xx
    OP_CPT_INDEX          = 0b010000, // compute index in GLB

    // 011000
    OP_CPT_TAGXY          = 0b011000, // compute and SET tagX and tagY for BUS

    // 0111xx
    OP_COMPUTE            = 0b011100, // set pe enable
    OP_WAIT               = 0b011101, // wait for ready
    OP_JUMP               = 0b011110, // absolute jump (pc = imm)
    OP_LOOP               = 0b011111, // loop

    // 10000x
    OP_LOADI              = 0b100000, // rd = imm
    OP_ADDI               = 0b100001, // rd = rs + imm
    OP_MULI               = 0b100010, // rd = rs * imm (unsigned)

    // 1001xx
    OP_ADD                = 0b100100, // rd = rs1 + rs2
    OP_MUL                = 0b100101, // rd = rs1 * rs2 (unsigned)
    // 111111
    OP_END                = 0b111111  // program end
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
    FMT_ALU_I,    // LOADI / ADDI / MULI
    FMT_ALU_R,    // ADD
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

    if (op == OP_LOADI || op == OP_ADDI || op == OP_MULI)
        return FMT_ALU_I;

    if (op == OP_ADD || op == OP_MUL)
        return FMT_ALU_R;

    return FMT_UNKNOWN;
}

struct ISASim {
    static const int CSR_NUM = 32;
    static const int REG_NUM = 32;

    vector<uint32_t> CSR = vector<uint32_t>(CSR_NUM, 0);
    vector<uint32_t> REG = vector<uint32_t>(REG_NUM, 0);

    // TAG 狀態（簡單保留）
    uint8_t tagX_ifmap{}, tagY_ifmap{};
    uint8_t tagX_weight{}, tagY_weight{};
    uint8_t tagX_ipsum{}, tagY_ipsum{};
    uint8_t tagX_opsum{}, tagY_opsum{};

    uint32_t PC = 0;
    bool running = true;

    // 全域 cycle 計數
    uint64_t cur_cycle = 0;
    uint32_t stall_cycle = 0;

    // DMA 狀態
    bool dma_busy = false;
    uint64_t dma_done_cycle = 0;
    bool dma_waiting = false;

    // GLB 狀態
    bool glb_busy = false;
    uint64_t glb_done_cycle = 0;
    bool glb_waiting = false;
    // PE 狀態
    bool pe_busy = false;
    uint64_t PE_done_cycle = 0;
    bool pe_waiting = false;

    vector<uint32_t> program; // 指令記憶體

    bool load_program_txt(const string& filename) {
        ifstream fin(filename);
        if (!fin.is_open()) {
            dlog << "Cannot open " << filename << "\n";
            return false;
        }
        program.clear();
        string line;
        while (fin >> line) {
            uint32_t inst = stoul(line, nullptr, 16);
            program.push_back(inst);
        }
        fin.close();
        dlog << "Loaded " << program.size() << " instructions from " << filename << "\n";
        return true;
    }

    // ===== stub: 真正硬體 I/O 之後再接，現在只 log =====
    void dma_read(uint32_t dram_addr, uint32_t size) {
        dlog << "[DMA READ] addr=" << dram_addr << " size=" << size << "\n";
    }
    void dma_write(uint32_t dram_addr, uint32_t size) {
        dlog << "[DMA WRITE] addr=" << dram_addr << " size=" << size << "\n";
    }
    void glb_to_pe(uint32_t addr, uint8_t tagX, uint8_t tagY, uint32_t size) {
        dlog << "[G2P] addr=" << addr << " tag=("
             << (int)tagX << "," << (int)tagY << ") size=" << size << "\n";
    }
    void pe_to_glb(uint32_t addr, uint8_t tagX, uint8_t tagY, uint32_t size) {
        dlog << "[P2G] addr=" << addr << " tag=("
             << (int)tagX << "," << (int)tagY << ") size=" << size << "\n";
    }
    void wait_dma_msg() { dlog << "[WAIT DMA]\n"; }
    void wait_glb_msg() { dlog << "[WAIT GLB]\n"; }
    void wait_pe_array() { dlog << "[WAIT PE_ARRAY]\n"; }
    void set_pe_en(uint8_t valid_e) {
        dlog << "[COMPUTE] valid_e=" << (int)valid_e << "\n";
    }
    void set_id() {
        dlog << "[SET_ID] (call PE array config module)\n";
    }

    void step() {
        if (!running) return;
        if (PC >= program.size()) {
            dlog << "PC out of range\n";
            running = false;
            return;
        }

        // 確保 REG[0] 永遠為 0（根據 ISA 定義）:contentReference[oaicite:4]{index=4}
        REG[0] = 0;

        // 更新 DMA / GLB 完成狀態
        if (dma_busy && cur_cycle >= dma_done_cycle) {
            dma_busy = false;
        }
        if (glb_busy && cur_cycle >= glb_done_cycle) {
            glb_busy = false;
        }

        uint32_t insn = program[PC];
        uint8_t opcode = insn & 0x3F;
        InstrFormat fmt = get_format(opcode);

        dlog << "PC=0x"
             << std::hex << std::setw(4) << std::setfill('0') << PC
             << std::dec << " ";
        dlog << "OPCODE=0x"
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
                dlog << "[NOP]\n";
            } else if (opcode == OP_CFG_SET) {
                // 這裡先 stub：依 type 塞測試值，對齊 ISA 的 mapping :contentReference[oaicite:5]{index=5}
                uint32_t value = 0;
                switch (type) {
                case 0:  value = 0x10000000; break; // DRAM_IFMAP_BASE
                case 1:  value = 0x20000000; break; // DRAM_WEIGHT_BASE
                case 2:  value = 0x30000000; break; // DRAM_OFMAP_BASE
                case 3:  value = 0x00000000; break; // GLB_IFMAP_BASE
                case 4:  value = 0x00001000; break; // GLB_WEIGHT_BASE
                case 5:  value = 0x00002000; break; // GLB_OPSUM_BASE
                case 6:  value = 256; break;          // OF_SIZE
                case 7:  value = 8192; break;         // IF_SIZE
                case 8:  value = 64; break;          // B_SIZE
                case 9:  value = 144; break;          // K_SIZE
                case 10: value = 128; break;          // N_SIZE
                case 11: value = 64; break;         // M_SIZE
                case 12: value = 1; break;          // MODE
                case 13: value = 0; break;          // DATA_FLOW
                default: value = (uint32_t)type;    break;
                }
                CSR[csr_id] = value;
                dlog << "[CFG_SET] CSR[" << (int)csr_id << "] <= type("
                     << (int)type << ") -> 0x" << hex << value << dec << "\n";
            } else {
                dlog << "\n";
            }
            break;
        }

        // ---------------- FMT_DMA ----------------
        case FMT_DMA: {
            // 31:14 size18, 13:10 csr_id, 9:6 rs, 5:0 opcode :contentReference[oaicite:6]{index=6}
            uint32_t size18 = (insn >> 14) & ((1u << 18) - 1);
            uint8_t csr_id  = (insn >> 10) & 0xF;
            uint8_t rs      = (insn >> 6)  & 0xF;
            uint32_t addr   = CSR[csr_id] + REG[rs];
            uint32_t size   = size18;

            uint64_t latency = (uint64_t)size * (uint64_t)DMA_cycle /4;
            if (latency == 0) {
                dma_busy = false;
            } else {
                dma_busy = true;
                dma_done_cycle = cur_cycle + latency;
                stall_cycle = cur_cycle;
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
                dlog << "\n";
                break;
            }
            break;
        }

        // ---------------- FMT_STREAM: G2P / P2G_OPSUM ----------------
        case FMT_STREAM: {
            // 31:14 size18, 13:10 csr_id, 9:6 rs, 5:0 opcode :contentReference[oaicite:7]{index=7}
            uint32_t size18 = (insn >> 14) & ((1u << 18) - 1);
            uint8_t csr_id  = (insn >> 10) & 0xF;
            uint8_t rs      = (insn >> 6)  & 0xF;
            uint32_t addr   = CSR[csr_id] + REG[rs];
            uint32_t size   = size18;

            uint64_t latency = (uint64_t)size * (uint64_t)GLB_cycle/4;
            if (latency == 0) {
                glb_busy = false;
            } else {
                glb_busy = true;
                glb_done_cycle = cur_cycle + latency;
                PE_done_cycle = glb_done_cycle + 48; // PE 也要等 GLB 完成
                stall_cycle = cur_cycle;
            }

            // tag 這邊照 ISA 的概念可以依 data type 設定，
            // 目前先簡化為 0（之後若要檢查 bus tag 再補）。
            uint8_t tagX = 0, tagY = 0;

            if (opcode == OP_G2P) {
                glb_to_pe(addr, tagX, tagY, size);
            } else if (opcode == OP_P2G_OPSUM) {
                pe_to_glb(addr, tagX, tagY, size);
            } else {
                dlog << "\n";
            }
            break;
        }

        // ---------------- FMT_IDX: CPT_INDEX ----------------
        case FMT_IDX: {
            // 31:14 imm18, 13:10 rs, 9:6 rd, 5:0 opcode :contentReference[oaicite:8]{index=8}
            uint32_t raw_imm = (insn >> 14) & ((1u << 18) - 1);
            int32_t imm = sign_extend(raw_imm, 18);
            uint8_t rs = (insn >> 10) & 0xF;
            uint8_t rd = (insn >> 6)  & 0xF;

            REG[rd] = (uint32_t)((int32_t)REG[rs] + imm);

            dlog << "[CPT_INDEX] REG[" << (int)rd << "] = REG[" << (int)rs
                 << "] + " << imm << " -> " << REG[rd] << "\n";
            break;
        }

        // ---------------- FMT_TAG: CPT_TAGXY ----------------
        case FMT_TAG: {
            // 31:8 reserved, 7:6 type, 5:0 opcode :contentReference[oaicite:9]{index=9}
            uint8_t type = (insn >> 6) & 0x3;
            uint8_t tagX = 0, tagY = 0; // 真實實作會依 TAG counter 變動

            switch (type) {
            case 0: tagX_ifmap = tagX; tagY_ifmap = tagY; break;
            case 1: tagX_weight = tagX; tagY_weight = tagY; break;
            case 2: tagX_ipsum = tagX; tagY_ipsum = tagY; break;
            case 3: tagX_opsum = tagX; tagY_opsum = tagY; break;
            default: break;
            }
            dlog << "[CPT_TAGXY] type=" << (int)type
                 << " tag=(" << (int)tagX << "," << (int)tagY << ")\n";
            break;
        }

        // ---------------- FMT_PEARRAY: COMPUTE / SET_ID ----------------
        case FMT_PEARRAY: {
            if (opcode == OP_COMPUTE) {
                // valid_e 放在 REG[7] :contentReference[oaicite:10]{index=10}
                uint8_t valid_e = REG[7] & 0x7;
                set_pe_en(valid_e);
            } else if (opcode == OP_SET_ID) {
                set_id();
            } else {
                dlog << "\n";
            }
            break;
        }

        // ---------------- FMT_WAIT ----------------
        case FMT_WAIT: {
            // 31:8 reserved, 7:6 type, 5:0 opcode :contentReference[oaicite:11]{index=11}
            uint8_t type = (insn >> 6) & 0x3;

            switch (type) {
            case 0:  // GLB
                if (glb_busy) {
                    if (!glb_waiting) {
                        dlog << "[WAIT GLB] still busy, stall\n";
                        glb_waiting = true;
                    }
                    nextPC = PC;  // stall
                } else {
                    dlog << "[WAIT GLB] done, continue\n";
                    glb_waiting = false;
                }
                break;

            case 1:  // DMA
                if (dma_busy) {
                    if (!dma_waiting) {
                        dlog << "[WAIT DMA] still busy, stall\n";
                        dma_waiting = true;
                    }
                    nextPC = PC;  // stall
                } else {
                    dlog << "[WAIT DMA] done, continue\n";
                    dma_waiting = false;
                }
                break;

            case 2:  // PE ARRAY
                if (cur_cycle != PE_done_cycle) {
                    dlog << "[WAIT PE_ARRAY] still busy, stall\n";
                    nextPC = PC;  // stall
                    pe_waiting = true;
                } else {
                    dlog << "[WAIT PE_ARRAY] done, continue\n";
                    pe_waiting = false;
                }
                break;

            default:
                dlog << "[WAIT] unknown type=" << (int)type << "\n";
                break;
            }
            break;
        }

        // ---------------- FMT_JUMP ----------------
        case FMT_JUMP: {
            // 31:6 jump_addr26, 5:0 opcode
            // 新版 ISA 註解：absolute jump (pc = imm) :contentReference[oaicite:12]{index=12}
            uint32_t target = (insn >> 6) & ((1u << 26) - 1);
            nextPC = target;
            dlog << "[JUMP] PC = " << nextPC << "\n";
            break;
        }

        // ---------------- FMT_LOOP ----------------
        case FMT_LOOP: {
            // 31:20 offset12, 19:14 target6, 13:10 csr_id, 9:6 loopReg, 5:0 op :contentReference[oaicite:13]{index=13}
            uint32_t raw_off = (insn >> 20) & ((1u << 12) - 1);
            int32_t offset   = sign_extend(raw_off, 12);
            uint8_t target   = (insn >> 14) & 0x3F;
            uint8_t csr_id   = (insn >> 10) & 0xF;
            uint8_t loopReg  = (insn >> 6)  & 0xF;
            
            dlog << "[LOOP] REG[" << (int)loopReg << "]<=" << CSR[csr_id]
                 << " ? target=" << (int)target
                 << " : PC+1, after += " << offset
                 << " -> REG=" << REG[loopReg] + offset << "\n";
            //先更新Loop index
            REG[loopReg] = (uint32_t)((int32_t)REG[loopReg] + offset);

            // spec: 先比較 (REG[loopReg] <= CSR[csr_id]) 再 REG += offset
            if ((int32_t)REG[loopReg] < (int32_t)CSR[csr_id]) {
                nextPC = target;
            } else {
                nextPC = PC + 1;
                REG[loopReg] = 0; // 超過目標後歸零
            }


           
            break;
        }

        // ---------------- FMT_ALU_I: LOADI / ADDI / MULI ----------------
        case FMT_ALU_I: {
            // FMT-ALU-I: 31:14 imm18, 13:10 rs, 9:6 rd, 5:0 opcode :contentReference[oaicite:14]{index=14}
            uint32_t raw_imm = (insn >> 14) & ((1u << 18) - 1);
            int32_t imm = sign_extend(raw_imm, 18);
            uint8_t rs = (insn >> 10) & 0xF;
            uint8_t rd = (insn >> 6)  & 0xF;

            if (opcode == OP_LOADI) {
                // LOADI rd, imm ； spec: 等價於 ADDI rd, REG[0], imm
                REG[rd] = (uint32_t)imm;
                dlog << "[LOADI] REG[" << (int)rd << "] = " << imm
                     << " -> " << REG[rd] << "\n";
            } else if (opcode == OP_ADDI) {
                REG[rd] = (uint32_t)((int32_t)REG[rs] + imm);
                dlog << "[ADDI] REG[" << (int)rd << "] = REG[" << (int)rs
                     << "] + " << imm << " -> " << REG[rd] << "\n";
            } else if (opcode == OP_MULI) {
                // 無號乘法：rd = rs * (unsigned imm)
                uint32_t uimm = (uint32_t)imm; // 直接當 32-bit 常數
                REG[rd] = REG[rs] * uimm;
                dlog << "[MULI] REG[" << (int)rd << "] = REG[" << (int)rs
                     << "] * " << uimm << " -> " << REG[rd] << "\n";
            } else {
                dlog << "\n";
            }
            break;
        }

        // ---------------- FMT_ALU_R: ADD ----------------
        case FMT_ALU_R: {
            // FMT-ALU: 31:18 reserved, 17:14 rs2, 13:10 rs1, 9:6 rd, 5:0 op :contentReference[oaicite:15]{index=15}
            uint8_t rs2 = (insn >> 14) & 0xF;
            uint8_t rs1 = (insn >> 10) & 0xF;
            uint8_t rd  = (insn >> 6)  & 0xF;
            if(opcode == OP_ADD){
                // 無號乘法：rd = rs1 * rs2
                REG[rd] = REG[rs1] + REG[rs2];
                dlog << "[ADD] REG[" << (int)rd << "] = REG[" << (int)rs1
                    << "] + REG[" << (int)rs2 << "] -> " << REG[rd] << "\n";
                break;
            }
            else if(opcode == OP_MUL){
                // 無號乘法：rd = rs1 * rs2
                REG[rd] = REG[rs1] * REG[rs2];
                dlog << "[MUL] REG[" << (int)rd << "] = REG[" << (int)rs1
                    << "] * REG[" << (int)rs2 << "] -> " << REG[rd] << "\n";
                break;
            }
            else{
                dlog << "\n";
                break;
            }
        }

        // ---------------- FMT_END ----------------
        case FMT_END: {
            dlog << "[END]\n";
            running = false;
            break;
        }

        default:
            dlog << "Unknown format / opcode=" << (int)opcode << "\n";
            running = false;
            break;
        }

        PC = nextPC;
    }

    void run(int max_steps = 1000000000) {
        while (running && cur_cycle < max_steps) {
            dlog << "cycle " << cur_cycle << ": ";
            step();
            if (dma_waiting) {
                cur_cycle = dma_done_cycle;
            } else if (glb_waiting) {
                cur_cycle = glb_done_cycle;
            } else if (pe_waiting) {
                cur_cycle = PE_done_cycle;
            }
            else {
                cur_cycle++;
        }
        if (cur_cycle >= max_steps) {
            dlog << "Max steps reached\n";
        }
    }
    }
};

int main() {
    ISASim sim;
    sim.load_program_txt("controller.hex");
    sim.run();
    return 0;
}
