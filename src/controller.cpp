#include <bits/stdc++.h>
#include <fstream>
using namespace std;

// === Opcode (對齊 assembler OPC) ===
enum Opcode : uint8_t {
    OP_NOP                = 0b000000,
    OP_CFG_SET            = 0b000001,

    OP_DMA_LOAD_IFMAP     = 0b000100,
    OP_DMA_LOAD_WEIGHT    = 0b000101,
    OP_DMA_LOAD_PSUM      = 0b000110,
    OP_DMA_STORE_OFMAP    = 0b000111,

    OP_G2P                = 0b001000,
    OP_P2G_OPSUM          = 0b001001,

    OP_CPT_IFIDX          = 0b010000,
    OP_CPT_WTIDX          = 0b010001,
    OP_CPT_IPIDX          = 0b010010,
    OP_CPT_OPIDX          = 0b010011,

    OP_CPT_TAGXY          = 0b011000,

    OP_COMPUTE            = 0b011100,
    OP_WAIT               = 0b011101,
    OP_JUMP               = 0b011110,
    OP_LOOP               = 0b011111,

    OP_LOADI              = 0b100000,
    OP_ADDI               = 0b100001,

    OP_END                = 0b111111
};

enum InstrFormat {
    FMT_CFG,
    FMT_DMA,
    FMT_STREAM,
    FMT_IDX,
    FMT_TAG,
    FMT_COMPUTE,
    FMT_WAIT,
    FMT_JUMP,
    FMT_LOOP,
    FMT_ALU,
    FMT_END,
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

    if (op == OP_CPT_IFIDX || op == OP_CPT_WTIDX ||
        op == OP_CPT_IPIDX || op == OP_CPT_OPIDX)
        return FMT_IDX;

    if (op == OP_CPT_TAGXY) return FMT_TAG;
    if (op == OP_COMPUTE)   return FMT_COMPUTE;
    if (op == OP_WAIT)      return FMT_WAIT;
    if (op == OP_JUMP)      return FMT_JUMP;
    if (op == OP_LOOP)      return FMT_LOOP;

    if (op == OP_LOADI || op == OP_ADDI)
        return FMT_ALU;

    return FMT_UNKNOWN;
}

struct ISASim {
    static const int CSR_NUM = 32;
    static const int REG_NUM = 32;

    vector<uint32_t> CSR = vector<uint32_t>(CSR_NUM, 0);
    vector<uint32_t> REG = vector<uint32_t>(REG_NUM, 0);

    // 只是保留，不一定會真的用到
    uint8_t tagX_ifmap{}, tagY_ifmap{};
    uint8_t tagX_weight{}, tagY_weight{};
    uint8_t tagX_ipsum{}, tagY_ipsum{};
    uint8_t tagX_opsum{}, tagY_opsum{};

    uint32_t PC = 0;
    bool running = true;

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

    // ===== stub: 這些是輸出行為（保持不變） =====
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
    void wait_dma() { cout << "[WAIT DMA]\n"; }
    void wait_glb() { cout << "[WAIT GLB]\n"; }
    void set_pe_en(uint8_t valid_e) {
        cout << "[COMPUTE] valid_e=" << (int)valid_e << "\n";
    }

    void step() {
        if (!running) return;
        if (PC >= program.size()) {
            cerr << "PC out of range\n";
            running = false;
            return;
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
        case FMT_CFG: {
            // 31:14 reserved, 13:10 csr_id, 9:6 type, 5:0 opcode
            uint8_t csr_id = (insn >> 10) & 0xF;
            if (opcode == OP_NOP) {
                // do nothing
                cout << "\n";
            } else {
                uint32_t value = 256; // stub
                CSR[csr_id] = value;
                cout << "[CFG] CSR[" << (int)csr_id << "] = 0x"
                     << hex << value << dec << "\n";
            }
            break;
        }

        case FMT_DMA: {
            // 31:14 size18, 13:10 csr_id, 9:6 rs, 5:0 opcode
            uint32_t size18 = (insn >> 14) & ((1u << 18) - 1);
            uint8_t csr_id = (insn >> 10) & 0xF;
            uint8_t rs     = (insn >> 6)  & 0xF;
            uint32_t addr  = CSR[csr_id] + REG[rs];
            uint32_t size  = size18;

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

        case FMT_STREAM: {
            // 31:14 size18, 13:10 csr_id, 9:6 rs, 5:0 opcode
            uint32_t size18 = (insn >> 14) & ((1u << 18) - 1);
            uint8_t csr_id = (insn >> 10) & 0xF;
            uint8_t rs     = (insn >> 6)  & 0xF;
            uint32_t addr  = CSR[csr_id] + REG[rs];
            uint32_t size  = size18;
            uint8_t tagX = 0, tagY = 0; // 新 ISA 沒有 tagX/Y，先填 0

            if (opcode == OP_G2P) {
                glb_to_pe(addr, tagX, tagY, size);
            } else if (opcode == OP_P2G_OPSUM) {
                pe_to_glb(addr, tagX, tagY, size);
            } else {
                cout << "\n";
            }
            break;
        }

        case FMT_IDX: {
            // 31:14 imm18, 13:10 rs, 9:6 rd, 5:0 opcode
            uint32_t raw_imm = (insn >> 14) & ((1u << 18) - 1);
            int32_t imm = sign_extend(raw_imm, 18);
            uint8_t rs = (insn >> 10) & 0xF;
            uint8_t rd = (insn >> 6)  & 0xF;

            REG[rd] = (uint32_t)((int32_t)REG[rs] + imm);

            cout << "[IDX] REG[" << (int)rd << "] = REG[" << (int)rs
                 << "] + " << imm << " -> " << REG[rd] << "\n";
            break;
        }

        case FMT_TAG: {
            // 新版 FMT-TAG: 31:8 reserved, 7:6 type, 5:0 opcode
            uint8_t type = (insn >> 6) & 0x3;
            uint8_t tagX = 0, tagY = 0; // 硬體裡有自己的 counter，這裡先 0

            switch (type) {
            case 0: tagX_ifmap = tagX; tagY_ifmap = tagY; break;
            case 1: tagX_weight = tagX; tagY_weight = tagY; break;
            case 2: tagX_ipsum = tagX; tagY_ipsum = tagY; break;
            case 3: tagX_opsum = tagX; tagY_opsum = tagY; break;
            }
            cout << "[TAG] type=" << (int)type
                 << " tag=(" << (int)tagX << "," << (int)tagY << ")\n";
            break;
        }

        case FMT_COMPUTE: {
            // valid_e 放在 REG[6]
            uint8_t valid_e = REG[6] & 0x7;
            set_pe_en(valid_e);
            break;
        }

        case FMT_WAIT: {
            // 31:8 reserved, 7:6 (1bit encode), 5:0 opcode
            uint8_t flag = (insn >> 6) & 0x1;
            bool isDMA = flag ? true : false;
            if (isDMA) wait_dma();
            else       wait_glb();
            break;
        }

        case FMT_JUMP: {
            // 31:6 jump_addr26 (absolute index), 5:0 opcode
            uint32_t target = (insn >> 6) & ((1u << 26) - 1);
            nextPC = target;
            cout << "[JUMP] PC -> " << nextPC << "\n";
            break;
        }

        case FMT_LOOP: {
            // 31:20 offset12, 19:14 target6, 13:10 csr_id, 9:6 loopReg, 5:0 op
            uint32_t raw_off = (insn >> 20) & ((1u << 12) - 1);
            int32_t offset   = sign_extend(raw_off, 12);
            uint8_t target   = (insn >> 14) & 0x3F;
            uint8_t csr_id   = (insn >> 10) & 0xF;
            uint8_t loopReg  = (insn >> 6)  & 0xF;

            if (REG[loopReg] <= CSR[csr_id]) {
                nextPC = target;
            } else {
                nextPC = PC + 1;
            }
            REG[loopReg] = (uint32_t)((int32_t)REG[loopReg] + offset);

            cout << "[LOOP] REG[" << (int)loopReg << "]+=" << offset
                 << " -> " << REG[loopReg]
                 << ", nextPC=" << nextPC << "\n";
            break;
        }

        case FMT_ALU: {
            if (opcode == OP_LOADI) {
                // 31:10 imm22, 9:6 rd, 5:0 opcode
                uint8_t rd = (insn >> 6) & 0xF;
                uint32_t raw_imm = (insn >> 10);
                int32_t imm = sign_extend(raw_imm, 22);
                REG[rd] = (uint32_t)imm;
                cout << "[LOADI] REG[" << (int)rd << "] = " << imm << "\n";
            } else if (opcode == OP_ADDI) {
                // 31:14 imm18, 13:10 rs, 9:6 rd, 5:0 opcode
                uint32_t raw_imm = (insn >> 14) & ((1u << 18) - 1);
                int32_t imm = sign_extend(raw_imm, 18);
                uint8_t rs = (insn >> 10) & 0xF;
                uint8_t rd = (insn >> 6)  & 0xF;
                REG[rd] = (uint32_t)((int32_t)REG[rs] + imm);
                cout << "[ADDI] REG[" << (int)rd << "] = REG[" << (int)rs
                     << "] + " << imm << " -> " << REG[rd] << "\n";
            } else {
                cout << "\n";
            }
            break;
        }

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

    void run(int max_steps = 1000000) {
        int steps = 0;
        while (running && steps < max_steps) {
            step();
            ++steps;
        }
        if (steps >= max_steps) {
            cerr << "Max steps reached\n";
        }
    }
};

int main() {
    ISASim sim;
    sim.load_program_txt("program.hex"); // 你可以把 assembler 的 program.hex 改名成這個
    sim.run();
    return 0;
}
