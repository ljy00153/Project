wvResizeWindow -win $_nWave1 8 31 1920 1009
wvSetPosition -win $_nWave1 {("G1" 0)}
wvResizeWindow -win $_nWave1 8 31 1920 1009
wvOpenFile -win $_nWave1 {/home/users/yves6512/Project/hardware/wave.fsdb}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/controller_tb"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/ctrl"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/ctrl"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/im"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/DMA_Loop"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/alu"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/DMA_Loop"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/ctrl"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/ctrl"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_adder"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/rf"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/u_id_sender"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_adder"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvSetPosition -win $_nWave1 {("G1" 5)}
wvSetPosition -win $_nWave1 {("G1" 5)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/im/r_data\[31:0\]} \
{/controller_tb/dut/im/addr\[15:0\]} \
{/controller_tb/dut/pc_counter/clk} \
{/controller_tb/dut/pc_counter/rst} \
{/controller_tb/dut/pc_counter/pc\[15:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSetPosition -win $_nWave1 {("G1" 5)}
wvSetPosition -win $_nWave1 {("G1" 5)}
wvSetPosition -win $_nWave1 {("G1" 5)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/im/r_data\[31:0\]} \
{/controller_tb/dut/im/addr\[15:0\]} \
{/controller_tb/dut/pc_counter/clk} \
{/controller_tb/dut/pc_counter/rst} \
{/controller_tb/dut/pc_counter/pc\[15:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSetPosition -win $_nWave1 {("G1" 5)}
wvGetSignalClose -win $_nWave1
wvCut -win $_nWave1
wvSetPosition -win $_nWave1 {("G2" 0)}
wvSetPosition -win $_nWave1 {("G1" 4)}
wvZoom -win $_nWave1 0.000000 669225.869001
wvZoom -win $_nWave1 264507.653879 476113.776982
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSelectSignal -win $_nWave1 {( "G1" 1 )} 
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSelectSignal -win $_nWave1 {( "G1" 1 )} 
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/controller_tb"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/im"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/ctrl"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvSetPosition -win $_nWave1 {("G1" 5)}
wvSetPosition -win $_nWave1 {("G1" 5)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/im/r_data\[31:0\]} \
{/controller_tb/dut/im/addr\[15:0\]} \
{/controller_tb/dut/pc_counter/clk} \
{/controller_tb/dut/pc_counter/rst} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSetPosition -win $_nWave1 {("G1" 5)}
wvSetPosition -win $_nWave1 {("G1" 5)}
wvSetPosition -win $_nWave1 {("G1" 5)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/im/r_data\[31:0\]} \
{/controller_tb/dut/im/addr\[15:0\]} \
{/controller_tb/dut/pc_counter/clk} \
{/controller_tb/dut/pc_counter/rst} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSetPosition -win $_nWave1 {("G1" 5)}
wvGetSignalClose -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSetRadix -win $_nWave1 -format Oct
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSetRadix -win $_nWave1 -format Bin
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 424708.176383 -snap {("G1" 5)}
wvSelectSignal -win $_nWave1 {( "G1" 1 )} 
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSelectSignal -win $_nWave1 {( "G1" 3 )} 
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSetCursor -win $_nWave1 414916.633411 -snap {("G1" 5)}
wvSetCursor -win $_nWave1 404989.096788 -snap {("G1" 5)}
wvSetCursor -win $_nWave1 414916.633411 -snap {("G1" 5)}
wvSetCursor -win $_nWave1 405397.077745 -snap {("G1" 2)}
wvSetCursor -win $_nWave1 425252.150992 -snap {("G1" 5)}
wvSetCursor -win $_nWave1 416548.557240 -snap {("G1" 2)}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/controller_tb"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/im"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/im"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_adder"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/rf"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_adder"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/ctrl"
wvSetPosition -win $_nWave1 {("G1" 6)}
wvSetPosition -win $_nWave1 {("G1" 6)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/im/r_data\[31:0\]} \
{/controller_tb/dut/im/addr\[15:0\]} \
{/controller_tb/dut/pc_counter/clk} \
{/controller_tb/dut/pc_counter/rst} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
{/controller_tb/dut/ctrl/pc_hold} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSetPosition -win $_nWave1 {("G1" 6)}
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/im"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_adder"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/rf"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/u_id_sender"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/DMA_Loop"
wvSetPosition -win $_nWave1 {("G1" 29)}
wvSetPosition -win $_nWave1 {("G1" 29)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/im/r_data\[31:0\]} \
{/controller_tb/dut/im/addr\[15:0\]} \
{/controller_tb/dut/pc_counter/clk} \
{/controller_tb/dut/pc_counter/rst} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
{/controller_tb/dut/ctrl/pc_hold} \
{/controller_tb/dut/DMA_Loop/cs\[1:0\]} \
{/controller_tb/dut/DMA_Loop/dram_addr\[31:0\]} \
{/controller_tb/dut/DMA_Loop/dram_stride\[31:0\]} \
{/controller_tb/dut/DMA_Loop/glb_addr\[15:0\]} \
{/controller_tb/dut/DMA_Loop/glb_stride\[15:0\]} \
{/controller_tb/dut/DMA_Loop/in_features\[31:0\]} \
{/controller_tb/dut/DMA_Loop/loop_cnt\[31:0\]} \
{/controller_tb/dut/DMA_Loop/loop_finish} \
{/controller_tb/dut/DMA_Loop/loop_max\[31:0\]} \
{/controller_tb/dut/DMA_Loop/ns\[1:0\]} \
{/controller_tb/dut/DMA_Loop/out_features\[31:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_done} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_en} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_done} \
{/controller_tb/dut/DMA_Loop/DMA_en} \
{/controller_tb/dut/DMA_Loop/DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_mode\[1:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 \
           22 23 24 25 26 27 28 29 )} 
wvSetPosition -win $_nWave1 {("G1" 29)}
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 29 )} 
wvSelectSignal -win $_nWave1 {( "G1" 22 )} 
wvSelectSignal -win $_nWave1 {( "G1" 23 )} 
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 26 )} 
wvSelectSignal -win $_nWave1 {( "G1" 22 )} 
