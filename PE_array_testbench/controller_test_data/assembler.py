import re
import sys
import os

# ----------------------------------
#  CSR + Loop Register Symbol Tables 
# ----------------------------------
CSR_MAP = {
    'DRAM_IFMAP_BASE':      0,
    'DRAM_WEIGHT_BASE':     1,
    'DRAM_OFMAP_BASE':      2,

    'GLB_IFMAP_BASE':       3,
    'GLB_WEIGHT_BASE':      4,
    'GLB_OPSUM_BASE':       5,

    'OF_SIZE':              6,
    'IF_SIZE':              7,
    'B_SIZE':               8,
    'K_SIZE':               9,
    'N_SIZE':               10,
    'M_SIZE':               11,

    'MODE':                 12,
    'DATA_FLOW':            13,
}

LOOP_REG_MAP = {
    'x0':0,
    'outf': 1,
    'inf':  2,
    'b':    3,
    'k':    4,
    'n':    5,
    'm':    6,
}

TAG_TYPE_MAP = {
    'IFMAP':    0,
    'WEIGHT':   1,
    'IPSUM':    2,
    'OPSUM':    3,
}

# ----------------------
# Instruction Opcodes
# ----------------------
OPC = {
    'NOP':              0b000000,
    'CFG_SET':          0b000001,
    'SET_ID':           0b000010,

    'DMA_LOAD_IFMAP':   0b000100,
    'DMA_LOAD_WEIGHT':  0b000101,
    'DMA_LOAD_PSUM':    0b000110,
    'DMA_STORE_OFMAP':  0b000111,

    'G2P':              0b001000,
    'P2G_OPSUM':        0b001001,

    'CPT_INDEX':        0b010000,

    'CPT_TAGXY':        0b011000,

    'COMPUTE':          0b011100,
    'WAIT':             0b011101,
    'JUMP':             0b011110,
    'LOOP':             0b011111,

    'LOADI':            0b100000,
    'ADDI':             0b100001,
    'MULI':              0b100010,

    'ADD':              0b100100,
    'MUL':              0b100101,
    'END':              0b111111,
}

WAIT = {
    'GLB': 0,
    'DMA': 1,
    'PE_ARRAY': 2
}

# --------------------------------------
# CONSTANT TABLE
# --------------------------------------

CONSTANTS = {}

# -------------------------------------------------------
# Operand Parser
# -------------------------------------------------------
def parse_operand(tok):
    tok = tok.strip()
    # constant support
    if tok in CONSTANTS:
        return ("imm", CONSTANTS[tok])
    # Loop registers
    if tok in LOOP_REG_MAP:
        return ("reg", LOOP_REG_MAP[tok])
    # CSR names
    if tok in CSR_MAP:
        return ("csr", CSR_MAP[tok])
    # TAG type
    if tok in TAG_TYPE_MAP:
        return ("tagtype", TAG_TYPE_MAP[tok])
    # WAIT type
    if tok in WAIT:
        return ("waittype", WAIT[tok])

    # CSR[index]
    m = re.match(r'^CSR\[(\d+)\]$', tok)
    if m:
        return ("csr", int(m.group(1)))

    # REG[index]
    m = re.match(r'^REG\[(\d+)\]$', tok)
    if m:
        return ("reg", int(m.group(1)))

    # R#
    m = re.match(r'^R(\d+)$', tok, re.IGNORECASE)
    if m:
        return ("reg", int(m.group(1)))

    # hex number
    if re.match(r'^0x[0-9A-Fa-f]+$', tok):
        return ("imm", int(tok, 16))

    # decimal number
    if re.match(r'^-?\d+$', tok):
        return ("imm", int(tok))

    # otherwise → label
    return ("label", tok)

# -------------------------------------------------------
# Pass 1: parse program & collect labels
# -------------------------------------------------------
def assemble(lines):
    program = []
    labels = {}
    global CONSTANTS
    pc = 0 # Program Counter

    for lineno, line in enumerate(lines):
        original_line = line.strip() # <-- 儲存原始行，用於錯誤報告
        line = original_line

        # Strip comments
        if "#" in line:
           line = line.split("#", 1)[0].strip()
        if line == "":
            continue

        # ---------- constant define ----------
        if line.startswith(".set"):
            # format: .set NAME, value
            try:
                _, rest = line.split(None, 1)
                name, val = rest.split(",", 1)
            except ValueError:
                raise ValueError(f"Invalid .set format on line {lineno + 1}: {original_line}")
            
            name = name.strip()
            val = val.strip()

            # support hex or dec literal values for .set
            if re.match(r'^0x[0-9A-Fa-f]+$', val):
                CONSTANTS[name] = int(val, 16)
            elif re.match(r'^-?\d+$', val):
                 CONSTANTS[name] = int(val)
            else:
                raise ValueError(f"Invalid constant value for .set on line {lineno + 1}: {val} in line: {original_line}")

            continue

        # ---------- label ----------
        if line.endswith(":"):
            label = line[:-1].strip()
            if label in labels:
               raise Exception(f"Duplicate label definition: {label} on line {lineno + 1}")
            labels[label] = pc
            continue

        # ---------- assembly instruction ----------
        parts = line.split()
        op = parts[0].upper()

        operands = []
        if len(parts) > 1:
            # Rejoin and split by comma to handle spaces in operands (e.g., in labels)
            operand_text = " ".join(parts[1:])
            operands = [x.strip() for x in operand_text.split(",")]

        # 儲存原始行內容，以便在 Pass 2 報告錯誤時使用
        program.append((pc, op, operands, lineno, original_line))
        pc += 1

    return program, labels

# -------------------------------------------------------
# Helper to encode 32-bit
# -------------------------------------------------------
def enc32(**kwargs):
    v = 0
    for key, val in kwargs.items():
        shift = val[0]
        field  = val[1]
        v |= (field << shift)
    return v & 0xffffffff


# -------------------------------------------------------
# Helper to check operand count and raise a meaningful error
# -------------------------------------------------------
def check_operands(op, operands, expected_count, lineno, original_line):
    #Checks the number of operands and provides detailed error messages if mismatch occurs."""
    if len(operands) != expected_count:
        # Construct the expected syntax format
        syntax_map = {
            'CFG_SET': 'csr, type (e.g., CFG_SET MODE, 0x1)',
            'DMA_*': 'csr_id, rs, size (e.g., DMA_LOAD_IFMAP 0, R0, 1024)',
            'G2P': 'csr_id, rs, size',
            'P2G_OPSUM': 'csr_id, rs, size',
            'CPT_INDEX': 'rd, rs, imm (e.g., CPT_INDEX R0, R1, 1)', # Updated for CPT_INDEX
            'CPT_TAGXY': 'type (e.g., CPT_TAGXY IFMAP)',
            'WAIT': 'type (e.g., WAIT DMA)',
            'JUMP': 'label (e.g., JUMP start_loop)',
            'LOOP': 'csr, reg, label, offset (e.g., LOOP N_SIZE, n, loop_body, 1)',
            'LOADI': 'rd, imm (e.g., LOADI R0, 10)',
            'ADDI': 'rd, rs, imm (e.g., ADDI R0, R0, 4)',
            'ADD': 'rd, rs1, rs2 (e.g., ADD R0, R1, R2)',
            'MUL': 'rd, rs1, rs2 (e.g., MUL R0, R1, R2)',
        }
        
        # Use a generic key for instruction families
        syntax_key = op
        if op.startswith("DMA_"): syntax_key = "DMA_*"

        expected_syntax = syntax_map.get(syntax_key, 'N/A')
        
        # NOTE: lineno is 0-based in assembly code, adding 1 for user readability
        error_msg = (
            f"(Operand Count Mismatch) for {op} at line {lineno + 1}.\n"
            f"Expected_count: {expected_count}, Receive: {len(operands)}.\n"
            f"請檢查參數之間是否遺漏了逗號 (,)。\n"
            f"Expected: {op} {expected_syntax}\n"
            f"Original: {original_line}"
        )
        raise Exception(error_msg)
# -------------------------------------------------------
# Pass 2: encode instructions
# -------------------------------------------------------
def encode(program, labels):
    out = []

    for pc, op, operands, lineno, original_line in program:

        # ------------------------------
        # NOP / END
        # ------------------------------
        if op == "NOP" or op == "END":
            # These instructions should not have operands
            if operands:
                raise Exception(f"{op} No operands expected at line {lineno + 1}.\n Original: {original_line}")
            out.append( OPC[op] )
            continue

        # ------------------------------
        # CFG_SET
        # FMT-CFG
        # Syntax: CFG_SET csr, type
        # ------------------------------
        if op == "CFG_SET":
            check_operands(op, operands, 2, lineno, original_line)
            csr, typ = operands
            t0, csr_id = parse_operand(csr)
            t1, typ_val = parse_operand(typ)
            instr = enc32(
                opcode=(0, OPC['CFG_SET']),
                type=(6, typ_val & 0xF),
                csr=(10, csr_id & 0xF),
            )
            out.append(instr)
            continue

        # ------------------------------
        # DMA
        # FMT-DMA
        # Syntax: DMA_LOAD_IFMAP   csr_id rs size
        #         DMA_LOAD_WEIGHT  csr_id rs size
        #         DMA_LOAD_PSUM    csr_id rs size
        #         DMA_STORE_OFMAP  csr_id rs size
        # ------------------------------
        if op.startswith("DMA_"):
            check_operands(op, operands, 3, lineno, original_line)
            t, csr_id = parse_operand(operands[0])
            rs, r = parse_operand(operands[1])
            s, c = parse_operand(operands[2])
            instr = enc32(
                opcode=(0, OPC[op]),
                rs=(6, r & 0xF),
                csr=(10, csr_id & 0xF),
                size=(14, c & 0x3FFFF),
            )
            out.append(instr)
            continue

        # ------------------------------
        # G2P / P2G_OPSUM
        # FMT-STREAM
        # Syntax: G2P          csr_id rs size
        #         P2G_OPSUM    csr_id rs size
        # ------------------------------
        if op == "G2P" or op == "P2G_OPSUM":
            check_operands(op, operands, 3, lineno, original_line)
            tcsr, csr_id = parse_operand(operands[0])
            tr, r = parse_operand(operands[1])
            ts, sz = parse_operand(operands[2])
            instr = enc32(
                opcode=(0, OPC[op]),
                rs=(6, r & 0xF),
                csr=(10, csr_id & 0xF),
                size=(14, sz & 0x3FFFF),
            )
            out.append(instr)
            continue

        # ------------------------------
        # CPT_IDX (IFIDX / WTIDX / IPIDX / OPIDX)
        # FMT-IDX
        # Syntax: OP_CPT_INDEX rd rs imm
        # ------------------------------
        if op.startswith("CPT_") and op.endswith("INDEX"):
            check_operands(op, operands, 3, lineno, original_line)
            trd, rd = parse_operand(operands[0])
            trs, rs = parse_operand(operands[1])
            timm, imm = parse_operand(operands[2])
            instr = enc32(
                opcode=(0, OPC[op]),
                rd=(6, rd & 0xF),
                rs=(10, rs & 0xF),
                imm=(14, imm & 0x3FFFF),
            )
            out.append(instr)
            continue

        # ------------------------------
        # CPT_TAGXY
        # Syntax: CPT_TAGXY type
        # ------------------------------
        if op == "CPT_TAGXY":
            check_operands(op, operands, 1, lineno, original_line)
            t, typ = parse_operand(operands[0])
            instr = enc32(
                opcode=(0, OPC['CPT_TAGXY']),
                type=(6, typ & 0x3),
            )
            out.append(instr)
            continue

        # ------------------------------
        # COMPUTE
        # FMT-PE_ARRAY
        # Syntax: COMPUTE SET_ID
        # ------------------------------
        if op == "COMPUTE":
            # These instructions should not have operands
            if operands:
                raise Exception(f"{op} No operands expected at line {lineno + 1}.\n Original: {original_line}")
            out.append(OPC['COMPUTE'])
            continue
        if op == "SET_ID":
            if operands:
                raise Exception(f"{op} No operands expected at line {lineno + 1}.\n Original: {original_line}")
            out.append(OPC['SET_ID'])
            continue

        # ------------------------------
        # WAIT
        # FMT-WAIT
        # Syntax: WAIT DMA
        #         WAIT GLB
        #         WAIT PE_ARRAY
        # ------------------------------
        if op == "WAIT":
            check_operands(op, operands, 1, lineno, original_line)
            tm, typ = parse_operand(operands[0])
            instr = enc32(
                opcode=(0, OPC['WAIT']),
                type=(6, typ & 0x3),
            )
            out.append(instr)
            continue

        # ------------------------------
        # JUMP
        # FMT-JUMP
        # Syntax: JUMP label
        # ------------------------------
        if op == "JUMP":
            check_operands(op, operands, 1, lineno, original_line)
            label = operands[0]
            if label not in labels:
                raise Exception(f"Unknown label {label}")
            target_pc = labels[label]
            imm = target_pc & 0x3FFFFFF
            instr = enc32(
                opcode=(0, OPC['JUMP']),
                imm=(6, imm),
            )
            out.append(instr)
            continue

        # ------------------------------
        # LOOP
        # FMT-LOOP
        # Syntax: LOOP csr, reg, label, offset
        # ------------------------------
        if op == "LOOP":
            check_operands(op, operands, 4, lineno, original_line)
            csr_t, csr_id = parse_operand(operands[0])
            reg_t, loopreg = parse_operand(operands[1])
            label = operands[2]
            off_t, offset = parse_operand(operands[3])

            if label not in labels:
                raise Exception(f"Unknown label {label}")

            target = labels[label] & 0x3F

            instr = enc32(
                opcode=(0, OPC['LOOP']),
                loop=(6, loopreg & 0xF),
                csr=(10, csr_id & 0xF),
                target=(14, target),
                offset=(20, offset & 0xFFF),
            )
            out.append(instr)
            continue

        # ------------------------------
        # LOADI / ADDI
        # FMT-ALU-I
        # Syntax: LOADI rd imm   
        #         ADDI  rd rs imm  
        #         MULI  rd rs imm  
        # ------------------------------
        if op == "LOADI":
            check_operands(op, operands, 2, lineno, original_line)
            trd, rd = parse_operand(operands[0])
            rs = 0
            timm, imm = parse_operand(operands[1])
            instr = enc32(
                opcode=(0, OPC['ADDI']),
                rd=(6, rd & 0xF),
                rs=(10, rs & 0xF),
                imm=(14, imm & 0x3FFFF),
            )
            out.append(instr)
            continue

        if op == "ADDI" or op == "MULI":
            check_operands(op, operands, 3, lineno, original_line)
            trd, rd = parse_operand(operands[0])
            trs, rs = parse_operand(operands[1])
            timm, imm = parse_operand(operands[2])
            instr = enc32(
                opcode=(0, OPC[op]),
                rd=(6, rd & 0xF),
                rs=(10, rs & 0xF),
                imm=(14, imm & 0x3FFFF),
            )
            out.append(instr)
            continue

        # ------------------------------
        # ADD / MUL
        # FMT-ALU
        # Syntax: ADD rd rs1 rs2   
        #         MUL rd rs1 rs2  
        # ------------------------------
        if op == "ADD":
            check_operands(op, operands, 3, lineno, original_line)
            trd, rd = parse_operand(operands[0])
            trs1, rs1 = parse_operand(operands[1])
            trs2, rs2 = parse_operand(operands[2])
            instr = enc32(
                opcode=(0, OPC["ADD"]),
                rd=(6, rd & 0xF),
                rs1=(10, rs1 & 0xF),
                rs2=(14, rs2 & 0xF),
            )
            out.append(instr)
            continue
        if op == "MUL":
            check_operands(op, operands, 3, lineno, original_line)
            trd, rd = parse_operand(operands[0])
            trs1, rs1 = parse_operand(operands[1])
            trs2, rs2 = parse_operand(operands[2])
            instr = enc32(
                opcode=(0, OPC["MUL"]),
                rd=(6, rd & 0xF),
                rs1=(10, rs1 & 0xF),
                rs2=(14, rs2 & 0xF),
            )
            out.append(instr)
            continue
        raise Exception(f"Unknown instruction {op} at line {lineno + 1}")

    return out

# ---------------------------------------------
# Output: .hex, .bin (string)
# ---------------------------------------------

def write_bin(filename, binary):
    with open(filename, "wb") as f:
        for code in binary:
            f.write(code.to_bytes(4, 'little'))


def write_hex(filename, binary):
    with open(filename, "w") as f:
        for code in binary:
            f.write(f"{code:08X}\n")


# ---------------------------------------------
# Main
# ---------------------------------------------
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python assembler.py program.txt")
        sys.exit(0)

    asm_file = sys.argv[1]
    base, _ = os.path.splitext(asm_file)
    out_bin = base + ".bin"
    out_hex = base + ".hex"

    with open(asm_file) as f:
        lines = f.readlines()

    program, labels = assemble(lines)
    binary = encode(program, labels)

    write_bin(out_bin, binary)
    write_hex(out_hex, binary)
    print(f"[OK] {out_bin} / {out_hex} 已輸出")