// 每個 clk 更新 pc = pc + 4

module pc_adder #(
    parameter pc_WIDTH = 8
) (
    input [pc_WIDTH-1:0] pc ,
    output logic [pc_WIDTH-1:0] pc_out
);

    assign pc_out = pc + 'd4;

endmodule