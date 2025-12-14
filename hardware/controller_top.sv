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

    // 你 signal_controller 需要的外部 done（先當作外部輸入）
    input  logic glb_done
);

    // ----------------------------
    // PC path (PC -> IM -> instr)
    // ----------------------------
    logic [PC_WIDTH-1:0] pc, pc_plus_4, next_pc;
    logic pc_hold;
    logic next_pc_sel;

    pc_counter #(.pc_WIDTH(PC_WIDTH)) pc_counter (
        .clk     (clk),
        .rst     (rst),
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
    SRAM im (
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
    assign target_or_jump = (opcode==`OP_LOOP)?{10'b0,target}:imm[21:6];

    // PC mux (drawio: PCmux)
    assign next_pc = (next_pc_sel) ? target_or_jump : pc_plus_4 ; 

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

    ALU u_alu (
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
    logic GLB_DI_select, GLB_DO_select, glb_addr_gen_en;
    logic [31:0] glb_addr_base;
    logic [1:0]  glb_type;
    logic GLB_EN, GLB_WEB, GLB_MODE;
    logic [31:0] K_bytes;
    logic relu_sel, Maxpool_en, Maxpool_init;

    signal_controller u_ctrl (
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

        .DMA_en          (),   // 你有 DMA 模組時再接
        .DMA_mode        (),
        .DMA_len         (),
        .DMA_DRAM_ADDR        (),
        .DMA_GLB_ADDR     (),
        .DMA_done        (1'b0), // 目前沒 DMA，先綁 0（你之後要改）

        .GLB_DI_select   (GLB_DI_select),
        .GLB_DO_select   (GLB_DO_select),
        .glb_addr_gen_en (glb_addr_gen_en),
        .glb_addr_base   (glb_addr_base),
        .glb_type        (glb_type),
        .GLB_EN          (GLB_EN),
        .GLB_WEB         (GLB_WEB),
        .GLB_MODE        (GLB_MODE),
        .K_bytes         (K_bytes),
        .glb_done        (glb_done),

        .relu_sel        (relu_sel),
        .Maxpool_en      (Maxpool_en),
        .Maxpool_init    (Maxpool_init),

        .ALU_result      (alu_result),

        .opcode          (opcode),
        .CSR_index       (csr_index),
        .CFG_TYPE        (cfg_type),
        .inst_type            (type_wire),
        .imm             (imm),
        .branch_result   (branch_result),

        .CSR_output      (CSR_output),

        .pc_hold         (pc_hold),
        .next_pc_sel     (next_pc_sel),
        .alu_op1_sel     (alu_op1_sel),
        .alu_op2_sel     (alu_op2_sel),
        .reg_wb_en (reg_wb_en)
    );
    
    assign alu_op1 = (alu_op1_sel) ? rs1_data : CSR_output ;
    assign alu_op2 = (alu_op2_sel) ? imm : rs2_data;
   

endmodule
