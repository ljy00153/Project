module pc_counter#(
    parameter pc_WIDTH = 16
)(
    input clk,
    input rst,
    input en,
    input [pc_WIDTH-1:0] nxt_pc,
    input pc_hold,
    output logic [pc_WIDTH-1:0] pc
);
    logic cs,ns;
    localparam IDLE = 0,
    RUN=1;

    always_ff @(posedge clk)begin
        if(rst) cs<=0;
        else cs<=ns;
    end 
    always_comb begin
        case (cs)
            IDLE:ns=(en)?RUN:IDLE;
            RUN:ns=RUN;
            default:begin
            end
        endcase
    end
    always_ff @( posedge clk) begin
        if (rst) pc <= '0;
        else begin
            if(cs==RUN)begin
                if (pc_hold) pc <= pc;
                else  pc <= nxt_pc;
            end
        end 
    end




endmodule