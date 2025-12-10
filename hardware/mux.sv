module mux (
    input logic  sel,
    input logic [31:0] in0,
    input logic [31:0] in1,

    output logic [31:0] out
);

    always_comb begin
        case (sel)
            0: out = in0;
            1: out = in1;
        endcase
    end