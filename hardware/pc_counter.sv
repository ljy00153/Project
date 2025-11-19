module pc_counter(
    parameter pc_WIDTH = 8
)(
    input clk,
    input rst,
    input [pc_WIDTH-1:0] nxt_pc,
    input pc_hold,
    output logic [pc_WIDTH-1:0] pc
);

    always_ff @( posedge clk ) begin
        if (rst) pc <= '0;
        else begin
            if (pc_hold) pc <= pc;
            else  pc <= nxt_pc;
        end 
    end




endmodule