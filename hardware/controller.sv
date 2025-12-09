`include "AXI_define.svh"
`include "ASIC.svh"
`include "../include/ISA.svh"
module isa_controller #(
  parameter int IMEM_DEPTH = 256,
  parameter int ADDR_W     = 64,
  parameter int SIZE_W     = 24
)(
  input  logic clk,
  input  logic rst,
  input  logic asic_en,
  output logic asic_done,

  /* MMIO */
  input  logic [`AXI_ADDR_BITS-1:0] DRAM_IFMAP_BASE,
  input  logic [`AXI_ADDR_BITS-1:0] DRAM_WEIGHT_BASE,
  input  logic [`AXI_ADDR_BITS-1:0] DRAM_OFMAP_BASE,
  input  logic [`GLB_ADDR_BITS-1:0] GLB_IFMAP_BASE,
  input  logic [`GLB_ADDR_BITS-1:0] GLB_WEIGHT_BASE,
  input  logic [`GLB_ADDR_BITS-1:0] GLB_OPSUM_BASE,
  input  logic [15:0] OF_SIZE,
  input  logic [15:0] IF_SIZE,
  input  logic [15:0] B_SIZE,
  input  logic [15:0] K_SIZE,
  input  logic [15:0] N_SIZE, 
  input  logic [15:0] M_SIZE,
  input  logic        MODE,
  input  logic [1:0]  DATA_FLOW,

  // ---------------- opcode / imm -----------------------------
  input  logic [5:0]  opcode,
  input  logic [15:0] imm,      // 這裡只給 16-bit；你若要 imm18/offset12 要自己決定 encoding

  // ---------------- DMA  ------------------------------
  output logic                    DMA_en,
  output logic [1:0]              DMA_mode,       // IFMAP:0, Filter:1, BIAS:2, OFMAP: 3
  output logic [`AXI_ADDR_BITS-1:0] DMA_DRAM_ADDR,
  output logic [`GLB_ADDR_BITS-1:0] DMA_GLB_ADDR,
  output logic [`GLB_ADDR_BITS-1:0] DMA_len,
  output logic [1:0]              DMA_byte_bias,
  input  logic                    DMA_done,

  //-----------------PE ID config--------------------------------------------------
  output logic                  set_XID,
  output logic [`XID_BITS-1:0]  ifmap_XID_scan_in,
  output logic [`XID_BITS-1:0]  filter_XID_scan_in,
  output logic [`XID_BITS-1:0]  ipsum_XID_scan_in,
  output logic [`XID_BITS-1:0]  opsum_XID_scan_in,
  output logic                  set_YID,
  output logic [`YID_BITS-1:0]  ifmap_YID_scan_in,
  output logic [`YID_BITS-1:0]  filter_YID_scan_in,
  output logic [`YID_BITS-1:0]  ipsum_YID_scan_in,
  output logic [`YID_BITS-1:0]  opsum_YID_scan_in,
  output logic                  set_LN,
  output logic [`PE_ARRAY_H-2:0] LN_config_in,

  //------------PE Array----------------------
  output logic [`PE_ARRAY_H*`PE_ARRAY_W-1:0] PE_en,
  output logic [10:0]                        PE_config,

  output logic                  PEA_ifmap_valid,
  input  logic                  PEA_ifmap_ready,
  output logic [`XID_BITS-1:0]  ifmap_tag_X,
  output logic [`YID_BITS-1:0]  ifmap_tag_Y,

  output logic                  PEA_filter_valid,
  input  logic                  PEA_filter_ready,
  output logic [`XID_BITS-1:0]  filter_tag_X,
  output logic [`YID_BITS-1:0]  filter_tag_Y,

  output logic                  PEA_ipsum_valid,
  input  logic                  PEA_ipsum_ready,
  output logic [`XID_BITS-1:0]  ipsum_tag_X,
  output logic [`YID_BITS-1:0]  ipsum_tag_Y,

  input  logic                  PEA_opsum_valid,
  output logic                  PEA_opsum_ready,
  output logic [`XID_BITS-1:0]  opsum_tag_X,
  output logic [`YID_BITS-1:0]  opsum_tag_Y,

  /* GLB */
  output logic                  GLB_EN,
  output logic                  GLB_WEB,
  output logic                  GLB_MODE,
  output logic [`GLB_ADDR_BITS-1:0] GLB_A,
  output logic                  relu_sel,
  output logic                  Maxpool_en,
  output logic                  Maxpool_init,

  /* PC counter control */
  output logic pc_hold,       // 1: PC 不加一（WAIT）
  output logic next_pc_sel    // 0: pc+1, 1: 分支/loop/jump target（假定由別處決定）
);

  // -----------------------------
  // ISA opcode (沿用 simulator 那套)
  // -----------------------------
  localparam logic [5:0]
    OP_NOP             = 6'b000000,
    OP_CFG_SET         = 6'b000001,
    OP_SET_ID          = 6'b000010,

    OP_DMA_LOAD_IFMAP  = 6'b000100,
    OP_DMA_LOAD_WEIGHT = 6'b000101,
    OP_DMA_LOAD_PSUM   = 6'b000110,
    OP_DMA_STORE_OFMAP = 6'b000111,

    OP_G2P             = 6'b001000,
    OP_P2G_OPSUM       = 6'b001001,

    OP_CPT_INDEX       = 6'b010000,
    OP_CPT_TAGXY       = 6'b011000,

    OP_COMPUTE         = 6'b011100,
    OP_WAIT            = 6'b011101,
    OP_JUMP            = 6'b011110,
    OP_LOOP            = 6'b011111,

    OP_LOADI           = 6'b100000,
    OP_ADDI            = 6'b100001,
    OP_MULI            = 6'b100010,

    OP_ADD             = 6'b100100,
    OP_MUL             = 6'b100101,

    OP_END             = 6'b111111;

  // -----------------------------
  // 簡單狀態機：IDLE / RUN / DONE
  // -----------------------------
  typedef enum logic [1:0] {S_IDLE, S_RUN, S_DONE} state_t;
  state_t state, state_n;

  // -----------------------------
  // REG / CSR（先做 16 個，每個 32-bit）
  // 注意：rd/rs/loopReg 目前沒有從 port 給，你之後要從 decoder 接進來
  // -----------------------------
  localparam int REG_NUM = 16;
  localparam int CSR_NUM = 16;

  logic [31:0] regfile [0:REG_NUM-1];
  logic [31:0] csr     [0:CSR_NUM-1];

  // busy flags 對應 WAIT
  logic dma_busy, dma_busy_n;
  logic glb_busy, glb_busy_n;
  logic pe_busy,  pe_busy_n;

  // 簡單 tag 暫存（你現在 real design 應該會做比較複雜，我先放骨架）
  logic [`XID_BITS-1:0] tagX_ifmap,  tagX_weight,  tagX_ipsum,  tagX_opsum;
  logic [`YID_BITS-1:0] tagY_ifmap,  tagY_weight,  tagY_ipsum,  tagY_opsum;

  // ----------------------------------
  // combinational: decode / control
  // ----------------------------------
  always_comb begin
    // default outputs
    DMA_en         = 1'b0;
    DMA_mode       = 2'b00;
    DMA_DRAM_ADDR  = '0;
    DMA_GLB_ADDR   = '0;
    DMA_len        = '0;
    DMA_byte_bias  = 2'b00;

    set_XID        = 1'b0;
    set_YID        = 1'b0;
    set_LN         = 1'b0;
    LN_config_in   = '0;

    PE_en          = '0;
    PE_config      = '0;
    PEA_ifmap_valid  = 1'b0;
    PEA_filter_valid = 1'b0;
    PEA_ipsum_valid  = 1'b0;
    PEA_opsum_ready  = 1'b0;

    ifmap_tag_X    = tagX_ifmap;
    ifmap_tag_Y    = tagY_ifmap;
    filter_tag_X   = tagX_weight;
    filter_tag_Y   = tagY_weight;
    ipsum_tag_X    = tagX_ipsum;
    ipsum_tag_Y    = tagY_ipsum;
    opsum_tag_X    = tagX_opsum;
    opsum_tag_Y    = tagY_opsum;

    GLB_EN         = 1'b0;
    GLB_WEB        = 1'b0;
    GLB_MODE       = 1'b0;
    GLB_A          = '0;
    relu_sel       = 1'b0;
    Maxpool_en     = 1'b0;
    Maxpool_init   = 1'b0;

    pc_hold        = 1'b0;
    next_pc_sel    = 1'b0; // 預設 pc+1

    // busy flag default
    dma_busy_n     = dma_busy;
    glb_busy_n     = glb_busy;
    pe_busy_n      = pe_busy;

    // 清 busy：看到 done 就清
    if (DMA_done)       dma_busy_n = 1'b0;
    if (glb_busy) begin
      // TODO: glb_busy 的 done 來源要接外面（這裡先簡化用 PEA_ifmap_ready/PEA_filter_ready/PEA_ipsum_ready）
      if (PEA_ifmap_ready && PEA_filter_ready && PEA_ipsum_ready)
        glb_busy_n = 1'b0;
    end
    if (pe_busy && PEA_opsum_valid)
      pe_busy_n = 1'b0;

    state_n   = state;
    asic_done = (state == S_DONE);

    unique case (state)
      S_IDLE: begin
        if (asic_en) begin
          state_n   = S_RUN;
        end
      end

      S_RUN: begin
        unique case (opcode)
          // ---------- NOP ----------
          OP_NOP: begin
            // do nothing
          end

          // ---------- CFG_SET: 用 MMIO 寫 CSR ----------
          OP_CFG_SET: begin
            // 真正寫 csr[] 放在 sequential block，這邊只需要讓 PC+1
          end

          // ---------- DMA ----------
          OP_DMA_LOAD_IFMAP: begin
            DMA_en        = 1'b1;
            DMA_mode      = `MODE_IFMAP;
            DMA_DRAM_ADDR = DRAM_IFMAP_BASE + regfile; // + regfile[rs] (TODO)
            DMA_GLB_ADDR  = GLB_IFMAP_BASE;  // + regfile[rs]
            DMA_len       = imm[`GLB_ADDR_BITS-1:0]; // 現在用 imm 當 len
            dma_busy_n    = 1'b1;
          end
          OP_DMA_LOAD_WEIGHT: begin
            DMA_en        = 1'b1;
            DMA_mode      = `MODE_FILTER;
            DMA_DRAM_ADDR = DRAM_WEIGHT_BASE;
            DMA_GLB_ADDR  = GLB_WEIGHT_BASE;
            DMA_len       = imm[`GLB_ADDR_BITS-1:0];
            dma_busy_n    = 1'b1;
          end
          OP_DMA_LOAD_PSUM: begin
            DMA_en        = 1'b1;
            DMA_mode      = `MODE_BIAS;
            DMA_DRAM_ADDR = DRAM_OFMAP_BASE;   // 依實際架構改
            DMA_GLB_ADDR  = GLB_OPSUM_BASE;
            DMA_len       = imm[`GLB_ADDR_BITS-1:0];
            dma_busy_n    = 1'b1;
          end
          OP_DMA_STORE_OFMAP: begin
            DMA_en        = 1'b1;
            DMA_mode      = `MODE_OFMAP;
            DMA_DRAM_ADDR = DRAM_OFMAP_BASE;
            DMA_GLB_ADDR  = GLB_OPSUM_BASE;
            DMA_len       = imm[`GLB_ADDR_BITS-1:0];
            dma_busy_n    = 1'b1;
          end

          // ---------- STREAM G2P / P2G（先做骨架） ----------
          OP_G2P: begin
            // 這裡預期應該要拉 GLB -> PE 的搬運控制
            // 你可以依照 DATA_FLOW / MODE 決定要送 ifmap/weight/psum
            PEA_ifmap_valid = 1'b1;
            glb_busy_n      = 1'b1;
          end
          OP_P2G_OPSUM: begin
            PEA_opsum_ready = 1'b1;
            glb_busy_n      = 1'b1;
          end

          // ---------- CPT_INDEX / CPT_TAGXY ----------
          OP_CPT_INDEX: begin
            // 真正寫 REG 放到 always_ff
          end

          OP_CPT_TAGXY: begin
            // 真正更新 tagX/tagY 放到 always_ff
          end

          // ---------- COMPUTE / SET_ID ----------
          OP_COMPUTE: begin
            // 用 REG[7][2:0] 控制啟動哪些 row（參考你的 simulator）
            PE_en        = '1;         // 先全部開，之後再依 valid_e/PE_config 細分
            PE_config    = 11'd0;      // TODO: 由 REG[] 或 imm 產生
            pe_busy_n    = 1'b1;
          end

          OP_SET_ID: begin
            // 這個應該要把 XID/YID/LN config 打進 PE array
            // 這裡只先打個 pulse，資料從 REG 或 imm 來，之後你自己細化
            set_XID        = 1'b1;
            set_YID        = 1'b1;
            set_LN         = 1'b1;
          end

          // ---------- WAIT ----------
          OP_WAIT: begin
            // imm[1:0] 決定等誰: 0=GLB,1=DMA,2=PE
            unique case (imm[1:0])
              2'd0: if (glb_busy) pc_hold = 1'b1;
              2'd1: if (dma_busy) pc_hold = 1'b1;
              2'd2: if (pe_busy)  pc_hold = 1'b1;
              default: ;
            endcase
          end

          // ---------- JUMP ----------
          OP_JUMP: begin
            // 假設 PC module 看到 next_pc_sel=1 就用 imm 當 target
            next_pc_sel = 1'b1;
          end

          // ---------- LOOP ----------
          OP_LOOP: begin
            // 這裡只負責告訴 PC 要跳（或不跳）
            // 真正 counter 更新丟到 always_ff 去做（REG += offset, compare CSR）
            // 假設 imm[15:0] 裡面打包了 offset/target/csr_id/loopReg（你 decoder 要負責）
            // 這裡先簡單：if REG[loopReg] + offset < CSR[csr_id] 就跳
            // → 用 next_pc_sel=1 表示「用 target」，否則 pc+1

            // TODO: 這邊缺 rd/rs/loopReg/csr_id 的欄位，你要從 decoder 拉進來。
            // 我先全部留 0，不把 next_pc_sel 打開，避免亂跑。
            next_pc_sel = 1'b0;
          end

          // ---------- ALU (LOADI/ADDI/MULI/ADD/MUL) ----------
          OP_LOADI,
          OP_ADDI,
          OP_MULI,
          OP_ADD,
          OP_MUL: begin
            // 算術部分全部在 always_ff 寫 REG
          end

          // ---------- END ----------
          OP_END: begin
            state_n   = S_DONE;
          end

          default: begin
            // 非法 opcode，直接進 DONE 方便 debug
            state_n   = S_DONE;
          end

        endcase
      end // S_RUN

      S_DONE: begin
        // 等下一次 asic_en 重新啟動
        if (!asic_en) state_n = S_IDLE;
      end

    endcase
  end // always_comb

  // ----------------------------------
  // sequential: state / REG / CSR / TAG
  // ----------------------------------
  integer k;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state   <= S_IDLE;
      dma_busy <= 1'b0;
      glb_busy <= 1'b0;
      pe_busy  <= 1'b0;

      tagX_ifmap  <= '0; tagX_weight  <= '0; tagX_ipsum  <= '0; tagX_opsum  <= '0;
      tagY_ifmap  <= '0; tagY_weight  <= '0; tagY_ipsum  <= '0; tagY_opsum  <= '0;

      for (k = 0; k < REG_NUM; k++) begin
        regfile[k] <= 32'h0;
      end
      for (k = 0; k < CSR_NUM; k++) begin
        csr[k] <= 32'h0;
      end

    end else begin
      state    <= state_n;
      dma_busy <= dma_busy_n;
      glb_busy <= glb_busy_n;
      pe_busy  <= pe_busy_n;

      // REG[0] 永遠是 0（如果你要這種語意）
      regfile[0] <= 32'h0;

      // ------- 根據 opcode 寫 REG / CSR / TAG -------
      unique case (opcode)
        OP_CFG_SET: begin
          // 這裡依據「imm 裡的 type/csr_id」，寫入對應 MMIO 值
          // 現在先偷懶：假設 imm[3:0] 是 type，imm[7:4] 是 csr_id
          logic [3:0] type   = imm[3:0];
          logic [3:0] csr_id = imm[7:4];
          logic [31:0] value;
          unique case (type)
            4'd0:  value = DRAM_IFMAP_BASE;
            4'd1:  value = DRAM_WEIGHT_BASE;
            4'd2:  value = DRAM_OFMAP_BASE;
            4'd3:  value = {{(`GLB_ADDR_BITS-0){1'b0}}} | GLB_IFMAP_BASE;
            4'd4:  value = {{(`GLB_ADDR_BITS-0){1'b0}}} | GLB_WEIGHT_BASE;
            4'd5:  value = {{(`GLB_ADDR_BITS-0){1'b0}}} | GLB_OPSUM_BASE;
            4'd6:  value = {16'b0, OF_SIZE};
            4'd7:  value = {16'b0, IF_SIZE};
            4'd8:  value = {16'b0, B_SIZE};
            4'd9:  value = {16'b0, K_SIZE};
            4'd10: value = {16'b0, N_SIZE};
            4'd11: value = {16'b0, M_SIZE};
            4'd12: value = {31'b0, MODE};
            4'd13: value = {30'b0, DATA_FLOW};
            default: value = {28'b0, type};
          endcase
          csr[csr_id] <= value;
        end

        OP_CPT_TAGXY: begin
          // 這裡依據 imm 來更新 tagX/tagY，先做個簡單示範：
          // imm[1:0] type: 0 IFMAP, 1 WEIGHT, 2 IPSUM, 3 OPSUM
          // imm[7:2] X, imm[13:8] Y
          logic [1:0] t  = imm[1:0];
          logic [`XID_BITS-1:0] X = imm[7:2];
          logic [`YID_BITS-1:0] Y = imm[13:8];
          case (t)
            2'd0: begin tagX_ifmap <= X; tagY_ifmap <= Y; end
            2'd1: begin tagX_weight <= X; tagY_weight <= Y; end
            2'd2: begin tagX_ipsum <= X; tagY_ipsum <= Y; end
            2'd3: begin tagX_opsum <= X; tagY_opsum <= Y; end
          endcase
        end

        // ALU / LOOP / CPT_INDEX 這邊因為缺 rs/rd/loopReg/csr_id 資訊，先留空骨架
        OP_LOADI,
        OP_ADDI,
        OP_MULI,
        OP_ADD,
        OP_MUL,
        OP_CPT_INDEX,
        OP_LOOP: begin
          // TODO: 把 decoder 解出來的 rd/rs/loopReg/csr_id 拉進來，在這裡更新 regfile[]
        end

        default: ;
      endcase
    end
  end

endmodule : isa_controller
