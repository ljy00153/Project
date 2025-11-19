`timescale 1ns/1ps

package isa_ctrl_pkg;
  // ---- Opcode set (coarse-grained) -----------------------------------------
  typedef enum logic [5:0] {
    OP_NOP       = 6'b000000,
    OP_CFG_DF    = 6'b000001, // set dataflow (WS/OS/IS)
    OP_CFG_TILE  = 6'b000010, // set tile sizes/strides
    OP_CFG_ADDR  = 6'b000011, // set base addresses
    OP_LOAD_IFM  = 6'b000100, // DMA read IFM
    OP_LOAD_W    = 6'b000101, // DMA read weights
    OP_STORE_OFM = 6'b000110, // DMA write OFM
    OP_COMPUTE   = 6'b000111, // kick PE compute (iters/unroll via imm)
    OP_WAIT      = 6'b001000, // wait for events mask
    OP_JUMP      = 6'b001001, // absolute jump (pc = imm)
    OP_END       = 6'b111111  // program end
  } opcode_e;


  // ---- Events bit definitions (used by WAIT imm mask) -----------------------
  localparam int EV_DMA_IFM   = 0;
  localparam int EV_DMA_W     = 1;
  localparam int EV_DMA_OFM   = 2;
  localparam int EV_PE_DONE   = 3;
  // Reserve others up to 17 if needed
endpackage : isa_ctrl_pkg

import isa_ctrl_pkg::*;

module isa_controller #(
  parameter int IMEM_DEPTH = 256,
  parameter int ADDR_W     = 64,
  parameter int SIZE_W     = 24
)(
  input clk,
  input rst,
  input asic_en,
  output logic asic_done,
  /* MMIO */
  input [`AXI_ADDR_BITS-1:0] DRAM_IFMAP_BASE,
  input [`AXI_ADDR_BITS-1:0] DRAM_WEIGHT_BASE,
  input [`AXI_ADDR_BITS-1:0] DRAM_OFMAP_BASE,
  input [`AXI_ADDR_BITS-1:0] DRAM_IFMAP_SIZE,
  input [`GLB_ADDR_BITS-1:0] DRAM_WEIGHT_SIZE,
  input [`GLB_ADDR_BITS-1:0] DRAM_OFMAP_SIZE,
  input [`GLB_ADDR_BITS-1:0] GLB_IFMAP_BASE,
  input [`GLB_ADDR_BITS-1:0] GLB_WEIGHT_BASE,
  input [`GLB_ADDR_BITS-1:0] GLB_OPSUM_BASE
  input [9:0] M,
  input [3:0] N,
  input [2:0] K,
  input [2:0] B,
  input [2:0] MODE,
  input [2:0] DATAFLOW,
  input [2:0] outf
  input [2:0] inf
  input [2:0] b
  input [2:0] k
  input [2:0] n
  input [2:0] m
  // ---------------- opcode -----------------------------

  input [5:0] opcode,
  input [15:0] imm,

  // ---------------- DMA  ------------------------------
  output logic DMA_en,
  output logic [1:0] DMA_mode,
  output logic [`AXI_ADDR_BITS-1:0] DMA_DRAM_ADDR,
  output logic [`GLB_ADDR_BITS-1:0] DMA_GLB_ADDR,
  output logic [`GLB_ADDR_BITS-1:0] DMA_len,
  output logic [1:0] DMA_byte_bias,
  input DMA_done,

  //-----------------PE ID config--------------------------------------------------
  
  output logic set_XID,
  output logic [`XID_BITS-1:0] ifmap_XID_scan_in,
  output logic [`XID_BITS-1:0] filter_XID_scan_in,
  output logic [`XID_BITS-1:0] ipsum_XID_scan_in,
  output logic [`XID_BITS-1:0] opsum_XID_scan_in,
  output logic set_YID,
  output logic [`YID_BITS-1:0] ifmap_YID_scan_in,
  output logic [`YID_BITS-1:0] filter_YID_scan_in,
  output logic [`YID_BITS-1:0] ipsum_YID_scan_in,
  output logic [`YID_BITS-1:0] opsum_YID_scan_in,
  output logic set_LN,
  output logic [`PE_ARRAY_H-2:0] LN_config_in,

  //------------PE Array----------------------

  output logic [`PE_ARRAY_H*`PE_ARRAY_W-1:0] PE_en,
  output logic [10:0] PE_config,

  output logic PEA_ifmap_valid,
  input PEA_ifmap_ready,
  output logic [`XID_BITS-1:0] ifmap_tag_X,
  output logic [`YID_BITS-1:0] ifmap_tag_Y,


  output logic PEA_filter_valid,
  input PEA_filter_ready,
  output logic [`XID_BITS-1:0] filter_tag_X,
  output logic [`YID_BITS-1:0] filter_tag_Y,

  output logic PEA_ipsum_valid,
  input PEA_ipsum_ready,
  output logic [`XID_BITS-1:0] ipsum_tag_X,
  output logic [`YID_BITS-1:0] ipsum_tag_Y,

  input PEA_opsum_valid,
  output logic PEA_opsum_ready,
  output logic [`XID_BITS-1:0] opsum_tag_X,
  output logic [`YID_BITS-1:0] opsum_tag_Y,

  output logic [1:0]            pe_dataflow,     // 0:WS 1:OS 2:IS
  output logic [15:0]           pe_m,
  output logic [15:0]           pe_n,
  output logic [15:0]           pe_k,
  output logic [15:0]           pe_b,
  output logic [7:0]            pe_iters,       // loop/iterations from imm
  input  logic                  pe_done,

  /* GLB */
  output logic GLB_EN,
  output logic GLB_WEB,
  output logic GLB_MODE,
  output logic [`GLB_ADDR_BITS-1:0] GLB_A
  output logic relu_sel,
  output logic Maxpool_en,
  output logic Maxpool_init,

  /* PC counter */
  output logic pc_hold,
  output logic next_pc_sel
);
  // ---------------------------------------------------------------------------
  // Program memory (IMEM) & PC
  // ---------------------------------------------------------------------------
  
  // Host mapping: 0..IMEM_DEPTH-1 => iMem, others => CSR space
  localparam int CSR_BASE = IMEM_DEPTH;

  // IMEM write (host)
  always_ff @(posedge clk) begin
    if (host_prog_we && (host_prog_addr < IMEM_DEPTH)) begin
      imem[host_prog_addr] <= host_prog_wdata;
    end
  end
 
  // Connect to PE

  // ---------------------------------------------------------------------------
  // Event engine: latch rising edges into a sticky status; WAIT checks mask
  // ---------------------------------------------------------------------------
  logic [17:0] event_status;      // sticky bits for events referenced by WAIT
  logic [2:0]  dma_done_sync;     // simple 1-cycle edge detect (example)
  logic        pe_done_sync;

  // Edge-detect & sticky-latch
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dma_done_sync  <= '0;
      pe_done_sync   <= 1'b0;
      event_status   <= '0;
    end else begin
      // simple level to pulse (one cycle) then sticky
      if (dma_ifm_done) event_status[EV_DMA_IFM] <= 1'b1;
      if (dma_w_done)   event_status[EV_DMA_W]   <= 1'b1;
      if (dma_ofm_done) event_status[EV_DMA_OFM] <= 1'b1;
      if (pe_done)      event_status[EV_PE_DONE] <= 1'b1;
    end
  end

  // Clear selected sticky bits (on explicit clear or after WAIT consumes them)
  logic [17:0] event_clear;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // nothing
    end else begin
      event_status <= event_status & ~event_clear;
    end
  end

  // ---------------------------------------------------------------------------
  // Decoder & command issue (1-issue, single-cycle decode)
  // ---------------------------------------------------------------------------
  // Default outputs
  always_comb begin
    // busy/done
    host_busy      = (pc != '0) || host_start; // basic heuristic
    host_done      = 1'b0;

    // PC control
    pc_hold        = 1'b0;

    // DMA command defaults
    dma_req_valid  = 1'b0;
    dma_req_kind   = '0;
    dma_req_addr   = '0;
    dma_req_size   = '0;

    // PE default
    pe_start       = 1'b0;

    // Event clear default
    event_clear    = '0;

    // Decode
    unique case (instr_r.opcode)
      OP_NOP: begin
        // do nothing
      end

      OP_CFG_DF: begin
        
      end    

      OP_CFG_TILE: begin
        
      end

      OP_CFG_ADDR: begin
      end

      OP_LOAD_IFM: begin
        dma_req_valid = 1'b1;
        dma_req_kind  = 2'd0; // IFM 
        dma_req_addr  = cfg.base_ifm;  // could add imm offset if needed
        dma_req_size  = (instr_r.imm != 0) ? instr_r.imm[SIZE_W-1:0] : cfg.size_ifm;
      end

      OP_LOAD_W: begin
        dma_req_valid = 1'b1;
        dma_req_kind  = 2'd1; // W
        dma_req_addr  = cfg.base_w;
        dma_req_size  = (instr_r.imm != 0) ? instr_r.imm[SIZE_W-1:0] : cfg.size_w;
      end

      OP_STORE_OFM: begin
        dma_req_valid = 1'b1;
        dma_req_kind  = 2'd2; // OFM
        dma_req_addr  = cfg.base_ofm;
        dma_req_size  = (instr_r.imm != 0) ? instr_r.imm[SIZE_W-1:0] : cfg.size_ofm;
      end

      OP_COMPUTE: begin
        PE_en = 'b1; 
        
      end

      OP_WAIT: begin
        // Clear the events that are waited for
        event_clear = instr_r.imm[17:0] & event_status;
        // Hold PC until all waited events are set
        if ((event_status & instr_r.imm[17:0]) != instr_r.imm[17:0]) begin
          pc_hold = 1'b1; 


      end
      end 
      OP_JUMP: begin
        
      end

      OP_END: begin
        pc_hold   = 1'b1; // stop here
      end

      default: ;
    endcase
  end



endmodule : isa_controller
