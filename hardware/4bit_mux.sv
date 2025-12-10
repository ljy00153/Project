module 4bit_mux(
    input logic [3:0] sel,
    input logic [31:0] DRAM_ifmap_base,
    input logic [31:0] DRAM_weight_base,
    input logic [31:0] DRAM_ofmap_base,
    input logic [31:0] GLB_ifmap_base,
    input logic [31:0] GLB_weight_base,
    input logic [31:0] GLB_opsum_base,
    input logic [31:0] OF_SIZE,
    input logic [31:0] IF_SIZE,
    input logic [31:0] B_SIZE,
    input logic [31:0] K_SIZE,
    input logic [31:0] N_SIZE,
    input logic [31:0] M_SIZE,
    input logic [31:0] DATAFLOW,
    output logic [31:0] out
);

    always_comb begin
        case (sel)
            4'b0000: out = DRAM_ifmap_base;
            4'b0001: out = DRAM_weight_base;
            4'b0010: out = DRAM_ofmap_base;
            4'b0011: out = GLB_ifmap_base;
            4'b0100: out = GLB_weight_base;
            4'b0101: out = GLB_opsum_base;
            4'b0110: out = OF_size;
            4'b0111: out = IF_size;
            4'b1000: out = B_SIZE;
            4'b1001: out = K_SIZE;
            4'b1010: out = N_SIZE;
            4'b1011: out = M_SIZE;
            4'b1100: out = DATAFLOW;
            default: out = 32'b0;
        endcase
    end

endmodule