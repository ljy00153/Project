`timescale 1ns/1ps

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

  // ----------------------------
  // Instantiate DUT
  // ----------------------------
  controller_top #(.PC_WIDTH(16)) dut (
    .clk(clk),
    .rst(rst),
    .asic_en(asic_en),
    .asic_done(asic_done),
    .im_init_en(im_init_en),
    .im_init_addr(im_init_addr),
    .im_init_wdata(im_init_wdata),
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

    .glb_done(glb_done)
  );

  // ---------------------------------------------------------
  // Helper: write one 32-bit instruction into DUT IM SRAM
  // NOTE: SRAM is byte-addressed, r_data is little-endian mapping:
  //   r_data[7:0]   = memory[addr]
  //   r_data[15:8]  = memory[addr+1]
  //   r_data[23:16] = memory[addr+2]
  //   r_data[31:24] = memory[addr+3]
  // ---------------------------------------------------------
  // ---------------------------------------------------------
// Loader: read 32-bit words (one per line) from hex file,
// then store into byte-addressed IM SRAM as little-endian.
// Format example per line: 00004061
// ---------------------------------------------------------
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

task automatic im_write32_port(input int unsigned byte_addr, input logic [31:0] word);
  begin
    im_init_en    <= 1'b1;
    im_init_addr  <= byte_addr[15:0];
    im_init_wdata <= word;
    @(negedge clk);
    im_init_en    <= 1'b0;
  end
endtask
  // ---------------------------------------------------------
  // Optional: dump waves
  // ---------------------------------------------------------
  initial begin
    $fsdbDumpfile("wave.fsdb");
    $fsdbDumpvars(0, controller_tb);   // 你的 TB module 名稱
    $fsdbDumpvars(0, dut);      // DUT instance（通常叫 dut）
    // 如果你要更狠：整棵設計都 dump
    $fsdbDumpvars(0, "+all");
  end


  // ---------------------------------------------------------
  // Test scenario
  // ---------------------------------------------------------
  logic [1023:0] hexfile;

  initial begin
   
    // defaults
    asic_en = 1'b0;
    glb_done = 1'b0;

    DRAM_ifmap_base  = 32'h0000_1000;
    DRAM_weight_base = 32'h0000_2000;
    DRAM_ofmap_base  = 32'h0000_3000;
    GLB_ifmap_base   = 32'h0000_4000;
    GLB_weight_base  = 32'h0000_5000;
    GLB_opsum_base   = 32'h0000_6000;

    OF_SIZE   = 32'd8192;
    IF_SIZE   = 32'd256;
    B_SIZE    = 32'd64;
    K_SIZE    = 32'd128;
    N_SIZE    = 32'd144;
    M_SIZE    = 32'd64;
    DATAFLOW  = 32'd0;
    im_init_en    = 1'b0;
    im_init_addr  = 16'd0;
    im_init_wdata = 32'd0;
    // reset
    rst = 1'b1;

    // 先決定 hex 檔名
    if (!$value$plusargs("HEX=%s", hexfile)) hexfile = "tb1.hex";
    $display("[TB] Using HEX file: %s", hexfile);

    // reset 期間灌 IM
    load_hex_words(hexfile);

    // 再放開 reset
    //repeat (2) @(negedge clk);
    im_init_en    = 1'b0;
    im_init_addr  = 16'b0;
    im_init_wdata = 32'b0;
    rst = 1'b0;

    // ---------------------------------------
    // Load instruction memory
    // ---------------------------------------
    
    


    // 讓 PC 跑一點
    repeat (2) @(posedge clk);

    // start controller
    asic_en = 1'b1;
    @(posedge clk);
    asic_en = 1'b0;

    // ---------------------------------------
    // 如果你的 signal_controller 會等 glb_done，就在這裡打一個 done pulse
    // ---------------------------------------
    /*
    repeat (30) @(posedge clk);
    glb_done = 1'b1;
    @(posedge clk);
    glb_done = 1'b0;
*/
    repeat (4) @(posedge clk);
        // wait for done (收到 asic_done 就停)
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
      $display("[%0t] PC=%0d  instr=%h  asic_done=%b",
               $time, dut.pc, dut.instr, asic_done);
    end
  end

endmodule
