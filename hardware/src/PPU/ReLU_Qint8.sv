`include "define.svh"


module ReLU_Qint8 (
    input [7:0] data_in,
    input relu_en,
    output logic [7:0] data_out
);
    logic [7:0] relu_out;
    always_comb begin
        relu_out = (data_in[7])?data_in:8'd128; // uint8 (zero point)
        data_out = (relu_en)?(relu_out):data_in;
    end

endmodule
