LOADI r1, 0        # loopReg
CFG_SET 6, 6       # OF_SIZE = loop bound

loop_start:
ADDI r8,r8, 1
LOOP 6, r1, loop_start, 1
END