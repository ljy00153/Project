module Regfile(
    input logic clk,
    input logic rst,
    //write port
    input logic wb_en,
    input logic [3:0] rd_index,
    input logic [31:0] wdata,
    //read port 1
    input logic [3:0] rs1_index,
    output logic [31:0] rdata1,
    //read port 2
    input logic [3:0] rs2_index,
    output logic [31:0] rdata2
);
    reg [31:0] regfile [0:15]; // 16 registers of 32 bits

    always_comb begin 
        rdata1 = regfile[rs1_index];
        rdata2 = regfile[rs2_index];
    end

    
    always_ff @( posedge clk ) begin 
        if ( rst ) begin
            // reset all registers to 0
            for ( int i = 0; i < 16; i++ ) begin
                regfile[i] <= 32'b0;
            end
        end else if ( wb_en ) begin
            regfile[rd_index] <= wdata;
        end else begin 
            regfile[rd_index] <= regfile[rd_index]; // hold value
        end
    end
    
endmodule