wvResizeWindow -win $_nWave1 8 31 892 139
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvSetPosition -win $_nWave1 {("G1" 0)}
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvOpenFile -win $_nWave1 {/home/users/yves6512/Project/hardware/novas.fsdb}
wvOpenFile -win $_nWave1 {/home/users/yves6512/Project/hardware/wave.fsdb}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/controller_tb"
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/im"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/ctrl"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvSetPosition -win $_nWave1 {("G1" 2)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/dec/instr\[31:0\]} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSetPosition -win $_nWave1 {("G1" 2)}
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/im"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/ctrl"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_adder"
wvSetPosition -win $_nWave1 {("G1" 3)}
wvSetPosition -win $_nWave1 {("G1" 3)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/dec/instr\[31:0\]} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
{/controller_tb/dut/pc_adder/pc\[15:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 3 )} 
wvSetPosition -win $_nWave1 {("G1" 3)}
wvZoom -win $_nWave1 0.000000 1009224.325193
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/glb_addr_generator"
wvSetPosition -win $_nWave1 {("G1" 5)}
wvSetPosition -win $_nWave1 {("G1" 5)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/dec/instr\[31:0\]} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
{/controller_tb/dut/pc_adder/pc\[15:0\]} \
{/controller_tb/dut/glb_addr_generator/clk} \
{/controller_tb/dut/glb_addr_generator/rst} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 4 5 )} 
wvSetPosition -win $_nWave1 {("G1" 5)}
wvSetPosition -win $_nWave1 {("G1" 3)}
wvSelectSignal -win $_nWave1 {( "G1" 3 )} 
wvSetPosition -win $_nWave1 {("G1" 1)}
wvSetPosition -win $_nWave1 {("G1" 0)}
wvMoveSelected -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 0)}
wvSetPosition -win $_nWave1 {("G1" 1)}
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSetPosition -win $_nWave1 {("G1" 5)}
wvSetPosition -win $_nWave1 {("G1" 3)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvSetPosition -win $_nWave1 {("G1" 1)}
wvMoveSelected -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 1)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_adder"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/rf"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/u_id_sender"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_adder"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/im"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/im"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/ctrl"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/DMA_Loop"
wvSetPosition -win $_nWave1 {("G1" 25)}
wvSetPosition -win $_nWave1 {("G1" 25)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/pc_adder/pc\[15:0\]} \
{/controller_tb/dut/glb_addr_generator/rst} \
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
{/controller_tb/dut/DMA_Loop/cs\[1:0\]} \
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
{/controller_tb/dut/dec/instr\[31:0\]} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
{/controller_tb/dut/glb_addr_generator/clk} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 \
           19 20 21 22 23 24 25 )} 
wvSetPosition -win $_nWave1 {("G1" 25)}
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvSelectSignal -win $_nWave1 {( "G1" 23 )} 
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvSelectSignal -win $_nWave1 {( "G1" 26 )} 
wvSelectSignal -win $_nWave1 {( "G1" 28 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 28 )} 
wvSelectSignal -win $_nWave1 {( "G1" 26 27 28 )} 
wvSetPosition -win $_nWave1 {("G1" 26)}
wvSetPosition -win $_nWave1 {("G1" 25)}
wvSetPosition -win $_nWave1 {("G1" 24)}
wvSetPosition -win $_nWave1 {("G1" 21)}
wvSetPosition -win $_nWave1 {("G1" 3)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvMoveSelected -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 2)}
wvSetPosition -win $_nWave1 {("G1" 5)}
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvSelectSignal -win $_nWave1 {( "G1" 4 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSetPosition -win $_nWave1 {("G1" 4)}
wvSetPosition -win $_nWave1 {("G1" 3)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvSetPosition -win $_nWave1 {("G1" 0)}
wvMoveSelected -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 0)}
wvSetPosition -win $_nWave1 {("G1" 1)}
wvSelectSignal -win $_nWave1 {( "G1" 3 )} 
wvSetPosition -win $_nWave1 {("G1" 3)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvSetPosition -win $_nWave1 {("G1" 1)}
wvMoveSelected -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 1)}
wvSetPosition -win $_nWave1 {("G1" 2)}
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 405700.395506 -snap {("G1" 14)}
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvCut -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 2)}
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 26 )} 
wvSelectSignal -win $_nWave1 {( "G1" 19 )} 
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvZoomIn -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 4 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSetRadix -win $_nWave1 -format Bin
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 19 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSetRadix -win $_nWave1 -format Bin
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSelectSignal -win $_nWave1 {( "G1" 25 )} 
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvSelectSignal -win $_nWave1 {( "G1" 25 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 26 )} 
wvSelectSignal -win $_nWave1 {( "G1" 26 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvGetSignalOpen -win $_nWave1
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvSetActiveFile -win $_nWave1 -applyAnnotation off \
           {/home/users/yves6512/Project/hardware/novas.fsdb}
wvGetSignalSetScope -win $_nWave1 "/controller_tb"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut"
wvSetActiveFile -win $_nWave1 -applyAnnotation off \
           {/home/users/yves6512/Project/hardware/wave.fsdb}
wvGetSignalSetScope -win $_nWave1 "/controller_tb"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/DMA_Loop"
wvSelectSignal -win $_nWave1 {( "G1" 26 )} 
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSelectSignal -win $_nWave1 {( "G1" 17 )} 
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSelectSignal -win $_nWave1 {( "G1" 17 )} 
wvOpenFile -win $_nWave1 \
           {/home/users/yves6512/Project/hardware/testbench/controller/wave.fsdb}
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 64394.182896 790292.244632
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 \
           18 19 20 21 22 23 24 25 26 27 )} 
wvCut -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 0)}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/controller_tb"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/DMA_Loop"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/alu"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/im"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/rf"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/u_id_sender"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_adder"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/pc_adder"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/dec"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/DMA_Loop"
wvSetPosition -win $_nWave1 {("G1" 30)}
wvSetPosition -win $_nWave1 {("G1" 30)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/dec/instr\[31:0\]} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
{/controller_tb/dut/glb_addr_generator/clk} \
{/controller_tb/dut/glb_addr_generator/rst} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_done} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_en} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_len_reg\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_done} \
{/controller_tb/dut/DMA_Loop/DMA_en} \
{/controller_tb/dut/DMA_Loop/DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_mode_reg\[1:0\]} \
{/controller_tb/dut/DMA_Loop/dram_addr\[31:0\]} \
{/controller_tb/dut/DMA_Loop/dram_stride\[31:0\]} \
{/controller_tb/dut/DMA_Loop/glb_addr\[15:0\]} \
{/controller_tb/dut/DMA_Loop/glb_stride\[15:0\]} \
{/controller_tb/dut/DMA_Loop/in_features\[31:0\]} \
{/controller_tb/dut/DMA_Loop/loop_cnt\[31:0\]} \
{/controller_tb/dut/DMA_Loop/loop_finish} \
{/controller_tb/dut/DMA_Loop/loop_max\[31:0\]} \
{/controller_tb/dut/DMA_Loop/next_dram_addr\[31:0\]} \
{/controller_tb/dut/DMA_Loop/next_glb_addr\[15:0\]} \
{/controller_tb/dut/DMA_Loop/out_features\[31:0\]} \
{/controller_tb/dut/DMA_Loop/count_length\[15:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 \
           21 22 23 24 25 26 27 28 29 30 )} 
wvSetPosition -win $_nWave1 {("G1" 30)}
wvSetPosition -win $_nWave1 {("G1" 30)}
wvSetPosition -win $_nWave1 {("G1" 30)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/dec/instr\[31:0\]} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
{/controller_tb/dut/glb_addr_generator/clk} \
{/controller_tb/dut/glb_addr_generator/rst} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_done} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_en} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_len_reg\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_done} \
{/controller_tb/dut/DMA_Loop/DMA_en} \
{/controller_tb/dut/DMA_Loop/DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_mode_reg\[1:0\]} \
{/controller_tb/dut/DMA_Loop/dram_addr\[31:0\]} \
{/controller_tb/dut/DMA_Loop/dram_stride\[31:0\]} \
{/controller_tb/dut/DMA_Loop/glb_addr\[15:0\]} \
{/controller_tb/dut/DMA_Loop/glb_stride\[15:0\]} \
{/controller_tb/dut/DMA_Loop/in_features\[31:0\]} \
{/controller_tb/dut/DMA_Loop/loop_cnt\[31:0\]} \
{/controller_tb/dut/DMA_Loop/loop_finish} \
{/controller_tb/dut/DMA_Loop/loop_max\[31:0\]} \
{/controller_tb/dut/DMA_Loop/next_dram_addr\[31:0\]} \
{/controller_tb/dut/DMA_Loop/next_glb_addr\[15:0\]} \
{/controller_tb/dut/DMA_Loop/out_features\[31:0\]} \
{/controller_tb/dut/DMA_Loop/count_length\[15:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 \
           21 22 23 24 25 26 27 28 29 30 )} 
wvSetPosition -win $_nWave1 {("G1" 30)}
wvGetSignalClose -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 11196.371132 466515.463840
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 275064.233384 469364.925902
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSetRadix -win $_nWave1 -format Bin
wvSetCursor -win $_nWave1 425934.475480 -snap {("G1" 8)}
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 28 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 28 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 28 )} 
wvSelectSignal -win $_nWave1 {( "G1" 12 )} 
wvSelectSignal -win $_nWave1 {( "G1" 11 )} 
wvSelectSignal -win $_nWave1 {( "G1" 10 )} 
wvSelectSignal -win $_nWave1 {( "G1" 9 )} 
wvSelectSignal -win $_nWave1 {( "G1" 7 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSetCursor -win $_nWave1 435674.484488 -snap {("G1" 7)}
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 30 )} 
wvSelectSignal -win $_nWave1 {( "G1" 17 )} 
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvUnknownSaveResult -win $_nWave1 -clear
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 434779.017487 -snap {("G1" 9)}
wvSelectSignal -win $_nWave1 {( "G1" 8 )} 
wvSelectSignal -win $_nWave1 {( "G1" 9 )} 
wvSetRadix -win $_nWave1 -1Com
wvSelectSignal -win $_nWave1 {( "G1" 9 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSelectSignal -win $_nWave1 {( "G1" 10 )} 
wvSelectSignal -win $_nWave1 {( "G1" 9 )} 
wvSelectSignal -win $_nWave1 {( "G1" 10 )} 
wvSelectSignal -win $_nWave1 {( "G1" 11 )} 
wvSelectSignal -win $_nWave1 {( "G1" 17 )} 
wvSelectSignal -win $_nWave1 {( "G1" 19 )} 
wvSelectSignal -win $_nWave1 {( "G1" 18 )} 
wvSetPosition -win $_nWave1 {("G1" 18)}
wvSetPosition -win $_nWave1 {("G1" 17)}
wvSetPosition -win $_nWave1 {("G1" 16)}
wvSetPosition -win $_nWave1 {("G1" 14)}
wvSetPosition -win $_nWave1 {("G1" 13)}
wvSetPosition -win $_nWave1 {("G1" 14)}
wvSetPosition -win $_nWave1 {("G1" 13)}
wvSetPosition -win $_nWave1 {("G1" 12)}
wvSetPosition -win $_nWave1 {("G1" 13)}
wvSetPosition -win $_nWave1 {("G1" 12)}
wvSetPosition -win $_nWave1 {("G1" 11)}
wvMoveSelected -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 11)}
wvSetPosition -win $_nWave1 {("G1" 12)}
wvSelectSignal -win $_nWave1 {( "G1" 11 )} 
wvSelectSignal -win $_nWave1 {( "G1" 10 )} 
wvSelectSignal -win $_nWave1 {( "G1" 9 )} 
wvSelectSignal -win $_nWave1 {( "G1" 10 )} 
wvSelectSignal -win $_nWave1 {( "G1" 11 )} 
wvSelectSignal -win $_nWave1 {( "G1" 12 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSelectSignal -win $_nWave1 {( "G1" 8 )} 
wvSelectSignal -win $_nWave1 {( "G1" 7 )} 
wvSelectSignal -win $_nWave1 {( "G1" 10 )} 
wvSelectSignal -win $_nWave1 {( "G1" 9 )} 
wvSelectSignal -win $_nWave1 {( "G1" 11 )} 
wvSelectSignal -win $_nWave1 {( "G1" 12 )} 
wvSelectSignal -win $_nWave1 {( "G1" 10 )} 
wvSelectSignal -win $_nWave1 {( "G1" 12 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSelectSignal -win $_nWave1 {( "G1" 18 )} 
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/alu"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut/DMA_Loop"
wvSetPosition -win $_nWave1 {("G1" 13)}
wvSetPosition -win $_nWave1 {("G1" 13)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/dec/instr\[31:0\]} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
{/controller_tb/dut/glb_addr_generator/clk} \
{/controller_tb/dut/glb_addr_generator/rst} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_done} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_en} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_len_reg\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_mode_reg\[1:0\]} \
{/controller_tb/dut/DMA_Loop/cs\[1:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_done} \
{/controller_tb/dut/DMA_Loop/DMA_en} \
{/controller_tb/dut/DMA_Loop/DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/dram_addr\[31:0\]} \
{/controller_tb/dut/DMA_Loop/dram_stride\[31:0\]} \
{/controller_tb/dut/DMA_Loop/glb_addr\[15:0\]} \
{/controller_tb/dut/DMA_Loop/glb_stride\[15:0\]} \
{/controller_tb/dut/DMA_Loop/in_features\[31:0\]} \
{/controller_tb/dut/DMA_Loop/loop_cnt\[31:0\]} \
{/controller_tb/dut/DMA_Loop/loop_finish} \
{/controller_tb/dut/DMA_Loop/loop_max\[31:0\]} \
{/controller_tb/dut/DMA_Loop/out_features\[31:0\]} \
{/controller_tb/dut/DMA_Loop/count_length\[15:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSetPosition -win $_nWave1 {("G1" 13)}
wvSelectSignal -win $_nWave1 {( "G1" 19 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSetCursor -win $_nWave1 425538.496121 -snap {("G1" 8)}
wvSelectSignal -win $_nWave1 {( "G1" 19 )} 
wvSelectSignal -win $_nWave1 {( "G1" 18 )} 
wvSelectSignal -win $_nWave1 {( "G1" 18 )} 
wvSetRadix -win $_nWave1 -format Bin
wvSelectSignal -win $_nWave1 {( "G1" 18 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSetCursor -win $_nWave1 435278.505129 -snap {("G1" 20)}
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 23 )} 
wvSelectSignal -win $_nWave1 {( "G1" 22 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 21 22 23 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 21 22 23 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSelectSignal -win $_nWave1 {( "G1" 25 )} 
wvSelectSignal -win $_nWave1 {( "G1" 26 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 29 )} 
wvSelectSignal -win $_nWave1 {( "G1" 28 )} 
wvSelectSignal -win $_nWave1 {( "G1" 29 )} 
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 29 )} 
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSelectSignal -win $_nWave1 {( "G1" 17 )} 
wvSelectSignal -win $_nWave1 {( "G1" 9 )} 
wvSelectSignal -win $_nWave1 {( "G1" 10 )} 
wvSelectSignal -win $_nWave1 {( "G1" 10 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSelectSignal -win $_nWave1 {( "G1" 11 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 6 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 23 )} 
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvSelectSignal -win $_nWave1 {( "G1" 22 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 22 )} 
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvSelectSignal -win $_nWave1 {( "G1" 22 )} 
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvSelectSignal -win $_nWave1 {( "G1" 22 )} 
wvSelectSignal -win $_nWave1 {( "G1" 23 )} 
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvCut -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 13)}
wvSelectSignal -win $_nWave1 {( "G1" 25 )} 
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 )} 
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 17 )} 
wvSelectSignal -win $_nWave1 {( "G1" 18 )} 
wvSelectSignal -win $_nWave1 {( "G1" 19 )} 
wvSelectSignal -win $_nWave1 {( "G1" 18 )} 
wvSelectSignal -win $_nWave1 {( "G1" 19 )} 
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSelectSignal -win $_nWave1 {( "G1" 21 )} 
wvSelectSignal -win $_nWave1 {( "G1" 22 )} 
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvSelectSignal -win $_nWave1 {( "G1" 23 )} 
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvSelectSignal -win $_nWave1 {( "G1" 25 )} 
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/controller_tb"
wvGetSignalSetScope -win $_nWave1 "/controller_tb/dut"
wvSetPosition -win $_nWave1 {("G1" 20)}
wvSetPosition -win $_nWave1 {("G1" 20)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/dec/instr\[31:0\]} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
{/controller_tb/dut/glb_addr_generator/clk} \
{/controller_tb/dut/glb_addr_generator/rst} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_done} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_en} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_len_reg\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_mode_reg\[1:0\]} \
{/controller_tb/dut/DMA_Loop/cs\[1:0\]} \
{/controller_tb/dut/DMA_BYTE_BIAS\[1:0\]} \
{/controller_tb/dut/DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_done} \
{/controller_tb/dut/DMA_en} \
{/controller_tb/dut/DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_done} \
{/controller_tb/dut/DMA_Loop/DMA_en} \
{/controller_tb/dut/DMA_Loop/DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/dram_addr\[31:0\]} \
{/controller_tb/dut/DMA_Loop/dram_stride\[31:0\]} \
{/controller_tb/dut/DMA_Loop/glb_addr\[15:0\]} \
{/controller_tb/dut/DMA_Loop/glb_stride\[15:0\]} \
{/controller_tb/dut/DMA_Loop/loop_cnt\[31:0\]} \
{/controller_tb/dut/DMA_Loop/loop_finish} \
{/controller_tb/dut/DMA_Loop/loop_max\[31:0\]} \
{/controller_tb/dut/DMA_Loop/out_features\[31:0\]} \
{/controller_tb/dut/DMA_Loop/count_length\[15:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 14 15 16 17 18 19 20 )} 
wvSetPosition -win $_nWave1 {("G1" 20)}
wvSetPosition -win $_nWave1 {("G1" 19)}
wvSetPosition -win $_nWave1 {("G1" 20)}
wvSetPosition -win $_nWave1 {("G1" 21)}
wvSetPosition -win $_nWave1 {("G1" 23)}
wvSetPosition -win $_nWave1 {("G1" 29)}
wvSetPosition -win $_nWave1 {("G1" 30)}
wvSetPosition -win $_nWave1 {("G1" 32)}
wvSetPosition -win $_nWave1 {("G1" 35)}
wvSetPosition -win $_nWave1 {("G2" 0)}
wvMoveSelected -win $_nWave1
wvSetPosition -win $_nWave1 {("G2" 7)}
wvSetPosition -win $_nWave1 {("G2" 7)}
wvSelectGroup -win $_nWave1 {G2}
wvRenameGroup -win $_nWave1 {G2} {TOP}
wvSetCursor -win $_nWave1 955020.370423 -snap {("G3" 0)}
wvSetCursor -win $_nWave1 2053893.181578 -snap {("TOP" 2)}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/controller_tb"
wvSetPosition -win $_nWave1 {("TOP" 8)}
wvSetPosition -win $_nWave1 {("TOP" 8)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/controller_tb/dut/dec/instr\[31:0\]} \
{/controller_tb/dut/dec/opcode\[5:0\]} \
{/controller_tb/dut/glb_addr_generator/clk} \
{/controller_tb/dut/glb_addr_generator/rst} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_done} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_en} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_len_reg\[15:0\]} \
{/controller_tb/dut/DMA_Loop/CTRL_DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_mode_reg\[1:0\]} \
{/controller_tb/dut/DMA_Loop/cs\[1:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_done} \
{/controller_tb/dut/DMA_Loop/DMA_en} \
{/controller_tb/dut/DMA_Loop/DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_Loop/DMA_mode\[1:0\]} \
{/controller_tb/dut/DMA_Loop/dram_addr\[31:0\]} \
{/controller_tb/dut/DMA_Loop/dram_stride\[31:0\]} \
{/controller_tb/dut/DMA_Loop/glb_addr\[15:0\]} \
{/controller_tb/dut/DMA_Loop/glb_stride\[15:0\]} \
{/controller_tb/dut/DMA_Loop/loop_cnt\[31:0\]} \
{/controller_tb/dut/DMA_Loop/loop_finish} \
{/controller_tb/dut/DMA_Loop/loop_max\[31:0\]} \
{/controller_tb/dut/DMA_Loop/out_features\[31:0\]} \
{/controller_tb/dut/DMA_Loop/count_length\[15:0\]} \
}
wvAddSignal -win $_nWave1 -group {"TOP" \
{/controller_tb/dut/DMA_BYTE_BIAS\[1:0\]} \
{/controller_tb/dut/DMA_DRAM_ADDR\[31:0\]} \
{/controller_tb/dut/DMA_GLB_ADDR\[15:0\]} \
{/controller_tb/dut/DMA_done} \
{/controller_tb/dut/DMA_en} \
{/controller_tb/dut/DMA_len\[15:0\]} \
{/controller_tb/dut/DMA_mode\[1:0\]} \
{/controller_tb/dma_cnt\[31:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G3" \
}
wvSelectSignal -win $_nWave1 {( "TOP" 8 )} 
wvSetPosition -win $_nWave1 {("TOP" 8)}
wvZoom -win $_nWave1 323667.991650 563422.059538
wvSetCursor -win $_nWave1 453868.626203 -snap {("TOP" 8)}
wvSetCursor -win $_nWave1 450016.536424 -snap {("TOP" 8)}
wvSetCursor -win $_nWave1 447088.948191 -snap {("TOP" 8)}
wvSelectSignal -win $_nWave1 {( "TOP" 2 )} 
wvSelectSignal -win $_nWave1 {( "TOP" 1 )} 
wvSelectSignal -win $_nWave1 {( "TOP" 2 )} 
wvSelectSignal -win $_nWave1 {( "TOP" 4 )} 
wvSelectSignal -win $_nWave1 {( "TOP" 4 )} 
wvSelectSignal -win $_nWave1 {( "TOP" 6 )} 
wvSelectSignal -win $_nWave1 {( "TOP" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 17 )} 
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 1883583.762829 -snap {("TOP" 4)}
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvSelectSignal -win $_nWave1 {( "G1" 14 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 14 15 )} 
wvSetRadix -win $_nWave1 -format UDec
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 444993.411350 -snap {("TOP" 7)}
wvSelectSignal -win $_nWave1 {( "G1" 15 )} 
wvSelectSignal -win $_nWave1 {( "G1" 17 )} 
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSelectSignal -win $_nWave1 {( "TOP" 6 )} 
wvSelectSignal -win $_nWave1 {( "TOP" 5 )} 
wvSelectSignal -win $_nWave1 {( "TOP" 6 )} 
wvSetCursor -win $_nWave1 435132.061514 -snap {("G1" 17)}
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSearchNext -win $_nWave1
wvSearchNext -win $_nWave1
wvSearchNext -win $_nWave1
wvSearchNext -win $_nWave1
wvSearchNext -win $_nWave1
wvSearchNext -win $_nWave1
wvSearchNext -win $_nWave1
wvSetCursor -win $_nWave1 6246032.385128 -snap {("G1" 14)}
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvSearchPrev -win $_nWave1
wvSearchPrev -win $_nWave1
wvSearchPrev -win $_nWave1
wvSearchNext -win $_nWave1
wvSearchNext -win $_nWave1
wvSearchPrev -win $_nWave1
wvSearchPrev -win $_nWave1
wvSearchPrev -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvSelectSignal -win $_nWave1 {( "G1" 23 )} 
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSetCursor -win $_nWave1 163472812.844601 -snap {("G1" 24)}
wvSetCursor -win $_nWave1 161816106.072151 -snap {("G1" 24)}
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvZoom -win $_nWave1 183520110.697708 187543541.430801
wvSetCursor -win $_nWave1 186033462.029683 -snap {("G1" 25)}
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvZoom -win $_nWave1 186028290.524812 186063198.182200
wvSetCursor -win $_nWave1 186044936.721318 -snap {("G1" 13)}
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 25 )} 
wvSelectSignal -win $_nWave1 {( "G1" 28 )} 
wvSelectSignal -win $_nWave1 {( "G1" 28 )} 
wvSetRadix -win $_nWave1 -format UDec
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 1941188.803671 -snap {("G1" 20)}
wvSetCursor -win $_nWave1 3319547.717520 -snap {("G1" 20)}
wvSetCursor -win $_nWave1 4766824.577061 -snap {("G1" 20)}
wvSetCursor -win $_nWave1 6053292.896654 -snap {("G1" 20)}
wvSetCursor -win $_nWave1 186093934.900479 -snap {("TOP" 7)}
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 186002044.306195 186162852.846144
wvSetCursor -win $_nWave1 186044830.125855 -snap {("TOP" 5)}
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvSelectSignal -win $_nWave1 {( "G1" 17 )} 
wvSetCursor -win $_nWave1 186085032.260842 -snap {("TOP" 7)}
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 339332.322461 -snap {("G1" 20)}
wvSetCursor -win $_nWave1 1821678.783740 -snap {("G1" 20)}
wvSetCursor -win $_nWave1 3304025.245019 -snap {("G1" 20)}
wvSetCursor -win $_nWave1 4679214.130784 -snap {("G1" 20)}
wvSetCursor -win $_nWave1 6197279.783901 -snap {("G1" 20)}
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 11 )} 
wvSelectSignal -win $_nWave1 {( "G1" 11 )} 
wvSelectSignal -win $_nWave1 {( "G1" 12 )} 
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvSelectSignal -win $_nWave1 {( "TOP" 5 )} 
wvSelectSignal -win $_nWave1 {( "TOP" 1 )} 
wvSetCursor -win $_nWave1 435885.762899 -snap {("TOP" 5)}
wvSetCursor -win $_nWave1 450396.684583 -snap {("TOP" 5)}
wvSetCursor -win $_nWave1 432537.088664 -snap {("TOP" 5)}
wvSetCursor -win $_nWave1 443141.223741 -snap {("TOP" 5)}
wvSetCursor -win $_nWave1 1896130.974228 -snap {("TOP" 5)}
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSetCursor -win $_nWave1 191454868.252039 -snap {("TOP" 7)}
wvSetCursor -win $_nWave1 232031870.180083 -snap {("TOP" 7)}
wvSetCursor -win $_nWave1 189168839.974403 -snap {("TOP" 7)}
wvSetCursor -win $_nWave1 233746391.388310 -snap {("TOP" 7)}
wvZoom -win $_nWave1 170880613.753312 200027474.293175
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSelectSignal -win $_nWave1 {( "TOP" 5 )} 
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 187315235.441255 -snap {("G1" 15)}
wvSelectSignal -win $_nWave1 {( "G1" 25 )} 
wvSetCursor -win $_nWave1 187325186.771372 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 187336308.846208 -snap {("G1" 8)}
wvSelectSignal -win $_nWave1 {( "G1" 7 )} 
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvZoomIn -win $_nWave1
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvSetCursor -win $_nWave1 187325918.486838 -snap {("TOP" 5)}
wvSetCursor -win $_nWave1 187315235.441271 -snap {("G1" 17)}
wvSelectSignal -win $_nWave1 {( "G1" 16 )} 
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
