`include "src/PE_array/GON/GON_Bus.sv"
`include "src/PE_array/GON/GON_MulticastController.sv"

module GON (
    input clk,
    input rst,

    /* Master GON <-> GLB */
    output logic GON_valid,
    input GON_ready,
    output logic [`DATA_BITS-1:0] GON_data,

    /* Controller <-> GON */
    input [`XID_BITS-1:0] tag_X,
    input [`YID_BITS-1:0] tag_Y,
    /* config */
    input set_XID,
    input [`XID_BITS - 1:0] XID_scan_in,

    input set_YID,
    input [`YID_BITS - 1:0] YID_scan_in,

    // Master PE <-> GON
    input [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] PE_valid,
    output logic [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] PE_ready,
    input [`DATA_BITS * `NUMS_PE_ROW * `NUMS_PE_COL - 1:0] PE_data

);
/* TODO: Start writing your implementation here */

genvar i;

logic [`NUMS_PE_ROW - 1:0] XBus_valid;
logic [`NUMS_PE_ROW - 1:0] XBus_ready;
logic [`NUMS_PE_ROW * `DATA_BITS - 1:0] XBus_data;
/* verilator lint_off UNOPTFLAT */
logic [`XID_BITS - 1:0] XID_scan_chain [0:`NUMS_PE_ROW];
/* verilator lint_on UNOPTFLAT */

GON_Bus #(
    .NUMS_MASTER(`NUMS_PE_ROW),
    .ID_SIZE(`YID_BITS)
) Y_Bus (
    .clk(clk),
    .rst(rst),
    .tag(tag_Y),
    // Bus
    .master_valid(XBus_valid),
    .master_data(XBus_data),
    .master_ready(XBus_ready),
    // GLB
    .slave_valid(GON_valid),
    .slave_ready(GON_ready),
    .slave_data(GON_data),
    .set_id(set_YID),
    .ID_scan_in(YID_scan_in),
    .ID_scan_out()
);

assign XID_scan_chain[`NUMS_PE_ROW] = XID_scan_in;

generate
    for (i = 0; i < `NUMS_PE_ROW; i++) begin : GON_XBUS
        GON_Bus #(
            .NUMS_MASTER(`NUMS_PE_COL),
            .ID_SIZE(`XID_BITS)
        ) XBus (
            .clk(clk),
            .rst(rst),
            .tag(tag_X),
            // PE
            .master_valid(PE_valid[(i+1)*`NUMS_PE_COL-1:i*`NUMS_PE_COL]),
            .master_data(PE_data[(i+1)*`NUMS_PE_COL*`DATA_BITS-1:i*`NUMS_PE_COL*`DATA_BITS]),
            .master_ready(PE_ready[(i+1)*`NUMS_PE_COL-1:i*`NUMS_PE_COL]),
            // Bus
            .slave_valid(XBus_valid[i]),
            .slave_ready(XBus_ready[i]),
            .slave_data(XBus_data[(i+1)*`DATA_BITS-1:i*`DATA_BITS]),
            .set_id(set_XID),
            .ID_scan_in(XID_scan_chain[i+1]),
            .ID_scan_out(XID_scan_chain[i])
        );
    end
endgenerate

/* TODO: End of implementation */
endmodule
