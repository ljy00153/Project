module GIN_MulticastController #(
    parameter ID_SIZE = `XID_BITS
    )(
    input clk,
    input rst,

    input set_id,
    input [ID_SIZE - 1:0] id_in,
    output reg [ID_SIZE - 1:0] id,

    input [ID_SIZE - 1:0] tag,

    input valid_in,
    output logic valid_out,
    input ready_in,
    output logic ready_out
);
/* TODO: Start writing your implementation here */

always_ff @( posedge clk ) begin
    if (rst) id <= 'd0;
    else begin
        if (set_id) id <= id_in;
    end
end

assign ready_out = (tag == id)? ready_in: 1'b1;
assign valid_out = (tag == id)? valid_in: 1'b0;

/* TODO: End of implementation */
endmodule
