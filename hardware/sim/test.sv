`timescale 1ns/10ps
`include "../src/ID_SENDER.sv"

`define CYCLE 10.0      // Cycle time
`define MAX 10000    // Max cycle number
`define XID_BITS 32
`define YID_BITS 32
`define PE_ARRAY_W 8 
`define PE_ARRAY_H 6

module test;
//***********************************************************************************
// Combinational Logic  
//***********************************************************************************
    logic clk;
    logic rst;
    logic en;
    logic [1:0] tag_type;
    logic                  set_XID;
    logic [`XID_BITS-1:0]  ifmap_XID_scan_in;
    logic [`XID_BITS-1:0]  weight_XID_scan_in;//weight
    logic [`XID_BITS-1:0]  ipsum_XID_scan_in;
    logic [`XID_BITS-1:0]  opsum_XID_scan_in;
    logic                  set_YID;
    logic [`YID_BITS-1:0]  ifmap_YID_scan_in;
    logic [`YID_BITS-1:0]  filter_YID_scan_in;
    logic [`YID_BITS-1:0]  ipsum_YID_scan_in;
    logic [`YID_BITS-1:0]  opsum_YID_scan_in;
    logic                  set_LN;
    logic [`PE_ARRAY_H-2:0] LN_config_in;

    //send tag
    logic PEA_ifmap_valid;
    logic PEA_ifmap_ready;
    logic [`XID_BITS-1:0]  ifmap_tag_X;
    logic [`YID_BITS-1:0]  ifmap_tag_Y;
    logic PEA_weight_valid;
    logic PEA_weight_ready;
    logic [`XID_BITS-1:0]  weight_tag_X;
    logic [`YID_BITS-1:0]  weight_tag_Y;
    logic PEA_ipsum_valid;
    logic PEA_ipsum_ready;
    logic [`XID_BITS-1:0]  ipsum_tag_X;
    logic [`YID_BITS-1:0]  ipsum_tag_Y;
    logic PEA_opsum_valid;
    logic PEA_opsum_ready;
    logic [`XID_BITS-1:0]  opsum_tag_X;
    logic [`YID_BITS-1:0]  opsum_tag_Y;



//***********************************************************************************
// clock generate
//***********************************************************************************
always #(`CYCLE / 2) clk = ~clk;
//***********************************************************************************
// Instantiate
//***********************************************************************************
    ID_SENDER DUT(
        .clk(clk),
        .rst(rst),
        .en(en),
        //input  mode,//1-6
        .tag_type(tag_type),
        //input  [2:0]valid_e,
        .set_XID(set_XID),
        .ifmap_XID_scan_in(ifmap_XID_scan_in),
        .weight_XID_scan_in(weight_XID_scan_in),//weight
        .ipsum_XID_scan_in(ipsum_XID_scan_in),
        .opsum_XID_scan_in(opsum_XID_scan_in),
        .set_YID(set_YID),
        .ifmap_YID_scan_in(ifmap_YID_scan_in),
        .weight_YID_scan_in(weight_YID_scan_in),
        .ipsum_YID_scan_in(ipsum_YID_scan_in),
        .opsum_YID_scan_in(opsum_YID_scan_in),
        .set_LN(set_LN),
        .LN_config_in(LN_config_in),
        
        .PEA_ifmap_valid(PEA_ifmap_valid),
        .PEA_ifmap_ready(PEA_ifmap_ready),
        .ifmap_tag_X(ifmap_tag_X),
        .ifmap_tag_Y(ifmap_tag_Y),

        .PEA_weight_valid(PEA_weight_valid),
        .PEA_weight_ready(PEA_weight_ready),
        .weight_tag_X(weight_tag_X),
        .weight_tag_Y(weight_tag_Y),

        .PEA_ipsum_valid(PEA_ipsum_valid),
        .PEA_ipsum_ready(PEA_ipsum_ready),
        .ipsum_tag_X(ipsum_tag_X),
        .ipsum_tag_Y(ipsum_tag_Y),

        .PEA_opsum_valid(PEA_opsum_valid),
        .PEA_opsum_ready(PEA_opsum_ready),
        .opsum_tag_X(opsum_tag_X),
        .opsum_tag_Y(opsum_tag_Y)
    );
//***********************************************************************************
// pattern generate
//***********************************************************************************
  initial
    begin
        clk = 1;
        rst = 1;
        en = 0;
        PEA_ifmap_ready = 0;
        PEA_weight_ready = 0;
        PEA_ipsum_ready = 0;
        PEA_opsum_valid = 0;
        #`CYCLE rst = 0;
        
        
        #(`CYCLE + 1) en = 1;  
        #(`CYCLE + 1) en = 0;  
        #`MAX $finish;
   end

    initial
    begin
        #(551);
        for(integer i = 0; i < 6; i = i + 1)
        begin
            PEA_ifmap_ready = 1;
            en = 1;
            tag_type = 2'd0;
            #`CYCLE;
            en = 0;
        end
        PEA_ifmap_ready = 0;
        #`CYCLE;
        for(integer i = 0; i < 12*48; i = i + 1)
        begin
            PEA_weight_ready = 1;
            en = 1;
            tag_type = 2'd1;
            #`CYCLE;
            en = 0;
        end
        PEA_weight_ready = 0;
        #`CYCLE;
        for(integer i = 0; i < 32; i = i + 1)
        begin
            PEA_ipsum_ready = 1;
            en = 1;
            tag_type = 2'd2;
            #`CYCLE;
            en = 0;
        end
        PEA_ipsum_ready = 0;
        #`CYCLE;
        for(integer i = 0; i < 32; i = i + 1)
        begin
            PEA_opsum_valid = 1;
            en = 1;
            tag_type = 2'd3;
            #`CYCLE;
            en = 0;
        end
        PEA_opsum_valid = 0;
   end
   
   
//***********************************************************************************
// Waveform Display
//***********************************************************************************
initial 
begin
    `ifdef FSDB
        $fsdbDumpfile("test.fsdb");
        $fsdbDumpvars(0, DUT);
    `elsif FSDB_ALL
        $fsdbDumpfile("test.fsdb");
        $fsdbDumpvars("+struct", "+mda", DUT);
    `endif
end




endmodule
