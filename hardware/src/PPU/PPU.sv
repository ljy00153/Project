

module PPU (
    input clk,
    input rst,
    input [`DATA_BITS-1:0] data_in,
    input [5:0] scaling_factor,
    input maxpool_en,
    input maxpool_init,
    input relu_sel,
    input relu_en,
    output logic[7:0] data_out
);

logic [7:0] max_val; 
logic [7:0] postquant_out;
logic [7:0] relu_input;
logic [7:0] maxpool_out;

post_quant post_quant1(
    data_in,
    scaling_factor,
    postquant_out);

maxpooler maxpooler1(
    clk,
    rst,
    postquant_out ,
    maxpool_en,
    maxpool_init,
    max_val);   

assign relu_input = (relu_sel) ? max_val : postquant_out;

ReLU_Qint8 reluer1(
    relu_input,
    relu_en,
    data_out);








endmodule