module decoder(
    input logic [13:0] instr,
    output logic [3:0] rs_idx,
    output logic [3:0] rd_idx,
    output logic [5:0] opcode
); 

assign rs_idx = instr[13:10];
assign rd_idx = instr[9:6];
assign opcode = instr[5:0];

endmodule