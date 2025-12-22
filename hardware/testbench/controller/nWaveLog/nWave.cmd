wvSetPosition -win $_nWave1 {("G1" 0)}
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvOpenFile -win $_nWave1 \
           {/home/users/yves6512/aoc2025-lab3/wave/PE_array_wave.vcd.fsdb}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/TOP"
wvGetSignalSetScope -win $_nWave1 "/TOP/PE_array"
wvGetSignalOpen -win $_nWave1
wvOpenFile -win $_nWave1 \
           {/home/users/yves6512/Project/hardware/testbench/controller/wave.fsdb}
wvGetSignalSetScope -win $_nWave1 "/controller_tb"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut"
wvSetCursor -win $_nWave1 12307104.447301
wvExit
