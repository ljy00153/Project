`timescale 1ns/1ps
`include "../include/ISA.svh"
`include "../include/ASIC.svh"
`include "../include/AXI_define.svh"

module controller_tb;

  // ----------------------------
  // clk / rst
  // ----------------------------
  logic clk;
  logic rst;

  initial clk = 1'b0;
  always #5 clk = ~clk;   // 100MHz

  // ----------------------------
  // DUT inputs/outputs
  // ----------------------------
  logic asic_en;
  logic asic_done;
  logic        im_init_en;
  logic [15:0] im_init_addr;
  logic [31:0] im_init_wdata;

  logic [31:0] DRAM_ifmap_base;
  logic [31:0] DRAM_weight_base;
  logic [31:0] DRAM_ofmap_base;
  logic [31:0] GLB_ifmap_base;
  logic [31:0] GLB_weight_base;
  logic [31:0] GLB_opsum_base;
  logic [31:0] OF_SIZE, IF_SIZE, B_SIZE, K_SIZE, N_SIZE, M_SIZE, DATAFLOW;

  logic glb_done;

  // ============================================================
  // GLB control
  // ============================================================
  logic GLB_EN;
  logic GLB_WEB;
  logic GLB_MODE;
  // ============================================================
  // GLB addr / mux selects (missing declarations!)
  // ============================================================
  logic [`GLB_ADDR_BITS-1:0] GLB_ADDR;
  logic GLB_DI_select;
  logic GLB_DO_select;
  logic GLB_mux;

  // ============================================================
  // PEA enables/config (missing declarations!)
  // ============================================================
  logic [`PE_ARRAY_H*`PE_ARRAY_W-1:0] PE_en;
  logic [10:0]                        PE_config;
  // ============================================================
  // PEA XID scan
  // ============================================================
  logic                        set_XID;
  logic [`XID_BITS-1:0]        ifmap_XID_scan_in;
  logic [`XID_BITS-1:0]        weight_XID_scan_in;
  logic [`XID_BITS-1:0]        ipsum_XID_scan_in;
  logic [`XID_BITS-1:0]        opsum_XID_scan_in;

  // ============================================================
  // PEA YID scan
  // ============================================================
  logic                        set_YID;
  logic [`YID_BITS-1:0]        ifmap_YID_scan_in;
  logic [`YID_BITS-1:0]        weight_YID_scan_in;
  logic [`YID_BITS-1:0]        ipsum_YID_scan_in;
  logic [`YID_BITS-1:0]        opsum_YID_scan_in;

  // ============================================================
  // PEA LN config
  // ============================================================
  logic                        set_LN;
  logic [`PE_ARRAY_H-2:0]      LN_config_in;

  // ============================================================
  // PEA ifmap handshake + tag
  // ============================================================
  logic                        PEA_ifmap_valid;
  logic                        PEA_ifmap_ready;
  logic [`XID_BITS-1:0]        ifmap_tag_X;
  logic [`YID_BITS-1:0]        ifmap_tag_Y;

  // ============================================================
  // PEA weight handshake + tag
  // ============================================================
  logic                        PEA_weight_valid;
  logic                        PEA_weight_ready;
  logic [`XID_BITS-1:0]        weight_tag_X;
  logic [`YID_BITS-1:0]        weight_tag_Y;

  // ============================================================
  // PEA ipsum handshake + tag
  // ============================================================
  logic                        PEA_ipsum_valid;
  logic                        PEA_ipsum_ready;
  logic [`XID_BITS-1:0]        ipsum_tag_X;
  logic [`YID_BITS-1:0]        ipsum_tag_Y;

  // ============================================================
  // PEA opsum handshake + tag
  // ============================================================
  logic                        PEA_opsum_valid;
  logic                        PEA_opsum_ready;
  logic [`XID_BITS-1:0]        opsum_tag_X;
  logic [`YID_BITS-1:0]        opsum_tag_Y;

  // ============================================================
  // DMA interface (from DUT)
  // ============================================================
  logic                      DMA_EN;
  logic [1:0]                DMA_mode;
  logic [`AXI_ADDR_BITS-1:0] DMA_DRAM_ADDR;
  logic [`GLB_ADDR_BITS-1:0] DMA_GLB_ADDR;
  logic [`GLB_ADDR_BITS-1:0] DMA_len;
  logic [1:0]                DMA_BYTE_BIAS;
  logic                      DMA_done;

  // ----------------------------
  // Instantiate DUT
  // ----------------------------
  controller_top #(.PC_WIDTH(16)) dut (
    .clk(clk),
    .rst(rst),
    .asic_en(asic_en),
    .asic_done(asic_done),

    // instruction write from tb
    .im_init_en(im_init_en),
    .im_init_addr(im_init_addr),
    .im_init_wdata(im_init_wdata),

    // MMIO
    .DRAM_ifmap_base(DRAM_ifmap_base),
    .DRAM_weight_base(DRAM_weight_base),
    .DRAM_ofmap_base(DRAM_ofmap_base),
    .GLB_ifmap_base(GLB_ifmap_base),
    .GLB_weight_base(GLB_weight_base),
    .GLB_opsum_base(GLB_opsum_base),
    .OF_SIZE(OF_SIZE),
    .IF_SIZE(IF_SIZE),
    .B_SIZE(B_SIZE),
    .K_SIZE(K_SIZE),
    .N_SIZE(N_SIZE),
    .M_SIZE(M_SIZE),
    .DATAFLOW(DATAFLOW),

    // GLB control
    .GLB_EN                (GLB_EN),
    .GLB_WEB               (GLB_WEB),
    .GLB_MODE              (GLB_MODE),
    .GLB_ADDR              (GLB_ADDR),

    .PE_en (PE_en),
    .PE_config(PE_config),
    // PEA XID scan
    .set_XID               (set_XID),
    .ifmap_XID_scan_in     (ifmap_XID_scan_in),
    .weight_XID_scan_in    (weight_XID_scan_in),
    .ipsum_XID_scan_in     (ipsum_XID_scan_in),
    .opsum_XID_scan_in     (opsum_XID_scan_in),

    // PEA YID scan
    .set_YID               (set_YID),
    .ifmap_YID_scan_in     (ifmap_YID_scan_in),
    .weight_YID_scan_in    (weight_YID_scan_in),
    .ipsum_YID_scan_in     (ipsum_YID_scan_in),
    .opsum_YID_scan_in     (opsum_YID_scan_in),

    // PEA LN config
    .set_LN                (set_LN),
    .LN_config_in          (LN_config_in),

    // PEA ifmap handshake + tag
    .PEA_ifmap_valid       (PEA_ifmap_valid),
    .PEA_ifmap_ready       (PEA_ifmap_ready),
    .ifmap_tag_X           (ifmap_tag_X),
    .ifmap_tag_Y           (ifmap_tag_Y),

    // PEA weight handshake + tag
    .PEA_weight_valid      (PEA_weight_valid),
    .PEA_weight_ready      (PEA_weight_ready),
    .weight_tag_X          (weight_tag_X),
    .weight_tag_Y          (weight_tag_Y),

    // PEA ipsum handshake + tag
    .PEA_ipsum_valid       (PEA_ipsum_valid),
    .PEA_ipsum_ready       (PEA_ipsum_ready),
    .ipsum_tag_X           (ipsum_tag_X),
    .ipsum_tag_Y           (ipsum_tag_Y),

    // PEA opsum handshake + tag
    .PEA_opsum_valid       (PEA_opsum_valid),
    .PEA_opsum_ready       (PEA_opsum_ready),
    .opsum_tag_X           (opsum_tag_X),
    .opsum_tag_Y           (opsum_tag_Y),

    // DMA
    .DMA_en(DMA_EN),
    .DMA_mode(DMA_mode),
    .DMA_DRAM_ADDR(DMA_DRAM_ADDR),
    .DMA_GLB_ADDR(DMA_GLB_ADDR),
    .DMA_BYTE_BIAS(DMA_BYTE_BIAS),
    .DMA_len(DMA_len),
    .DMA_done(DMA_done),

    .GLB_DI_select(GLB_DI_select),
    .GLB_DO_select(GLB_DO_select),
    .GLB_mux(GLB_mux)
  );

  // ---------------------------------------------------------
  // IM loader helpers
  // ---------------------------------------------------------
  task automatic im_write32_port(input int unsigned byte_addr, input logic [31:0] word);
    begin
      im_init_en    <= 1'b1;
      im_init_addr  <= byte_addr[15:0];
      im_init_wdata <= word;
      @(negedge clk);
      im_init_en    <= 1'b0;
    end
  endtask

  task automatic load_hex_words(input logic [1023:0] filename);
    int fd;
    int word_idx;
    logic [31:0] w;
    begin
      fd = $fopen(filename, "r");
      if (fd == 0) $fatal(1, "[TB] Cannot open %s", filename);

      word_idx = 0;
      while ($fscanf(fd, "%h", w) == 1) begin
        im_write32_port(word_idx*4, w);  // byte address = word_idx*4
        word_idx++;
      end

      $fclose(fd);
      $display("[TB] Loaded %0d words from %s", word_idx, filename);
    end
  endtask

  // ---------------------------------------------------------
  // Optional: dump waves
  // ---------------------------------------------------------
  initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0, controller_tb);
    $fsdbDumpvars(0, dut);
    $fsdbDumpvars(0, "+all");
  end

  // ---------------------------------------------------------
  // DMA stub: generate DMA_done pulse based on DMA_len
  //   - When DMA_EN rises: start counting
  //   - Each cycle counts as "1 unit" transfer (toy model)
  //   - When count reaches DMA_len: pulse done for 1 cycle
  // ---------------------------------------------------------
  logic DMA_EN_d;           // delay one cycle
  logic dma_active;         // DMA busy flag
  int unsigned dma_cnt;
  always_ff @(posedge clk) begin
  if (rst) begin
    DMA_EN_d   <= 1'b0;
    dma_active <= 1'b0;
    dma_cnt    <= 0;
    DMA_done   <= 1'b0;
  end else begin
    // default
    DMA_done <= 1'b0;

    // record previous DMA_EN
    DMA_EN_d <= DMA_EN;

    // --------------------------------------------------
    // detect DMA start pulse (0 -> 1)
    // --------------------------------------------------
    if (DMA_EN && !DMA_EN_d) begin
      dma_active <= 1'b1;
      dma_cnt    <= 0;
    end

    // --------------------------------------------------
    // DMA active: count transfers
    // --------------------------------------------------
    if (dma_active) begin
      if (DMA_len == 0) begin
        // corner case: zero length
        DMA_done   <= 1'b1;
        dma_active <= 1'b0;
      end
      else if (dma_cnt < DMA_len - 1) begin
        dma_cnt <= dma_cnt + 1;
      end
      else begin
        // finished
        DMA_done   <= 1'b1;   // 1-cycle pulse
        dma_active <= 1'b0;
        dma_cnt    <= 0;
      end
    end
  end
end


  // ---------------------------------------------------------
  // Test scenario
  // ---------------------------------------------------------
  logic [1023:0] hexfile;

  initial begin
    // defaults
    asic_en   = 1'b0;
    glb_done  = 1'b0;

    // default MMIO
    DRAM_ifmap_base  = 32'h0000_1000;
    DRAM_weight_base = 32'h0000_2000;
    DRAM_ofmap_base  = 32'h0000_3000;
    GLB_ifmap_base   = 32'h0000_4000;
    GLB_weight_base  = 32'h0000_5000;
    GLB_opsum_base   = 32'h0000_6000;

    OF_SIZE   = 32'd256;
    IF_SIZE   = 32'd8192;
    B_SIZE    = 32'd64;
    K_SIZE    = 32'd12;
    N_SIZE    = 32'd32;
    M_SIZE    = 32'd64;
    DATAFLOW  = 32'd0;

    // init ports
    im_init_en    = 1'b0;
    im_init_addr  = 16'd0;
    im_init_wdata = 32'd0;

    // default handshakes (avoid X)
    PEA_ifmap_ready  = 1'b1;
    PEA_weight_ready = 1'b1;
    PEA_ipsum_ready  = 1'b1;
    PEA_opsum_valid  = 1'b1;

    // If DUT expects *_valid from TB, set them too (your original had opsum_valid=1)
 

    // reset
    rst = 1'b1;

    // choose hex file
    if (!$value$plusargs("HEX=%s", hexfile)) hexfile = "tb1.hex";
    $display("[TB] Using HEX file: %s", hexfile);

    // load IM during reset
    load_hex_words(hexfile);

    // release reset
    @(negedge clk);
    rst = 1'b0;

    // start controller (1-cycle pulse)
    @(posedge clk);
    asic_en = 1'b1;
    @(posedge clk);
    asic_en = 1'b0;

    // wait for done
    wait (asic_done === 1'b1);
    $display("[%0t] asic_done asserted! stop simulation.", $time);
    $fsdbDumpflush;
    $finish;
  end

  // ---------------------------------------------------------
  // Simple monitors
  // ---------------------------------------------------------
  always @(posedge clk) begin
    if (!rst) begin
      $display("[%0t] PC=%0d  instr=%h  asic_done=%b  DMA_EN=%b DMA_len=%0d DMA_done=%b",
               $time, dut.pc, dut.instr, asic_done, DMA_EN, DMA_len, DMA_done);
    end
  end

endmodule
