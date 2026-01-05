wvSetPosition -win $_nWave1 {("G1" 0)}
wvResizeWindow -win $_nWave1 8 31 892 249
wvOpenFile -win $_nWave1 {/home/users/yves6512/Project/hardware/build/top.fsdb}
wvResizeWindow -win $_nWave1 8 31 892 139
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test"
wvGetSignalSetScope -win $_nWave1 "/test/DUT"
wvGetSignalSetScope -win $_nWave1 "/test/u_dram"
wvGetSignalSetScope -win $_nWave1 "/test/DUT"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/GLB_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PPU"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/im"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/dec"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/rf"
wvAddSignal -win $_nWave1 "/test/DUT/asic_0/ctrl/rf/regfile\[0:15\]"
wvSetPosition -win $_nWave1 {("G1" 0)}
wvSetPosition -win $_nWave1 {("G1" 1)}
wvSetPosition -win $_nWave1 {("G1" 1)}
wvExpandBus -win $_nWave1
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
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/pc_counter"
wvSetPosition -win $_nWave1 {("G1" 19)}
wvSetPosition -win $_nWave1 {("G1" 19)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/test/DUT/asic_0/ctrl/rf/regfile\[0:15\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[0\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[1\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[2\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[3\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[4\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[5\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[6\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[7\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[8\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[9\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[10\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[11\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[12\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[13\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[14\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[15\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/pc_counter/pc\[15:0\]} \
{/test/DUT/asic_0/ctrl/pc_counter/clk} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 18 19 )} 
wvSetPosition -win $_nWave1 {("G1" 19)}
wvZoom -win $_nWave1 0.000000 4233136869.679110
wvZoom -win $_nWave1 0.000000 121976438.942947
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 19 )} 
wvSelectSignal -win $_nWave1 {( "G1" 18 )} 
wvSelectSignal -win $_nWave1 {( "G1" 18 )} 
wvSetRadix -win $_nWave1 -format UDec
wvZoom -win $_nWave1 56874410.299528 77004117.315653
wvZoom -win $_nWave1 70768785.672798 72218862.799042
wvZoom -win $_nWave1 71629145.775198 71758294.753043
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 69636809.235178 74746609.264959
wvZoom -win $_nWave1 71614472.507993 72183343.500175
wvZoomOut -win $_nWave1
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
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvScrollDown -win $_nWave1 0
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 98663566.404715 127176431.925344
wvSetCursor -win $_nWave1 109493600.459697 -snap {("G1" 8)}
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 109059465.473805 109965080.390472
wvZoom -win $_nWave1 109566538.658967 109644823.641940
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvZoomOut -win $_nWave1
wvScrollDown -win $_nWave1 0
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/DMA_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/ctrl"
wvSetPosition -win $_nWave1 {("G1" 20)}
wvSetPosition -win $_nWave1 {("G1" 20)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/test/DUT/asic_0/ctrl/rf/regfile\[0:15\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[0\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[1\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[2\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[3\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[4\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[5\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[6\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[7\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[8\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[9\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[10\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[11\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[12\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[13\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[14\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[15\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/pc_counter/pc\[15:0\]} \
{/test/DUT/asic_0/ctrl/pc_counter/clk} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[0:15\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 20 )} 
wvSetPosition -win $_nWave1 {("G1" 20)}
wvExpandBus -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G1" 21 22 23 24 25 26 27 28 29 30 31 32 33 34 \
           35 36 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSetCursor -win $_nWave1 108959304.552265 -snap {("G2" 0)}
wvSelectSignal -win $_nWave1 {( "G1" 25 )} 
wvSelectSignal -win $_nWave1 {( "G1" 26 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 28 )} 
wvSelectSignal -win $_nWave1 {( "G1" 29 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 25 )} 
wvSelectSignal -win $_nWave1 {( "G1" 24 )} 
wvSelectSignal -win $_nWave1 {( "G1" 23 )} 
wvSelectSignal -win $_nWave1 {( "G1" 26 )} 
wvSelectSignal -win $_nWave1 {( "G1" 28 )} 
wvSelectSignal -win $_nWave1 {( "G1" 28 )} 
wvSelectSignal -win $_nWave1 {( "G1" 27 )} 
wvSelectSignal -win $_nWave1 {( "G1" 28 )} 
wvSelectSignal -win $_nWave1 {( "G1" 30 )} 
wvSelectSignal -win $_nWave1 {( "G1" 31 )} 
wvSelectSignal -win $_nWave1 {( "G1" 32 )} 
wvGetSignalOpen -win $_nWave1
wvSetPosition -win $_nWave1 {("G2" 0)}
wvSetPosition -win $_nWave1 {("G1" 36)}
wvSetPosition -win $_nWave1 {("G2" 0)}
wvAddSignal -win $_nWave1 "/test/DUT/asic_0/ctrl/ctrl/opcode\[5:0\]" \
           "/test/DUT/asic_0/ctrl/ctrl/PE_config\[10:0\]"
wvSetPosition -win $_nWave1 {("G2" 0)}
wvSetPosition -win $_nWave1 {("G2" 2)}
wvSetPosition -win $_nWave1 {("G2" 2)}
wvSelectSignal -win $_nWave1 {( "G2" 2 )} 
wvSelectSignal -win $_nWave1 {( "G2" 1 )} 
wvSelectSignal -win $_nWave1 {( "G2" 1 2 )} 
wvSelectSignal -win $_nWave1 {( "G2" 1 2 )} 
wvSetRadix -win $_nWave1 -format Bin
wvSetCursor -win $_nWave1 106203180.986687 -snap {("G2" 2)}
wvDisplayGridCount -win $_nWave1 -off
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvScrollDown -win $_nWave1 0
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
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 50000000000.000000 51309757694.826454
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/DMA_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array/GON"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array/PE_ROW\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE"
wvSetPosition -win $_nWave1 {("G3" 0)}
wvAddSignal -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/cs\[3:0\]"
wvSetPosition -win $_nWave1 {("G3" 0)}
wvSetPosition -win $_nWave1 {("G3" 1)}
wvSetPosition -win $_nWave1 {("G3" 1)}
wvZoom -win $_nWave1 55752619.622606 87488726.177013
wvZoom -win $_nWave1 64710224.026627 66996387.563618
wvSetPosition -win $_nWave1 {("G2" 2)}
wvSetPosition -win $_nWave1 {("G4" 0)}
wvAddSignal -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/ifmap_ready"
wvSetPosition -win $_nWave1 {("G4" 0)}
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvSetPosition -win $_nWave1 {("G4" 1)}
wvSetPosition -win $_nWave1 {("G4" 1)}
wvScrollDown -win $_nWave1 1
wvSetPosition -win $_nWave1 {("G2" 2)}
wvSetPosition -win $_nWave1 {("G5" 0)}
wvAddSignal -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/ifmap_valid"
wvSetPosition -win $_nWave1 {("G5" 0)}
wvSetPosition -win $_nWave1 {("G5" 1)}
wvSetPosition -win $_nWave1 {("G5" 1)}
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array/GIN_FILTER"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/pc_adder"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/im"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/glb_addr_generator"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/rf"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/pc_counter"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/pc_adder"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender"
wvSetPosition -win $_nWave1 {("G4" 1)}
wvSetPosition -win $_nWave1 {("G5" 0)}
wvSetPosition -win $_nWave1 {("G5" 1)}
wvSetPosition -win $_nWave1 {("G6" 0)}
wvAddSignal -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender/cs\[2:0\]"
wvSetPosition -win $_nWave1 {("G6" 0)}
wvSetPosition -win $_nWave1 {("G6" 1)}
wvSetPosition -win $_nWave1 {("G6" 1)}
wvSetPosition -win $_nWave1 {("G7" 0)}
wvSetPosition -win $_nWave1 {("G5" 0)}
wvSetPosition -win $_nWave1 {("G5" 1)}
wvSetPosition -win $_nWave1 {("G7" 0)}
wvAddSignal -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender/en"
wvSetPosition -win $_nWave1 {("G7" 0)}
wvSetPosition -win $_nWave1 {("G7" 1)}
wvSetPosition -win $_nWave1 {("G7" 1)}
wvSetCursor -win $_nWave1 65503718.901934 -snap {("G7" 1)}
wvSetPosition -win $_nWave1 {("G5" 1)}
wvSetPosition -win $_nWave1 {("G7" 1)}
wvAddSignal -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender/set_XID" \
           "/test/DUT/asic_0/ctrl/u_id_sender/set_YID"
wvSetPosition -win $_nWave1 {("G7" 1)}
wvSetPosition -win $_nWave1 {("G7" 3)}
wvSetPosition -win $_nWave1 {("G7" 1)}
wvSetPosition -win $_nWave1 {("G7" 2)}
wvSetPosition -win $_nWave1 {("G7" 3)}
wvSetPosition -win $_nWave1 {("G8" 0)}
wvAddSignal -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender/tag_type\[1:0\]"
wvSetPosition -win $_nWave1 {("G8" 0)}
wvSetPosition -win $_nWave1 {("G8" 1)}
wvSetPosition -win $_nWave1 {("G8" 1)}
wvSetPosition -win $_nWave1 {("G9" 0)}
wvSetCursor -win $_nWave1 65458804.097671 -snap {("G9" 0)}
wvSetCursor -win $_nWave1 65596542.830745 -snap {("G4" 1)}
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvSetPosition -win $_nWave1 {("G8" 1)}
wvScrollUp -win $_nWave1 1
wvScrollDown -win $_nWave1 1
wvScrollDown -win $_nWave1 1
wvSetPosition -win $_nWave1 {("G9" 0)}
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvScrollDown -win $_nWave1 1
wvScrollDown -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvSetPosition -win $_nWave1 {("G8" 1)}
wvSetPosition -win $_nWave1 {("G9" 0)}
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvSetPosition -win $_nWave1 {("G8" 1)}
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvSetPosition -win $_nWave1 {("G8" 0)}
wvScrollUp -win $_nWave1 1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSetPosition -win $_nWave1 {("G8" 1)}
wvZoomIn -win $_nWave1
wvSetPosition -win $_nWave1 {("G9" 0)}
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvSelectSignal -win $_nWave1 {( "G7" 2 )} 
wvSelectSignal -win $_nWave1 {( "G7" 1 )} 
wvZoom -win $_nWave1 71147897.357325 72308355.781917
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
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvGetSignalOpen -win $_nWave1
wvAddSignal -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender/ifmap_tag_X\[3:0\]" \
           "/test/DUT/asic_0/ctrl/u_id_sender/ifmap_tag_Y\[2:0\]"
wvSetPosition -win $_nWave1 {("G9" 0)}
wvSetPosition -win $_nWave1 {("G9" 2)}
wvSetPosition -win $_nWave1 {("G9" 2)}
wvSetPosition -win $_nWave1 {("G10" 0)}
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvSetCursor -win $_nWave1 65426522.857481 -snap {("G9" 0)}
wvSetPosition -win $_nWave1 {("G9" 2)}
wvSetPosition -win $_nWave1 {("G9" 2)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/test/DUT/asic_0/ctrl/rf/regfile\[0:15\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[0\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[1\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[2\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[3\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[4\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[5\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[6\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[7\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[8\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[9\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[10\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[11\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[12\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[13\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[14\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[15\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/pc_counter/pc\[15:0\]} \
{/test/DUT/asic_0/ctrl/pc_counter/clk} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[0:15\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[0\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[1\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[2\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[3\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[4\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[5\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[6\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[7\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[8\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[9\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[10\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[11\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[12\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[13\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[14\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[15\]\[31:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
{/test/DUT/asic_0/ctrl/ctrl/opcode\[5:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/PE_config\[10:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G3" \
{/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/cs\[3:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G4" \
{/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/ifmap_ready} \
}
wvAddSignal -win $_nWave1 -group {"G5" \
{/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/ifmap_valid} \
}
wvAddSignal -win $_nWave1 -group {"G6" \
{/test/DUT/asic_0/ctrl/u_id_sender/cs\[2:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G7" \
{/test/DUT/asic_0/ctrl/u_id_sender/en} \
{/test/DUT/asic_0/ctrl/u_id_sender/set_XID} \
{/test/DUT/asic_0/ctrl/u_id_sender/set_YID} \
}
wvAddSignal -win $_nWave1 -group {"G8" \
{/test/DUT/asic_0/ctrl/u_id_sender/tag_type\[1:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G9" \
{/test/DUT/asic_0/ctrl/u_id_sender/ifmap_tag_X\[3:0\]} \
{/test/DUT/asic_0/ctrl/u_id_sender/ifmap_tag_Y\[2:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G10" \
}
wvSetPosition -win $_nWave1 {("G9" 2)}
wvGetSignalClose -win $_nWave1
wvSetPosition -win $_nWave1 {("G10" 0)}
wvSetCursor -win $_nWave1 65794678.867927 -snap {("G8" 1)}
wvSetCursor -win $_nWave1 71255659.689540 -snap {("G8" 1)}
wvSetCursor -win $_nWave1 71709718.769090 -snap {("G8" 1)}
wvSetCursor -win $_nWave1 65487882.192555 -snap {("G8" 1)}
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 0.000000 2945248.083566
wvSetCursor -win $_nWave1 969420.717526 -snap {("G7" 3)}
wvSetCursor -win $_nWave1 979153.857260 -snap {("G7" 3)}
wvScrollDown -win $_nWave1 0
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test"
wvGetSignalSetScope -win $_nWave1 "/test/DUT"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array/PE_ROW\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender"
wvSetPosition -win $_nWave1 {("G7" 3)}
wvSetPosition -win $_nWave1 {("G8" 1)}
wvSetPosition -win $_nWave1 {("G9" 0)}
wvSetPosition -win $_nWave1 {("G9" 1)}
wvSetPosition -win $_nWave1 {("G9" 0)}
wvAddSignal -win $_nWave1 \
           "/test/DUT/asic_0/ctrl/u_id_sender/weight_XID_scan_in\[3:0\]"
wvSetPosition -win $_nWave1 {("G9" 0)}
wvSetPosition -win $_nWave1 {("G9" 1)}
wvCut -win $_nWave1
wvSetPosition -win $_nWave1 {("G9" 1)}
wvSetPosition -win $_nWave1 {("G9" 0)}
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 45597813.026743 78488038.816524
wvZoom -win $_nWave1 65618895.612588 73509941.192027
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSetCursor -win $_nWave1 65861416.180628 -snap {("G8" 1)}
wvSetCursor -win $_nWave1 71306394.095323 -snap {("G7" 1)}
wvSetCursor -win $_nWave1 71661047.829230 -snap {("G7" 1)}
wvSetCursor -win $_nWave1 71953115.610095 -snap {("G7" 1)}
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test"
wvGetSignalSetScope -win $_nWave1 "/test/DUT"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array/PE_ROW\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender"
wvSetPosition -win $_nWave1 {("G5" 1)}
wvSetPosition -win $_nWave1 {("G9" 0)}
wvSetPosition -win $_nWave1 {("G9" 2)}
wvSetPosition -win $_nWave1 {("G10" 0)}
wvAddSignal -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender/ipsum_tag_X\[3:0\]" \
           "/test/DUT/asic_0/ctrl/u_id_sender/ipsum_tag_Y\[2:0\]" \
           "/test/DUT/asic_0/ctrl/u_id_sender/weight_tag_X\[3:0\]" \
           "/test/DUT/asic_0/ctrl/u_id_sender/weight_tag_Y\[2:0\]" \
           "/test/DUT/asic_0/ctrl/u_id_sender/opsum_tag_X\[3:0\]" \
           "/test/DUT/asic_0/ctrl/u_id_sender/opsum_tag_Y\[2:0\]"
wvSetPosition -win $_nWave1 {("G10" 0)}
wvSetPosition -win $_nWave1 {("G10" 6)}
wvSetPosition -win $_nWave1 {("G10" 6)}
wvScrollDown -win $_nWave1 1
wvScrollDown -win $_nWave1 0
wvScrollUp -win $_nWave1 1
wvSetPosition -win $_nWave1 {("G10" 4)}
wvSetPosition -win $_nWave1 {("G10" 5)}
wvSetPosition -win $_nWave1 {("G10" 6)}
wvSetPosition -win $_nWave1 {("G11" 0)}
wvAddSignal -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender/PEA_ifmap_ready" \
           "/test/DUT/asic_0/ctrl/u_id_sender/PEA_ifmap_valid" \
           "/test/DUT/asic_0/ctrl/u_id_sender/PEA_ipsum_ready" \
           "/test/DUT/asic_0/ctrl/u_id_sender/PEA_ipsum_valid" \
           "/test/DUT/asic_0/ctrl/u_id_sender/PEA_opsum_ready" \
           "/test/DUT/asic_0/ctrl/u_id_sender/PEA_opsum_valid" \
           "/test/DUT/asic_0/ctrl/u_id_sender/PEA_weight_ready" \
           "/test/DUT/asic_0/ctrl/u_id_sender/PEA_weight_valid"
wvSetPosition -win $_nWave1 {("G11" 0)}
wvSetPosition -win $_nWave1 {("G11" 8)}
wvSetPosition -win $_nWave1 {("G11" 8)}
wvSetPosition -win $_nWave1 {("G12" 0)}
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvSetCursor -win $_nWave1 65485900.462373 -snap {("G11" 8)}
wvSetCursor -win $_nWave1 65652796.337153 -snap {("G12" 0)}
wvSetCursor -win $_nWave1 65611072.368458 -snap {("G12" 0)}
wvSetCursor -win $_nWave1 65569348.399763 -snap {("G12" 0)}
wvSetCursor -win $_nWave1 65631934.352805 -snap {("G11" 8)}
wvZoom -win $_nWave1 64442801.244998 66216069.914535
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G8" 1 )} 
wvSetCursor -win $_nWave1 65310683.234278 -snap {("G11" 7)}
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 65499378.710677 -snap {("G11" 8)}
wvSetCursor -win $_nWave1 65595484.481267 -snap {("G11" 8)}
wvSetCursor -win $_nWave1 65513442.969788 -snap {("G11" 8)}
wvSelectSignal -win $_nWave1 {( "G7" 1 )} 
wvSetCursor -win $_nWave1 65593140.438082 -snap {("G11" 8)}
wvSetCursor -win $_nWave1 65504066.797048 -snap {("G11" 8)}
wvSetCursor -win $_nWave1 65586108.308526 -snap {("G11" 8)}
wvSetCursor -win $_nWave1 65499378.710677 -snap {("G11" 8)}
wvSetCursor -win $_nWave1 65595484.481267 -snap {("G11" 8)}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test"
wvGetSignalSetScope -win $_nWave1 "/test/DUT"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array/PE_ROW\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender"
wvSetPosition -win $_nWave1 {("G11" 7)}
wvSetPosition -win $_nWave1 {("G11" 8)}
wvSetPosition -win $_nWave1 {("G10" 6)}
wvSetPosition -win $_nWave1 {("G12" 0)}
wvAddSignal -win $_nWave1 \
           "/test/DUT/asic_0/ctrl/u_id_sender/count_weight_x\[2:0\]" \
           "/test/DUT/asic_0/ctrl/u_id_sender/count_weight_y\[2:0\]"
wvSetPosition -win $_nWave1 {("G12" 0)}
wvSetPosition -win $_nWave1 {("G12" 2)}
wvSetPosition -win $_nWave1 {("G12" 2)}
wvSelectSignal -win $_nWave1 {( "G11" 7 )} 
wvScrollUp -win $_nWave1 1
wvSetCursor -win $_nWave1 65494690.624307 -snap {("G7" 1)}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test"
wvGetSignalSetScope -win $_nWave1 "/test/DUT"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array/PE_ROW\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender"
wvSetPosition -win $_nWave1 {("G13" 0)}
wvAddSignal -win $_nWave1 \
           "/test/DUT/asic_0/ctrl/u_id_sender/PE_weight_num\[3:0\]"
wvSetPosition -win $_nWave1 {("G13" 0)}
wvSetPosition -win $_nWave1 {("G13" 1)}
wvSetPosition -win $_nWave1 {("G13" 1)}
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 65515494.007582 -snap {("G13" 1)}
wvSetCursor -win $_nWave1 65522526.137138 -snap {("G13" 1)}
wvSetCursor -win $_nWave1 65584057.270747 -snap {("G13" 1)}
wvSetCursor -win $_nWave1 65499085.705287 -snap {("G11" 8)}
wvSelectSignal -win $_nWave1 {( "G11" 7 )} 
wvZoomOut -win $_nWave1
wvSetCursor -win $_nWave1 65572630.060214 -snap {("G3" 1)}
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSelectSignal -win $_nWave1 {( "G11" 8 )} 
wvSelectSignal -win $_nWave1 {( "G11" 7 )} 
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test"
wvGetSignalSetScope -win $_nWave1 "/test/DUT"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array/PE_ROW\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test"
wvGetSignalSetScope -win $_nWave1 "/test/DUT"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array/PE_ROW\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender"
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test"
wvGetSignalSetScope -win $_nWave1 "/test/DUT"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array/PE_ROW\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvSetPosition -win $_nWave1 {("G9" 1)}
wvSetPosition -win $_nWave1 {("G9" 0)}
wvSetPosition -win $_nWave1 {("G9" 1)}
wvSetPosition -win $_nWave1 {("G10" 0)}
wvSetPosition -win $_nWave1 {("G10" 1)}
wvSetPosition -win $_nWave1 {("G10" 5)}
wvSetPosition -win $_nWave1 {("G12" 0)}
wvSetPosition -win $_nWave1 {("G13" 0)}
wvSetPosition -win $_nWave1 {("G13" 1)}
wvSetPosition -win $_nWave1 {("G14" 0)}
wvSetPosition -win $_nWave1 {("G13" 1)}
wvSetPosition -win $_nWave1 {("G14" 0)}
wvSetPosition -win $_nWave1 {("G13" 1)}
wvSetPosition -win $_nWave1 {("G14" 0)}
wvAddSignal -win $_nWave1 "/test/DUT/asic_0/PE_array/PE_filter_ready\[47:0\]"
wvSetPosition -win $_nWave1 {("G14" 0)}
wvSetPosition -win $_nWave1 {("G14" 1)}
wvSetPosition -win $_nWave1 {("G14" 1)}
wvDisplayGridCount -win $_nWave1 -off
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvReloadFile -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvScrollDown -win $_nWave1 1
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 80410057.422117 115214410.634675
wvZoom -win $_nWave1 94327197.999504 109624550.865566
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoom -win $_nWave1 87679209.553527 117768384.787763
wvZoom -win $_nWave1 100128531.230078 108202691.934043
wvZoom -win $_nWave1 101622757.930007 102594005.285011
wvSetCursor -win $_nWave1 102215905.686791 -snap {("G14" 1)}
wvSetCursor -win $_nWave1 102090728.400455 -snap {("G13" 1)}
wvSetCursor -win $_nWave1 102072112.291205 -snap {("G13" 1)}
wvSetCursor -win $_nWave1 101977105.940550 -snap {("G11" 8)}
wvSetCursor -win $_nWave1 102068260.682395 -snap {("G13" 1)}
wvSetCursor -win $_nWave1 102074680.030412 -snap {("G13" 1)}
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvScrollDown -win $_nWave1 1
wvScrollDown -win $_nWave1 1
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvDisplayGridCount -win $_nWave1 -off
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvCloseGetStreamsDialog -win $_nWave1
wvGetSignalClose -win $_nWave1
wvResizeWindow -win $_nWave1 0 23 1920 1009
wvReloadFile -win $_nWave1
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
wvScrollDown -win $_nWave1 0
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
wvZoom -win $_nWave1 46671227.824330 94657138.122584
wvZoom -win $_nWave1 62211939.024680 68491654.979111
wvZoom -win $_nWave1 65254260.105039 65802126.929880
wvSetCursor -win $_nWave1 65585587.365261 -snap {("G13" 1)}
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvGetSignalOpen -win $_nWave1
wvScrollDown -win $_nWave1 1
wvScrollDown -win $_nWave1 1
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvSetPosition -win $_nWave1 {("G14" 1)}
wvSetPosition -win $_nWave1 {("G14" 1)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/test/DUT/asic_0/ctrl/rf/regfile\[0:15\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[0\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[1\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[2\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[3\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[4\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[5\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[6\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[7\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[8\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[9\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[10\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[11\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[12\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[13\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[14\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/rf/regfile\[15\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/pc_counter/pc\[15:0\]} \
{/test/DUT/asic_0/ctrl/pc_counter/clk} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[0:15\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[0\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[1\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[2\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[3\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[4\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[5\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[6\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[7\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[8\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[9\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[10\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[11\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[12\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[13\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[14\]\[31:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/CSR\[15\]\[31:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
{/test/DUT/asic_0/ctrl/ctrl/opcode\[5:0\]} \
{/test/DUT/asic_0/ctrl/ctrl/PE_config\[10:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G3" \
{/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/cs\[3:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G4" \
{/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/ifmap_ready} \
}
wvAddSignal -win $_nWave1 -group {"G5" \
{/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/ifmap_valid} \
}
wvAddSignal -win $_nWave1 -group {"G6" \
{/test/DUT/asic_0/ctrl/u_id_sender/cs\[2:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G7" \
{/test/DUT/asic_0/ctrl/u_id_sender/en} \
{/test/DUT/asic_0/ctrl/u_id_sender/set_XID} \
{/test/DUT/asic_0/ctrl/u_id_sender/set_YID} \
}
wvAddSignal -win $_nWave1 -group {"G8" \
{/test/DUT/asic_0/ctrl/u_id_sender/tag_type\[1:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G9" \
{/test/DUT/asic_0/ctrl/u_id_sender/ifmap_tag_X\[3:0\]} \
{/test/DUT/asic_0/ctrl/u_id_sender/ifmap_tag_Y\[2:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G10" \
{/test/DUT/asic_0/ctrl/u_id_sender/ipsum_tag_X\[3:0\]} \
{/test/DUT/asic_0/ctrl/u_id_sender/ipsum_tag_Y\[2:0\]} \
{/test/DUT/asic_0/ctrl/u_id_sender/weight_tag_X\[3:0\]} \
{/test/DUT/asic_0/ctrl/u_id_sender/weight_tag_Y\[2:0\]} \
{/test/DUT/asic_0/ctrl/u_id_sender/opsum_tag_X\[3:0\]} \
{/test/DUT/asic_0/ctrl/u_id_sender/opsum_tag_Y\[2:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G11" \
{/test/DUT/asic_0/ctrl/u_id_sender/PEA_ifmap_ready} \
{/test/DUT/asic_0/ctrl/u_id_sender/PEA_ifmap_valid} \
{/test/DUT/asic_0/ctrl/u_id_sender/PEA_ipsum_ready} \
{/test/DUT/asic_0/ctrl/u_id_sender/PEA_ipsum_valid} \
{/test/DUT/asic_0/ctrl/u_id_sender/PEA_opsum_ready} \
{/test/DUT/asic_0/ctrl/u_id_sender/PEA_opsum_valid} \
{/test/DUT/asic_0/ctrl/u_id_sender/PEA_weight_ready} \
{/test/DUT/asic_0/ctrl/u_id_sender/PEA_weight_valid} \
}
wvAddSignal -win $_nWave1 -group {"G12" \
{/test/DUT/asic_0/ctrl/u_id_sender/count_weight_x\[2:0\]} \
{/test/DUT/asic_0/ctrl/u_id_sender/count_weight_y\[2:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G13" \
{/test/DUT/asic_0/ctrl/u_id_sender/PE_weight_num\[3:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G14" \
{/test/DUT/asic_0/PE_array/PE_filter_ready\[47:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G15" \
}
wvSetPosition -win $_nWave1 {("G14" 1)}
wvGetSignalClose -win $_nWave1
wvScrollUp -win $_nWave1 1
wvScrollUp -win $_nWave1 1
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/test"
wvGetSignalSetScope -win $_nWave1 "/test/DUT"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array/PE_ROW\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/ctrl/u_id_sender"
wvGetSignalSetScope -win $_nWave1 "/test/DUT/asic_0/PE_array"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]"
wvGetSignalSetScope -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE"
wvSetPosition -win $_nWave1 {("G14" 0)}
wvAddSignal -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/batch\[5:0\]"
wvSetPosition -win $_nWave1 {("G14" 0)}
wvSetPosition -win $_nWave1 {("G14" 1)}
wvSelectSignal -win $_nWave1 {( "G14" 1 )} 
wvSetRadix -win $_nWave1 -format UDec
wvSetPosition -win $_nWave1 {("G14" 2)}
wvSetPosition -win $_nWave1 {("G15" 0)}
wvAddSignal -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/ofmap_ch\[1:0\]"
wvSetPosition -win $_nWave1 {("G15" 0)}
wvSetPosition -win $_nWave1 {("G15" 1)}
wvSetPosition -win $_nWave1 {("G15" 1)}
wvSetPosition -win $_nWave1 {("G15" 0)}
wvSetPosition -win $_nWave1 {("G15" 1)}
wvAddSignal -win $_nWave1 \
           "/test/DUT/asic_0/PE_array/PE_ROW\[0\]/PE_COL\[0\]/PE/input_ch\[1:0\]"
wvSetPosition -win $_nWave1 {("G15" 1)}
wvSetPosition -win $_nWave1 {("G15" 2)}
