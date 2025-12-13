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
    if (fd == 0) begin
      $fatal(1, "[TB] Cannot open %s", filename);
    end

    word_idx = 0;
    // fscanf 會自動跳過空白/換行，所以不需要處理空行
    while ($fscanf(fd, "%h", w) == 1) begin
      // little-endian mapping to byte memory
      dut.im.memory[word_idx*4 + 0] = w[7:0];
      dut.im.memory[word_idx*4 + 1] = w[15:8];
      dut.im.memory[word_idx*4 + 2] = w[23:16];
      dut.im.memory[word_idx*4 + 3] = w[31:24];
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
    $dumpfile("controller_tb.vcd");
    $dumpvars(0, dut);
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

    // reset
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    // ---------------------------------------
    // Load instruction memory
    // ---------------------------------------
    

    // Load instruction memory
    if (!$value$plusargs("HEX=%s", hexfile)) begin
      hexfile = "tb1.hex";   // 你的預設檔名
    end
    $display("[TB] Using HEX file: %s", hexfile);
    load_hex_words(hexfile);
    $display("[TB] IM bytes @0..15 = %02h %02h %02h %02h  %02h %02h %02h %02h  %02h %02h %02h %02h  %02h %02h %02h %02h",
  dut.im.memory[0], dut.im.memory[1], dut.im.memory[2], dut.im.memory[3],
  dut.im.memory[4], dut.im.memory[5], dut.im.memory[6], dut.im.memory[7],
  dut.im.memory[8], dut.im.memory[9], dut.im.memory[10],dut.im.memory[11],
  dut.im.memory[12],dut.im.memory[13],dut.im.memory[14],dut.im.memory[15]
);


    // 讓 PC 跑一點
    repeat (2) @(posedge clk);

    // start controller
    asic_en = 1'b1;
    @(posedge clk);
    asic_en = 1'b0;

    // ---------------------------------------
    // 如果你的 signal_controller 會等 glb_done，就在這裡打一個 done pulse
    // ---------------------------------------
    repeat (30) @(posedge clk);
    glb_done = 1'b1;
    @(posedge clk);
    glb_done = 1'b0;

    // wait for done (加個 timeout 避免卡死)
    fork
      begin
        wait (asic_done === 1'b1);
        $display("[%0t] asic_done asserted!", $time);
      end
      begin
        repeat (500) @(posedge clk);
        $display("[%0t] TIMEOUT: asic_done not asserted", $time);
      end
    join_any
    disable fork;

    repeat (10) @(posedge clk);
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
