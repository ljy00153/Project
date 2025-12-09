module SRAM(
    input clk,
    input w_en,
    input [15:0] addr,
    input [31:0] w_data,
    output logic [31:0] r_data
);
reg [7:0] memory [0:65535]; // 64KB SRAM
always_comb begin
    r_data[7:0] = memory[addr];
    r_data[15:8] = memory[addr + 1];
    r_data[23:16] = memory[addr + 2];   
    r_data[31:24] = memory[addr + 3];
end

always_ff @(posedge clk) begin
    if (w_en) begin
        memory[addr] <= w_data[7:0];
        memory[addr + 1] <= w_data[15:8];
        memory[addr + 2] <= w_data[23:16];
        memory[addr + 3] <= w_data[31:24];
    end
    else begin
        memory[addr] <= memory[addr];
        memory[addr + 1] <= memory[addr + 1];
        memory[addr + 2] <= memory[addr + 2];
        memory[addr + 3] <= memory[addr + 3];
    end
end


endmodule