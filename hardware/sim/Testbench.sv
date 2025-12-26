`timescale 1ns/10ps
`include "DRAM.sv"
`include "../src/top.sv"

`define CYCLE 10.0      // Cycle time
`define MAX 10000    // Max cycle number

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
    integer num, gf, code;
    string prog_path;

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

    asic_top DUT(

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
        rst_n = 0;
        #(`CYCLE) rst_n = 1;

        //data
        load_hex_file({prog_path, "/A.txt"});
        load_hex_file({prog_path, "/B.txt"});
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
            flag = 0;
            $display("Last element: 0x%0h\n", u_dram.mem[current_dram_addr-1]);
            $fclose(fd);
            $display("Finished. Loaded %0d bytes.", count);
            $display("Next file will start at address 0x%h", current_dram_addr);
            $display("---------------------------------------");
        end
    endtask

endmodule