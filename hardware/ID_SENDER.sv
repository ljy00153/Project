module ID_SENDER(
    input  clk,
    input  rst,
    input  en,
    input  mode,//1-6
    input  [1:0]type,
    input  [2:0]valid_e,
    output logic                  set_XID,
    output logic [`XID_BITS-1:0]  ifmap_XID_scan_in,
    output logic [`XID_BITS-1:0]  filter_XID_scan_in,
    output logic [`XID_BITS-1:0]  ipsum_XID_scan_in,
    output logic [`XID_BITS-1:0]  opsum_XID_scan_in,
    output logic                  set_YID,
    output logic [`YID_BITS-1:0]  ifmap_YID_scan_in,
    output logic [`YID_BITS-1:0]  filter_YID_scan_in,
    output logic [`YID_BITS-1:0]  ipsum_YID_scan_in,
    output logic [`YID_BITS-1:0]  opsum_YID_scan_in,
    output logic                  set_LN,
    output logic [`PE_ARRAY_H-2:0] LN_config_in,


    //send tag
    output logic PEA_ifmap_valid,
    input PEA_ifmap_ready,
    output logic [`XID_BITS-1:0]  ifmap_tag_X,
    output logic [`YID_BITS-1:0]  ifmap_tag_Y,

    output logic PEA_filter_valid,
    input PEA_filter_ready,
    output logic [`XID_BITS-1:0]  filter_tag_X,
    output logic [`YID_BITS-1:0]  filter_tag_Y,

    output logic PEA_ipsum_valid,
    input PEA_ipsum_ready,
    output logic [`XID_BITS-1:0]  ipsum_tag_X,
    output logic [`YID_BITS-1:0]  ipsum_tag_Y,

    input PEA_opsum_valid,
    output logic PEA_opsum_ready,
    output logic [`XID_BITS-1:0]  opsum_tag_X,
    output logic [`YID_BITS-1:0]  opsum_tag_Y,


);






endmodule