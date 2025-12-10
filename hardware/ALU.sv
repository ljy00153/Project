`include "../include/ISA.svh"

module ALU{
    input  [31:0] rs1_src,
    input  [31:0] rs2_src,
    input  [5:0] opcode,
    input  [31:0] loop_reg_src,
    output logic [31:0] result,
    output logic branch_result
};
always_comb begin
    case (opcode)
        `OP_DMA_LOAD_IFMAP,`OP_DMA_LOAD_WEIGHT,`OP_DMA_LOAD_PSUM,`OP_DMA_STORE_OFMAP,`OP_G2P,`OP_P2G_OPSUM,`OP_ADD,`OP_ADDI: begin
            result = rs1_src + rs2_src;
        end 
        `OP_MULI: begin
            result = rs1_src[15:0] * rs2_src[15:0];
        end
        `OP_LOOP:begin
            branch_result = (loop_reg_src<rs1_src); //小於的話branch
            if(branch_result) begin
                result = loop_reg_src + rs2_src; //branch taken , loop_reg + offset
            end else begin
                result = 32'b0; // branch not taken,pc+4,loop reg 歸零
            end
        end 
        'OP_COMPUTE: begin
            result = rs2_src; // no ALU operation
        end
        default:  result = 32'b0;
    endcase
end

endmodule