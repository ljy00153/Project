`timescale 1ns/10ps
`include "AXI_define.svh"
`include "ASIC.svh"

`define CYCLE 10.0      // Cycle time
`define MAX 20000000    // Max cycle number

`define DRAM_ifmap_base 0
`define DRAM_weight_base 524288
`define DRAM_ofmap_base `DRAM_weight_base + 2097152
`define DRAM_ofmap_size 65536
logic [31:0] current_dram_addr = 32'h0; 

module test;
//***********************************************************************************
// Combinational Logic  
//***********************************************************************************
    logic [7:0] GOLDEN[`DRAM_ofmap_size];
    integer err_cnt;
    integer show_cnt;
    int unsigned ofmap_base;
    int start_time,finish_time;
    integer status;
    string  key;
    integer fs, num, gf, code;
    string prog_path;
    string hexfile;

//DRAM
    logic clk;
    logic rst_n;
    
    //WRIRE ADDRESS CHANNEL
    logic [`AXI_ID_BITS-1:0]    AWID;
    logic [`AXI_ADDR_BITS-1:0]  AWADDR;
    logic [7:0]                AWLEN;   // AXI4 LEN is 8 bits (0-255 beats)
    logic [2:0]                AWSIZE;  // 3'b010 = 4 bytes
    logic [1:0]                AWBURST; // 00:FIXED, 01:INCR, 10:WRAP
    logic                      AWVALID;
    logic                      AWREADY;

    //WRITE DATA CHANNEL
    logic [`AXI_DATA_BITS-1:0]  WDATA;
    logic [`AXI_STRB_BITS-1:0]  WSTRB;
    logic                      WLAST;
    logic                      WVALID;
    logic                      WREADY;

    //WRITE RESPONSE CHANNEL
    logic [`AXI_ID_BITS-1:0]    BID;
    logic [1:0]                BRESP;
    logic                      BVALID;
    logic                      BREADY;

    //READ ADDRESS CHANNEL
    logic [`AXI_ID_BITS-1:0]    ARID;
    logic [`AXI_ADDR_BITS-1:0]  ARADDR;
    logic [7:0]                ARLEN;
    logic [2:0]                ARSIZE;
    logic [1:0]                ARBURST;
    logic                      ARVALID;
    logic                      ARREADY;

    //READ DATA CHANNEL
    logic [`AXI_ID_BITS-1:0]    RID;
    logic [`AXI_DATA_BITS-1:0]  RDATA;
    logic [1:0]                RRESP;
    logic                      RLAST;
    logic                      RVALID;
    logic                      RREADY;

    // DUT
    logic asic_en;
    logic ASIC_interrupt;

    // IM init
    logic        im_init_en;
    logic [15:0] im_init_addr;
    logic [31:0] im_init_wdata;

    // ---- CONV-style CSR ----
    logic [31:0] ASIC_ENABLE;
    logic [31:0] ASIC_MAPPING_PARAM;
    logic [31:0] ASIC_SHAPE_PARAM1;
    logic [31:0] ASIC_SHAPE_PARAM2;
    logic [31:0] ASIC_IFMAP_ADDR;
    logic [31:0] ASIC_FILTER_ADDR;
    logic [31:0] ASIC_BIAS_ADDR;
    logic [31:0] ASIC_OPSUM_ADDR;
    logic [31:0] ASIC_GLB_FILTER_ADDR;
    logic [31:0] ASIC_GLB_OFMAP_ADDR;
    logic [31:0] ASIC_GLB_BIAS_ADDR;
    logic [31:0] ASIC_IFMAP_LEN;
    logic [31:0] ASIC_OFMAP_LEN;

    // ---- FC-style CSR ----
    logic [31:0] DRAM_ifmap_base;
    logic [31:0] DRAM_weight_base;
    logic [31:0] DRAM_ofmap_base;
    logic [31:0] GLB_ifmap_base;
    logic [31:0] GLB_weight_base;
    logic [31:0] GLB_opsum_base;
    logic [31:0] OF_SIZE, IF_SIZE, B_SIZE, K_SIZE, N_SIZE, M_SIZE, DATAFLOW;   
   
    

//***********************************************************************************
// clock generate
//***********************************************************************************
    always #(`CYCLE / 2) clk = ~clk;
//***********************************************************************************
// Instantiate
//***********************************************************************************
    DRAM u_dram(
    .clk(clk),
    .rst_n(rst_n),

    //WRIRE ADDRESS CHANNEL
    .AWID_S(AWID),
    .AWADDR_S(AWADDR),
    .AWLEN_S(AWLEN),   // AXI4 LEN is 8 bits (0-255 beats)
    .AWSIZE_S(AWSIZE),  // 3'b010 = 4 bytes
    .AWBURST_S(AWBURST), // 00:FIXED, 01:INCR, 10:WRAP
    .AWVALID_S(AWVALID),
    .AWREADY_S(AWREADY),

    //WRITE DATA CHANNEL
    .WDATA_S(WDATA),
    .WSTRB_S(WSTRB),
    .WLAST_S(WLAST),
    .WVALID_S(WVALID),
    .WREADY_S(WREADY),

    //WRITE RESPONSE CHANNEL
    .BID_S(BID),
    .BRESP_S(BRESP),
    .BVALID_S(BVALID),
    .BREADY_S(BREADY),

    //READ ADDRESS CHANNEL
    .ARID_S(ARID),
    .ARADDR_S(ARADDR),
    .ARLEN_S(ARLEN),
    .ARSIZE_S(ARSIZE),
    .ARBURST_S(ARBURST),
    .ARVALID_S(ARVALID),
    .ARREADY_S(ARREADY),

    //READ DATA CHANNEL
    .RID_S(RID),
    .RDATA_S(RDATA),
    .RRESP_S(RRESP),
    .RLAST_S(RLAST),
    .RVALID_S(RVALID),
    .RREADY_S(RREADY)
    );

    // -------------------------------------------------
    // DUT instance: asic_top (AXI Master)
    // -------------------------------------------------
    asic_top DUT (
        .ACLK        (clk),
        .ARESETn     (rst_n),
        .ASIC_interrupt (ASIC_interrupt),
        .asic_en (asic_en),
        // IM init
        .im_init_en     (im_init_en),
        .im_init_addr   (im_init_addr),
        .im_init_wdata  (im_init_wdata),

        // CONV-style CSR
        .ASIC_ENABLE          (ASIC_ENABLE),
        .ASIC_MAPPING_PARAM   (ASIC_MAPPING_PARAM),
        .ASIC_SHAPE_PARAM1    (ASIC_SHAPE_PARAM1),
        .ASIC_SHAPE_PARAM2    (ASIC_SHAPE_PARAM2),
        .ASIC_IFMAP_ADDR      (ASIC_IFMAP_ADDR),
        .ASIC_FILTER_ADDR     (ASIC_FILTER_ADDR),
        .ASIC_BIAS_ADDR       (ASIC_BIAS_ADDR),
        .ASIC_OPSUM_ADDR      (ASIC_OPSUM_ADDR),
        .ASIC_GLB_FILTER_ADDR (ASIC_GLB_FILTER_ADDR),
        .ASIC_GLB_OFMAP_ADDR  (ASIC_GLB_OFMAP_ADDR),
        .ASIC_GLB_BIAS_ADDR   (ASIC_GLB_BIAS_ADDR),
        .ASIC_IFMAP_LEN       (ASIC_IFMAP_LEN),
        .ASIC_OFMAP_LEN       (ASIC_OFMAP_LEN),

        // FC-style CSR
        .DRAM_ifmap_base   (DRAM_ifmap_base),
        .DRAM_weight_base  (DRAM_weight_base),
        .DRAM_ofmap_base   (DRAM_ofmap_base),
        .GLB_ifmap_base    (GLB_ifmap_base),
        .GLB_weight_base   (GLB_weight_base),
        .GLB_opsum_base    (GLB_opsum_base),
        .OF_SIZE           (OF_SIZE),
        .IF_SIZE           (IF_SIZE),
        .B_SIZE            (B_SIZE),
        .K_SIZE            (K_SIZE),
        .N_SIZE            (N_SIZE),
        .M_SIZE            (M_SIZE),
        .DATAFLOW          (DATAFLOW),

        // AXI Master <-> DRAM Slave wiring (share same TB signals)
        // WRITE ADDRESS
        .AWID_M      (AWID),
        .AWADDR_M    (AWADDR),
        .AWLEN_M     (AWLEN),
        .AWSIZE_M    (AWSIZE),
        .AWBURST_M   (AWBURST),
        .AWVALID_M   (AWVALID),
        .AWREADY_M   (AWREADY),

        // WRITE DATA
        .WDATA_M     (WDATA),
        .WSTRB_M     (WSTRB),
        .WLAST_M     (WLAST),
        .WVALID_M    (WVALID),
        .WREADY_M    (WREADY),

        // WRITE RESPONSE
        .BID_M       (BID),
        .BRESP_M     (BRESP),
        .BVALID_M    (BVALID),
        .BREADY_M    (BREADY),

        // READ ADDRESS
        .ARID_M      (ARID),
        .ARADDR_M    (ARADDR),
        .ARLEN_M     (ARLEN),
        .ARSIZE_M    (ARSIZE),
        .ARBURST_M   (ARBURST),
        .ARVALID_M   (ARVALID),
        .ARREADY_M   (ARREADY),

        // READ DATA
        .RID_M       (RID),
        .RDATA_M     (RDATA),
        .RRESP_M     (RRESP),
        .RLAST_M     (RLAST),
        .RVALID_M    (RVALID),
        .RREADY_M    (RREADY)
    );

//***********************************************************************************
// pattern generate
//***********************************************************************************
    //=================================================================
    // Simulation begin
    //=================================================================
    initial
    begin
        $value$plusargs("prog_path=%s", prog_path);
        clk = 0; 

        // default IM init idle
        im_init_en    = 1'b0;
        im_init_addr  = '0;
        im_init_wdata = '0;

        // ---- CSR init (先給保守值，不用的先清 0) ----
        ASIC_ENABLE          = 32'd0;
        ASIC_MAPPING_PARAM   = 32'd0;
        ASIC_SHAPE_PARAM1    = 32'd0;
        ASIC_SHAPE_PARAM2    = 32'd0;
        ASIC_IFMAP_ADDR      = 32'd0;
        ASIC_FILTER_ADDR     = 32'd0;
        ASIC_BIAS_ADDR       = 32'd0;
        ASIC_OPSUM_ADDR      = 32'd0;
        ASIC_GLB_FILTER_ADDR = 32'd0;
        ASIC_GLB_OFMAP_ADDR  = 32'd0;
        ASIC_GLB_BIAS_ADDR   = 32'd0;
        ASIC_IFMAP_LEN       = 32'd0;
        ASIC_OFMAP_LEN       = 32'd0;

        $display("Loading file: %s", {prog_path, "/shape.txt"});
        fs = $fopen({prog_path, "/shape.txt"}, "r");
        while (!$feof(fs)) 
        begin
            // 讀取格式為 "鍵: 值"
            $fscanf(fs, "%s %d\n", key, status);
            case (key)
                "IF_SIZE:": IF_SIZE = status;
                "OF_SIZE:": OF_SIZE = status;
                "B_SIZE:":  B_SIZE  = status;
                "K_SIZE:":  K_SIZE  = status;
                "N_SIZE:":  N_SIZE  = status;
                "M_SIZE:":  M_SIZE  = status;
            endcase
        end
        $fclose(fs);
        $display("IF_SIZE: %0d", IF_SIZE);
        $display("OF_SIZE: %0d", OF_SIZE);
        $display("B_SIZE: %0d", B_SIZE);
        $display("K_SIZE: %0d", K_SIZE);
        $display("N_SIZE: %0d", N_SIZE);
        $display("M_SIZE: %0d", M_SIZE);

        // GLB bases / sizes / dataflow：依你 controller 的需求填
        GLB_ifmap_base  = 0;
        GLB_weight_base = B_SIZE * K_SIZE * 12;
        GLB_opsum_base  = GLB_weight_base + N_SIZE * K_SIZE * 48;

        //data
        DRAM_ifmap_base   = current_dram_addr;
        load_hex_file({prog_path, "/A.txt"});
        DRAM_weight_base  = current_dram_addr;
        load_hex_file({prog_path, "/B.txt"});
        DRAM_ofmap_base   = current_dram_addr;
        load_hex_file({prog_path, "/ipsum.txt"});

        //read golden
        num = 0;
        $display("Loading file: %s", {prog_path, "/C_golden.txt"});
        gf = $fopen({prog_path, "/C_golden.txt"}, "r");
        while (!$feof(gf))
        begin
            code = $fscanf(gf, "%h\n", GOLDEN[num]);
            if (code == 1)
                num++;
            else
                break;
        end
        $fclose(gf);
        $display("Finished. Loaded %0d bytes.", num);

        

        // 灌指令
        // reset
        rst_n = 1'b0;

        // choose hex file
        // default: use assembler output in prog_path
        hexfile = {prog_path, "/GEMM_assembly.hex"};

        // optional override: +hexfile=xxx.hex (absolute or relative)
        if ($value$plusargs("hexfile=%s", hexfile)) begin
            $display("[TB] hexfile override: %s", hexfile);
        end else begin
            $display("[TB] hexfile default : %s", hexfile);
        end
        

        // load IM during reset
        load_hex_instruction(hexfile);

        // release reset
        @(negedge clk);
        rst_n = 1'b1;
        start_time = $realtime;
        $display("===========================");
        $display("[%0d] asic start!", start_time);
        $display("===========================\n");
        // start controller (1-cycle pulse)
        @(posedge clk);
        asic_en = 1'b1;
        @(posedge clk);
        asic_en = 1'b0;

         // wait for done
        wait (ASIC_interrupt === 1'b1);
        finish_time = $realtime;
        $display("===========================");
        $display("[%0d] asic_done asserted!", finish_time);
        $display("===========================\n");

        $display("===========================");
        $display("Cycle Count: %0d", (finish_time - start_time) / `CYCLE);
        $display("===========================\n");
        // compare result
        compare_ofmap_with_golden();

        $fsdbDumpflush;

        // 如果想讓 regression 看 exit code：
        if (err_cnt == 0) $finish;
        else $fatal(1, "[TB] Result mismatch!");


    end

   
//***********************************************************************************
// Waveform Display
//***********************************************************************************
    initial 
    begin
        `ifdef FSDB
            $fsdbDumpfile("top.fsdb");
            $fsdbDumpvars(0, test);
        `elsif FSDB_ALL
            $fsdbDumpfile("top.fsdb");
            $fsdbDumpvars("+struct", "+mda", test);
        `endif

        #(`CYCLE*`MAX);
        $display("\n==========================================================================================\n");
        $display("SIMULATION TIMEOUT after %d cycles", `MAX);
        $finish;
    end


// --- 聰明的載入 Task ---
    task load_hex_file(input string filename);
        integer fd;
        integer count;
        logic [7:0] data; // 每次讀 1 byte
        integer status;
        integer flag = 0;

        fd = $fopen(filename, "r"); // 開啟檔案 (Read mode)
        
        if (fd == 0) begin
            $display("[Error] Cannot open file: %s", filename);
        end else begin
            count = 0;
            $display("---------------------------------------");
            $display("Loading file: %s at address 0x%h", filename, current_dram_addr);
            
            // 使用 $fscanf 讀取 Hex (%h)，它會自動跳過換行符號
            while (!$feof(fd)) begin
                status = $fscanf(fd, "%h", data);
                if (status == 1) begin
                    // 寫入你的 DRAM instance (假設你的 instance 名稱叫 u_dram)
                    u_dram.mem[current_dram_addr] = data; 
                    if(flag == 0) begin
                        $display("First element: 0x%0h", u_dram.mem[current_dram_addr]);
                        flag = 1;
                    end
                    // 地址往後推 1 byte
                    current_dram_addr++; 
                    count++;
                end
            end
            $display("0 element: 0x%0h", u_dram.mem[0]);
        
             
            flag = 0;
            $display("Last element: 0x%0h\n", u_dram.mem[current_dram_addr-1]);
            $fclose(fd);
            $display("Finished. Loaded %0d bytes.", count);
            $display("Next file will start at address 0x%h", current_dram_addr);
            $display("---------------------------------------");
        end
    endtask


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

    task automatic load_hex_instruction(input logic [1023:0] filename);
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
        $display("[TB] Loaded %0d words from %0s", word_idx, filename);
        end
    endtask
    task automatic compare_ofmap_with_golden;
        int unsigned i;
        logic [7:0] dut_b, ref_b;
        integer log_fd;        // 檔案描述符
        string log_filename;   // 檔案名稱
        begin
            err_cnt  = 0;
            show_cnt = 0;
            ofmap_base = DRAM_ofmap_base;

            // 設定 log 檔案路徑
            log_filename = {prog_path, "/verification.log"};
            log_fd = $fopen(log_filename, "w");

            if (log_fd == 0) begin
                $display("[TB] Error: Cannot open log file %s", log_filename);
                $finish;
            end

            // Console 提示
            $display("===========================");
            $display("[TB] Checking Result... Full report (Pass & Fail) saved to: %s", log_filename);
            $display("===========================");
            // 寫入 Log Header
            $fdisplay(log_fd, "--------------------------------------------------");
            $fdisplay(log_fd, "[TB] Compare DRAM OFMAP vs GOLDEN");
            $fdisplay(log_fd, "[TB] ofmap_base = 0x%08h, bytes = %0d", ofmap_base, num);
            $fdisplay(log_fd, "--------------------------------------------------");
            $fdisplay(log_fd, "Result | Index | Address    | DUT  | Golden");
            $fdisplay(log_fd, "-------|-------|------------|------|-------");

            for (i = 0; i < num; i++) begin
                dut_b = u_dram.mem[ofmap_base + i];
                ref_b = GOLDEN[i];

                if (dut_b !== ref_b) begin
                    // === 錯誤 (MISMATCH) ===
                    err_cnt++;
                    
                    // 1. 寫入 Log (標記為 [MIS])
                    $fdisplay(log_fd, "[MIS]  | %5d | 0x%08h | 0x%02h | 0x%02h", 
                                i, (ofmap_base + i), dut_b, ref_b);

                    // 2. 顯示在 Console (只顯示前 20 筆錯誤，避免洗版)
                    if (show_cnt < 20) begin
                        $display("[MIS] i=%0d addr=0x%08h dut=0x%02h ref=0x%02h",
                                    i, (ofmap_base + i), dut_b, ref_b);
                        show_cnt++;
                    end

                end else begin
                    // === 正確 (MATCH) ===
                    // 這裡只寫入 Log，不要 print 到 Console，不然跑 simulation 會很慢且畫面很亂
                    $fdisplay(log_fd, "[OK ]  | %5d | 0x%08h | 0x%02h | 0x%02h", 
                                i, (ofmap_base + i), dut_b, ref_b);
                end
            end

            // 寫入總結到 Log
            $fdisplay(log_fd, "--------------------------------------------------");
            if (err_cnt == 0) begin
                $fdisplay(log_fd, "[PASS] All %0d bytes matched.", num);
                $display("===========================");
                $display("[PASS] OFMAP matches GOLDEN! (See %s)", log_filename);
                $display("===========================");
            end else begin
                $fdisplay(log_fd, "[FAIL] Total errors: %0d / %0d", err_cnt, num);
                $display("===========================");
                $display("[FAIL] OFMAP mismatch! errors=%0d. Check %s for details.", err_cnt, log_filename);
                $display("===========================");
            end
            $fdisplay(log_fd, "--------------------------------------------------");

            // 關閉檔案
            $fclose(log_fd);
            $display("===========================");
            $display("[TB] Checking Result Finished");
            $display("===========================");
        end
    endtask

endmodule