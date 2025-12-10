module top(
    input  logic clk,
    input  logic rst,
    input  logic asic_en,
    output logic asic_done,

    /* MMIO */
    input logic [31:0] DRAM_ifmap_base,
    input logic [31:0] DRAM_weight_base,
    input logic [31:0] DRAM_ofmap_base,
    input logic [31:0] GLB_ifmap_base,
    input logic [31:0] GLB_weight_base,
    input logic [31:0] GLB_opsum_base,
    input logic [31:0] OF_SIZE,
    input logic [31:0] IF_SIZE,
    input logic [31:0] B_SIZE,
    input logic [31:0] K_SIZE,
    input logic [31:0] N_SIZE,
    input logic [31:0] M_SIZE,
    input logic [31:0] DATAFLOW,
    // ---------------- DMA LOOPER------------------------------
    output logic                    DMA_en,
    output logic [1:0]              DMA_mode,       // IFMAP:0, Filter:1, BIAS:2, OFMAP: 3
    output logic [`AXI_ADDR_BITS-1:0] DMA_DRAM_ADDR,
    output logic [`GLB_ADDR_BITS-1:0] DMA_GLB_ADDR,
    output logic [`GLB_ADDR_BITS-1:0] DMA_len,
    output logic [1:0]              DMA_byte_bias,
    input  logic                    DMA_done,

    //-----------------PE ID config--------------------------------------------------
    output logic                  ID_sender_en,
    
    output logic PEA_ifmap_valid,
    input PEA_ifmap_ready,

    output logic PEA_filter_valid,
    input PEA_filter_ready,

    output logic PEA_ipsum_valid,
    input PEA_ipsum_ready,

    input PEA_opsum_valid,
    output logic PEA_opsum_ready,
    //------------PE Array----------------------
    output logic [`PE_ARRAY_H*`PE_ARRAY_W-1:0] PE_en,
    output logic [10:0]                        PE_config,
    //------------GLB----------------------
    output logic GLB_EN,
    output logic GLB_WEB,
    output logic GLB_MODE,
    output logic [`GLB_ADDR_BITS-1:0] GLB_A,
    output logic GLB_mux,
    output logic GLB_DI_select,
    output logic GLB_DO_select,


    //------------PPU-----------------------
    output logic                  relu_sel,
    output logic                  Maxpool_en,
    output logic                  Maxpool_init,

    //------------control signal--------------------
    //decoder
    input [5:0]opcode,
    input [3:0]CSR_index,
    input [3:0]CFG_TYPE,
    input [31:0]imm,
    //
    output logic [31:0] CSR_output,
    output branch_result,
    /* PC counter control */
    output logic pc_hold,       // 1: PC 不加一（WAIT）
    output logic next_pc_sel    // 0: pc+1, 1: 分支/loop/jump target（假定由別處決定）
    output logic alu_op1_sel,
    output logic alu_op2_sel



);
    
    
    pc_counter pc_counter1(
        .clk(clk),
        .rst(rst),
        
        .hold(pc_hold),        .imm(imm),
        .pc_out(pc_out)
    );


endmodule