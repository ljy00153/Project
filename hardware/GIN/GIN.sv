`include "src/PE_array/GIN/GIN_Bus.sv"
`include "src/PE_array/GIN/GIN_MulticastController.sv"

module GIN (
    input clk,
    input rst,

    // Slave SRAM <-> GIN
    input GIN_valid,
    output logic GIN_ready,
    input [`DATA_BITS - 1:0] GIN_data,

    /* Controller <-> GIN */
    input [`XID_BITS - 1:0] tag_X,
    input [`YID_BITS - 1:0] tag_Y,

    /* config */
    input set_XID,
    input [`XID_BITS - 1:0] XID_scan_in,
    input set_YID,
    input [`YID_BITS - 1:0] YID_scan_in,

    // Master GIN <-> PE
    input [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] PE_ready,
    output logic [`NUMS_PE_ROW * `NUMS_PE_COL - 1:0] PE_valid,
    output logic [`DATA_BITS - 1:0] PE_data
);
/* TODO: Start writing your implementation here */

logic [`NUMS_PE_ROW - 1:0] XBus_ready;
logic [`NUMS_PE_ROW - 1:0] XBus_valid;
logic [`DATA_BITS - 1:0] XBus_data;

/* verilator lint_off UNOPTFLAT */
logic [`XID_BITS - 1:0] scan_chain [0:`NUMS_PE_ROW];
/* verilator lint_on UNOPTFLAT */
assign scan_chain[`NUMS_PE_ROW] = XID_scan_in;
// Y BUS
GIN_Bus #(
    .NUMS_SLAVE(`NUMS_PE_ROW),
    .ID_SIZE(`YID_BITS)
) YBus (
    .clk(clk),
    .rst(rst),
    .tag(tag_Y),
    // GLB
    .master_valid(GIN_valid),
    .master_data(GIN_data),
    .master_ready(GIN_ready),
    // Bus
    .slave_ready(XBus_ready),
    .slave_valid(XBus_valid),
    .slave_data(XBus_data),
    // Config
    .set_id(set_YID),
    .ID_scan_in(YID_scan_in),
    .ID_scan_out()
);

genvar i;
// X BUS
generate
for (i = 0; i < `NUMS_PE_ROW; i++) begin : GIN_XBUS
    GIN_Bus #(
        .NUMS_SLAVE(`NUMS_PE_COL),
        .ID_SIZE(`XID_BITS)
    ) XBus (
        .clk(clk),
        .rst(rst),
        .tag(tag_X),
        // Bus
        .master_valid(XBus_valid[i]),
        .master_data(XBus_data),
        .master_ready(XBus_ready[i]),
        // PE
        .slave_ready(PE_ready[(i+1)*`NUMS_PE_COL-1 : i*`NUMS_PE_COL]),
        .slave_valid(PE_valid[(i+1)*`NUMS_PE_COL-1 : i*`NUMS_PE_COL]),
        .slave_data(PE_data),
        // Config
        .set_id(set_XID),
        .ID_scan_in(scan_chain[i+1]),
        .ID_scan_out(scan_chain[i])
    );
end
endgenerate

/* TODO: End of implementation */
endmodule
