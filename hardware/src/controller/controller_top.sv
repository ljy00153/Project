`timescale 1ns/1ps
`include "../include/ISA.svh"

module controller_top #(
    parameter int PC_WIDTH = 16
)(
    input  logic clk,
    input  logic rst,
    input  logic asic_en,
    output logic asic_done,
    //tb write instruction to IM
    input  logic        im_init_en,
    input  logic [15:0] im_init_addr,
    input  logic [31:0] im_init_wdata,

    // (drawio: AXI_SlaveASIC_MMIO / CSR bank 這些值餵進 Controller)
    input  logic [31:0] DRAM_ifmap_base,
    input  logic [31:0] DRAM_weight_base,
    input  logic [31:0] DRAM_ofmap_base,
    input  logic [31:0] GLB_ifmap_base,
    input  logic [31:0] GLB_weight_base,
    input  logic [31:0] GLB_opsum_base,
    input  logic [31:0] OF_SIZE,
    input  logic [31:0] IF_SIZE,
    input  logic [31:0] B_SIZE,
    input  logic [31:0] K_SIZE,
    input  logic [31:0] N_SIZE,
    input  logic [31:0] M_SIZE,
    input  logic [31:0] DATAFLOW,

    // GLB
    output logic GLB_EN, 
    output logic GLB_WEB, 
    output logic GLB_MODE, 
    output logic [`GLB_ADDR_BITS-1:0]GLB_ADDR,
    //PEA

    output logic [`PE_ARRAY_H*`PE_ARRAY_W-1:0] PE_en,
    output logic [10:0]                        PE_config,
    output logic                        set_XID,
    output logic [`XID_BITS-1:0]        ifmap_XID_scan_in,
    output logic [`XID_BITS-1:0]        weight_XID_scan_in,
    output logic [`XID_BITS-1:0]        ipsum_XID_scan_in,
    output logic [`XID_BITS-1:0]        opsum_XID_scan_in,

    output logic                        set_YID,
    output logic [`YID_BITS-1:0]        ifmap_YID_scan_in,
    output logic [`YID_BITS-1:0]        weight_YID_scan_in,
    output logic [`YID_BITS-1:0]        ipsum_YID_scan_in,
    output logic [`YID_BITS-1:0]        opsum_YID_scan_in,

    output logic                        set_LN,
    output logic [`PE_ARRAY_H-2:0]      LN_config_in,

    // PEA handshake + tag
    output logic                        PEA_ifmap_valid,
    input  logic                        PEA_ifmap_ready,
    output logic [`XID_BITS-1:0]        ifmap_tag_X,
    output logic [`YID_BITS-1:0]        ifmap_tag_Y,

    output logic                        PEA_weight_valid,
    input  logic                        PEA_weight_ready,
    output logic [`XID_BITS-1:0]        weight_tag_X,
    output logic [`YID_BITS-1:0]        weight_tag_Y,

    output logic                        PEA_ipsum_valid,
    input  logic                        PEA_ipsum_ready,
    output logic [`XID_BITS-1:0]        ipsum_tag_X,
    output logic [`YID_BITS-1:0]        ipsum_tag_Y,

    input  logic                        PEA_opsum_valid,
    output logic                        PEA_opsum_ready,
    output logic [`XID_BITS-1:0]        opsum_tag_X,
    output logic [`YID_BITS-1:0]        opsum_tag_Y,

    /* DMA */
    output logic  DMA_en,
    output logic  [1:0]DMA_mode,
    output logic  [`AXI_ADDR_BITS-1:0]DMA_DRAM_ADDR,
    output logic  [`GLB_ADDR_BITS-1:0]DMA_GLB_ADDR,
    output logic  [`GLB_ADDR_BITS-1:0]DMA_len,
    output logic  [1:0]DMA_BYTE_BIAS,
    input logic  DMA_done,

    output logic GLB_DI_select,
    output logic GLB_DO_select,
    output logic GLB_mux

);

    // ----------------------------
    // PC path (PC -> IM -> instr)
    // ----------------------------
    logic [PC_WIDTH-1:0] pc, pc_plus_4, next_pc;
    logic pc_hold,pc_en;
    logic next_pc_sel;
    assign pc_en = asic_en;
    pc_counter #(.pc_WIDTH(PC_WIDTH)) pc_counter (
        .clk     (clk),
        .rst     (rst),
        .en (pc_en),
        .nxt_pc  (next_pc),
        .pc_hold (pc_hold),
        .pc      (pc)
    );

    pc_adder #(.pc_WIDTH(PC_WIDTH)) pc_adder (
        .pc     (pc),
        .pc_out (pc_plus_4)
    );
    
    logic im_wen;
    logic [15:0]im_addr;
    logic [31:0]im_wdata;
    assign im_wen   = im_init_en;
    assign im_addr  = im_init_en ? im_init_addr : pc[15:0];
    assign im_wdata = im_init_wdata;
    
    // Instruction memory (drawio: IM)
    logic [31:0] instr;
    SRAM_IM im (
        .clk   (clk),
        .w_en  (im_wen),
        .addr  (im_addr),
        .w_data(im_wdata),
        .r_data(instr)
    );

    // ----------------------------
    // Decode
    // ----------------------------
    logic [3:0] csr_index, rs_index1, rs_index2, rd_index, cfg_type;
    logic [31:0] imm;
    logic [5:0]  opcode;
    logic [1:0]  type_wire;
    logic [5:0] target;
    decoder dec (
        .instr     (instr),
        .csr_index (csr_index),
        .rs_index1 (rs_index1),
        .rs_index2 (rs_index2),
        .rd_index  (rd_index),
        .imm       (imm),
        .opcode    (opcode),
        .inst_type      (type_wire),
        .cfg_type  (cfg_type),
        .target (target)
    );

    // ----------------------------
    // RegFile
    // ----------------------------
    logic [31:0] rs1_data, rs2_data, loop_reg;
    logic        reg_wb_en;
    logic [31:0] alu_result;

    regfile rf (
        .clk      (clk),
        .rst      (rst),
        .wb_en    (reg_wb_en),
        .rd_index (rd_index),
        .wdata    (alu_result),
        .rs1_index(rs_index1),
        .rdata1   (rs1_data),
        .rs2_index(rs_index2),
        .rdata2   (rs2_data),
        .loop_reg (loop_reg)
    );

    // ----------------------------
    // Immediate / branch target (drawio: Imm_Ext + target_or_jump)
    // 這裡用最常見的 branch/jump target = imm
    // ----------------------------
    logic [PC_WIDTH-1:0] target_or_jump;
    assign target_or_jump = (opcode==`OP_LOOP)?{10'b0,target}:imm[15:0];

    // PC mux (drawio: PCmux)
    assign next_pc = (next_pc_sel) ? {2'b0, target_or_jump[15:2]} : pc_plus_4 ; 

    // mux.out 是 32-bit，取低 PC_WIDTH 當 next_pc
    //assign next_pc = reg_wb_data[PC_WIDTH-1:0];

    // ----------------------------
    // ALU operand muxes (drawio: alu_op1_sel / alu_op2_sel)
    // op1: rs1 或 pc
    // op2: rs2 或 imm
    // ----------------------------
    logic alu_op1_sel, alu_op2_sel;
    logic [31:0] alu_op1, alu_op2;



    // ----------------------------
    // ALU
    // ----------------------------
    logic        branch_result;

    ALU alu (
        .rs1_src      (alu_op1),
        .rs2_src      (alu_op2),
        .opcode       (opcode),
        .loop_reg_src (loop_reg),
        .result       (alu_result),
        .branch_result(branch_result)
    );

    // ----------------------------
    // Controller (drawio: Controller / signal_controller)
    // ----------------------------
    logic [3:0] mmio_sel;
    logic csr_wen;
    logic [31:0] CSR_output;

    // 這些 GLB 控制線你後面要接 GLB / DMA 再拉出去
    logic [31:0] glb_addr_base;
    logic [1:0]  glb_type;
    logic GLB_EN_wire, GLB_WEB_wire, GLB_MODE_wire;
    logic relu_sel, Maxpool_en, Maxpool_init;
    logic glb_done;
    logic config_id_en;
    logic CTRL_DMA_en;
    logic [1:0]CTRL_DMA_mode;
    logic [`AXI_ADDR_BITS-1:0] CTRL_DMA_DRAM_ADDR;
    logic [`GLB_ADDR_BITS-1:0] CTRL_DMA_GLB_ADDR;
    logic [`GLB_ADDR_BITS-1:0] CTRL_DMA_len;
    logic CTRL_DMA_done;
    logic [1:0] CTRL_DMA_byte_bias;
    logic [31:0] OF_BYTE,IF_BYTE,B_BYTE,K_BYTE,N_BYTE,M_BYTE;
 
    signal_controller ctrl (
        .clk            (clk),
        .rst            (rst),
        .asic_en        (asic_en),
        .asic_done      (asic_done),

        .mmio_sel       (mmio_sel),
        .csr_wen        (csr_wen),

        .DRAM_ifmap_base (DRAM_ifmap_base),
        .DRAM_weight_base(DRAM_weight_base),
        .DRAM_ofmap_base (DRAM_ofmap_base),
        .GLB_ifmap_base  (GLB_ifmap_base),
        .GLB_weight_base (GLB_weight_base),
        .GLB_opsum_base  (GLB_opsum_base),
        .OF_SIZE         (OF_SIZE),
        .IF_SIZE         (IF_SIZE),
        .B_SIZE          (B_SIZE),
        .K_SIZE          (K_SIZE),
        .N_SIZE          (N_SIZE),
        .M_SIZE          (M_SIZE),
        .DATAFLOW        (DATAFLOW),

        .DMA_en          (CTRL_DMA_en),   // 你有 DMA 模組時再接
        .DMA_mode        (CTRL_DMA_mode),
        .DMA_len         (CTRL_DMA_len),
        .DMA_DRAM_ADDR   (CTRL_DMA_DRAM_ADDR),
        .DMA_GLB_ADDR    (CTRL_DMA_GLB_ADDR),
        .DMA_done        (CTRL_DMA_done), // 目前沒 DMA，先綁 0（你之後要改）
        .DMA_byte_bias   (DMA_BYTE_BIAS),

        .OF_BYTE(OF_BYTE),
        .IF_BYTE(IF_BYTE),
        .B_BYTE(B_BYTE),
        .K_BYTE(K_BYTE),
        .N_BYTE(N_BYTE),
        .M_BYTE(M_BYTE),            

        .ID_sender_en (config_id_en),
        .PEA_ifmap_ready(),
        .PEA_filter_ready(),
        .PEA_ipsum_ready(),
        .PEA_opsum_valid(),
    
        .PE_finish (),
        .PE_en(PE_en),
        .PE_config(PE_config),
        .GLB_mux (GLB_mux),
        .GLB_DI_select (GLB_DI_select),
        .GLB_DO_select (GLB_DO_select),
        .glb_addr_base   (glb_addr_base),
        .glb_type        (glb_type),
        .glb_done        (glb_done),

        .GLB_EN          (GLB_EN_wire),
        .GLB_WEB         (GLB_WEB_wire),
        .GLB_MODE        (GLB_MODE_wire),

        .relu_sel        (relu_sel),
        .Maxpool_en      (Maxpool_en),
        .Maxpool_init    (Maxpool_init),

        .ALU_result      (alu_result),

        .opcode          (opcode),
        .CSR_index       (csr_index),
        .CFG_TYPE        (cfg_type),
        .inst_type       (type_wire),
        .imm             (imm),
        .branch_result   (branch_result),
        .CSR_output      (CSR_output),

        .pc_hold         (pc_hold),
        .next_pc_sel     (next_pc_sel),
        .alu_op1_sel     (alu_op1_sel),
        .alu_op2_sel     (alu_op2_sel),
        .reg_wb_en       (reg_wb_en)
 
    );
    
    assign alu_op1 = (alu_op1_sel) ? rs1_data : CSR_output ;
    assign alu_op2 = (alu_op2_sel) ? imm : rs2_data;
   
    assign GLB_EN = GLB_EN_wire ;
    assign GLB_WEB = GLB_WEB_wire ;
    assign GLB_MODE = GLB_MODE_wire ;
    

    // ----------------------------
    // glb_addr_generator signals
    // ----------------------------
    logic [`GLB_ADDR_BITS-1:0]    glb_a;
    logic tag_id_en;
    glb_addr_generator #(
    .tk              (72),
    .tn              (32),
    .KK_STRIDE_BYTES (12)
    ) glb_addr_generator (
        .clk      (clk),
        .rst      (rst),
        .en       (GLB_EN_wire),
        .base_in  (glb_addr_base),
        .type_in  (glb_type),
        .K_bytes  (K_BYTE),
        .id_en (tag_id_en),
        .glb_a    (glb_a),
        .done     (glb_done)
    );
    assign GLB_ADDR = glb_a;


    // ----------------------------
    // ID_SENDER signals
    // ----------------------------
    logic [1:0]  tag_type;
    logic id_en;
    assign id_en = (opcode==`OP_SET_ID)? config_id_en: tag_id_en;
    

    
    ID_SENDER u_id_sender (
        .clk                  (clk),
        .rst                  (rst),
        .en                   (id_en),
        .tag_type             (glb_type),

        .set_XID              (set_XID),
        .ifmap_XID_scan_in    (ifmap_XID_scan_in),
        .weight_XID_scan_in   (weight_XID_scan_in),
        .ipsum_XID_scan_in    (ipsum_XID_scan_in),
        .opsum_XID_scan_in    (opsum_XID_scan_in),

        .set_YID              (set_YID),
        .ifmap_YID_scan_in    (ifmap_YID_scan_in),
        .weight_YID_scan_in   (weight_YID_scan_in),
        .ipsum_YID_scan_in    (ipsum_YID_scan_in),
        .opsum_YID_scan_in    (opsum_YID_scan_in),

        .set_LN               (set_LN),
        .LN_config_in         (LN_config_in),

        .PEA_ifmap_valid      (PEA_ifmap_valid),
        .PEA_ifmap_ready      (PEA_ifmap_ready),
        .ifmap_tag_X          (ifmap_tag_X),
        .ifmap_tag_Y          (ifmap_tag_Y),

        .PEA_weight_valid     (PEA_weight_valid),
        .PEA_weight_ready     (PEA_weight_ready),
        .weight_tag_X         (weight_tag_X),
        .weight_tag_Y         (weight_tag_Y),

        .PEA_ipsum_valid      (PEA_ipsum_valid),
        .PEA_ipsum_ready      (PEA_ipsum_ready),
        .ipsum_tag_X          (ipsum_tag_X),
        .ipsum_tag_Y          (ipsum_tag_Y),

        .PEA_opsum_valid      (PEA_opsum_valid),
        .PEA_opsum_ready      (PEA_opsum_ready),
        .opsum_tag_X          (opsum_tag_X),
        .opsum_tag_Y          (opsum_tag_Y)
    );

    DMA_Loop_Unit DMA_Loop(
        .clk(clk),
        .rst(rst),
    /* Controller */
        .CTRL_DMA_en(CTRL_DMA_en),
        .CTRL_DMA_mode(CTRL_DMA_mode),
        .CTRL_DMA_DRAM_ADDR(CTRL_DMA_DRAM_ADDR),
        .CTRL_DMA_GLB_ADDR(CTRL_DMA_GLB_ADDR),
        .CTRL_DMA_len(CTRL_DMA_len),
        .CTRL_DMA_done(CTRL_DMA_done),
    /* DMA */
        .DMA_en(DMA_en),
        .DMA_mode(DMA_mode),
        .DMA_DRAM_ADDR(DMA_DRAM_ADDR),
        .DMA_GLB_ADDR(DMA_GLB_ADDR),
        .DMA_len(DMA_len),
        .DMA_done(DMA_done),
    /* CSR */
        .B(B_BYTE),
        .N(N_BYTE), 
        .M(M_BYTE), 
        .K(K_BYTE),
        .in_features(IF_BYTE), 
        .out_features(OF_BYTE)
);



endmodule
