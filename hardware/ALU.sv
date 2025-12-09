`include "../include/ISA.svh"

module ALU{
    input  [31:0] rs1_src,
    input  [31:0] rs2_src,
    input  [5:0] opcode,
    output logic [31:0] result,
};
always_comb begin
    case (opcode)
        `DMA_type,`STREAM_type,`OP_ADD,`OP_ADDI: begin
            result = rs1_src + rs2_src;
        end 
        `OP_MULI: begin
            result = rs1_src[15:0] * rs2_src[15:0];
        end
        `OP_LOOP:begin
            result = {31'b0,!(rs2_src<rs1_src)}; //小於的話不跳轉   

        end 
        default:  result = 32'b0;
    endcase
end

endmodule