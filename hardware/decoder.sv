`include "../include/ISA.svh"
module decoder(
    input logic [31:0] instr,
    output logic [3:0] csr_index,
    output logic [3:0] rs_index1,
    output logic [3:0] rs_index2,
    output logic [3:0] rd_index,
    output logic [31:0] imm,
    output logic [5:0] opcode,
    output logic [1:0] type,
    output logic [3:0] cfg_type
); 

always_comb begin
    opcode = instr[5:0];
    case (opcode)
        `OP_CFG_SET:begin
            type = 2'b0;
            cfg_type = instr[9:6];
            csr_index = instr[13:10];
            rs_index1 = 4'b0;
            rs_index2 = 4'b0;
            rd_index   = 4'b0;
            imm = 32'b0;

        end 
        `DMA_type,`STREAM_type: begin
            type = 2'b0;
            cfg_type = 4'b0;
            csr_index = instr[13:10];
            rs_index1 = 4'b0;
            rs_index2 = instr[9:6];
            rd_index   = 4'b0;
            imm = {14'b0,instr[31:14]};
        end 
        `OP_CPT_TAGXY,`OP_WAIT: begin
            type = instr[7:6];
            cfg_type = 4'b0;
            csr_index = 4'b0;
            rs_index1 = 4'b0;
            rs_index2 = 4'b0;
            rd_index   = 4'b0;
            imm = 32'b0;
        end
        `OP_JUMP:begin
            type = 2'b0;
            cfg_type = 4'b0;
            csr_index = 4'b0;
            rs_index1 = 4'b0;
            rs_index2 = 4'b0;
            rd_index   = 4'b0;
            imm = {6'b0,instr[31:6]};
        
        end 
        `OP_LOADI,`OP_ADDI,`OP_MULI: begin
            type = 2'b0;      
            cfg_type = 4'b0;
            csr_index = 4'b0;     
            rs_index1 = instr[9:6];
            rs_index2 = 4'b0;
            rd_index   = instr[13:10];
            imm = {14'b0,instr[31:14]};
        end
        `OP_ADD,`OP_MUL: begin
            type = 2'b0; 
            cfg_type = 4'b0;
            csr_index = 4'b0;          
            rs_index1 = instr[13:10];
            rs_index2 = instr[17:14];
            rd_index   =instr[9:6];
            imm = 32'b0;
        end
        `OP_LOOP:begin
            type = 2'b0;
            cfg_type = 4'b0;
            csr_index = instr[13:10];           
            rs_index1 = 4'b0;
            rs_index2 = instr[9:6];
            rd_index   = 4'b0;
            imm = { 14'b0,instr[31:14]};
        end 
        default:  result = 32'b0;






    endcase
end 




endmodule