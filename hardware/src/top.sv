`include "AXI_define.svh"
`include "ASIC.svh"
`include "ISA.svh"
module asic_top (
    input ACLK,
    input ARESETn,
    input  logic asic_en,
    output logic ASIC_interrupt,
    
    input  logic        im_init_en,
    input  logic [15:0] im_init_addr,
    input  logic [31:0] im_init_wdata,
    // MMIO from tb
    // --- CONV-style CSR ports ---
    input  logic [31:0] ASIC_ENABLE,
    input  logic [31:0] ASIC_MAPPING_PARAM,
    input  logic [31:0] ASIC_SHAPE_PARAM1,
    input  logic [31:0] ASIC_SHAPE_PARAM2,
    input  logic [31:0] ASIC_IFMAP_ADDR,
    input  logic [31:0] ASIC_FILTER_ADDR,
    input  logic [31:0] ASIC_BIAS_ADDR,
    input  logic [31:0] ASIC_OPSUM_ADDR,
    input  logic [31:0] ASIC_GLB_FILTER_ADDR,
    input  logic [31:0] ASIC_GLB_OFMAP_ADDR,
    input  logic [31:0] ASIC_GLB_BIAS_ADDR,
    input  logic [31:0] ASIC_IFMAP_LEN,
    input  logic [31:0] ASIC_OFMAP_LEN,

    // --- FC-style CSR ports ---
    input  logic [31:0] DRAM_ifmap_base,
    input  logic [31:0] DRAM_weight_base,
    input  logic [31:0] DRAM_ofmap_base,
    input  logic [31:0] GLB_ifmap_base,
    input  logic [31:0] GLB_weight_base,
    input  logic [31:0] GLB_opsum_base,
    input  logic [31:0] OF_SIZE,
    input  logic [31:0] IF_SIZE,
    input  logic [31:0] B_SIZE,
    input  logic [31:0] K_SIZE,
    input  logic [31:0] N_SIZE,
    input  logic [31:0] M_SIZE,
    input  logic [31:0] DATAFLOW,
    /*************** AXI master ***************/
    //WRITE ADDRESS0
    output logic [`AXI_ID_BITS-1:0] AWID_M,
    output logic [`AXI_ADDR_BITS-1:0] AWADDR_M,
    output logic [`AXI_LEN_BITS-1:0] AWLEN_M,
    output logic [`AXI_SIZE_BITS-1:0] AWSIZE_M,
    output logic [1:0] AWBURST_M,
    output logic AWVALID_M,
    input AWREADY_M,

    //WRITE DATA0
    output logic [`AXI_DATA_BITS-1:0] WDATA_M,
    output logic [`AXI_STRB_BITS-1:0] WSTRB_M,
    output logic WLAST_M,
    output logic WVALID_M,
    input WREADY_M,

    //WRITE RESPONSE0
    input [`AXI_ID_BITS-1:0] BID_M,
    input [1:0] BRESP_M,
    input BVALID_M,
    output logic BREADY_M,

    //READ ADDRESS0
    output logic [`AXI_ID_BITS-1:0] ARID_M,
    output logic [`AXI_ADDR_BITS-1:0] ARADDR_M,
    output logic [`AXI_LEN_BITS-1:0] ARLEN_M,
    output logic [`AXI_SIZE_BITS-1:0] ARSIZE_M,
    output logic [1:0] ARBURST_M,
    output logic ARVALID_M,
    input logic ARREADY_M,

    //READ DATA0
    input [`AXI_ID_BITS-1:0] RID_M,
    input [`AXI_DATA_BITS-1:0] RDATA_M,
    input [1:0] RRESP_M,
    input RLAST_M,
    input RVALID_M,
    output logic RREADY_M
);

/***********************************
        Global Buffer Mux
************************************/
logic GLB_EN, GLB_EN_dma, GLB_EN_asic;
logic GLB_WEB, GLB_WEB_dma, GLB_WEB_asic;
logic GLB_MODE, GLB_MODE_dma, GLB_MODE_asic;
logic [`GLB_ADDR_BITS-1:0] GLB_A, GLB_A_dma, GLB_A_asic;
logic [`DATA_BITS-1:0] GLB_DI, GLB_DI_dma, GLB_DI_asic;
logic [`DATA_BITS-1:0] GLB_DO, GLB_DO_dma, GLB_DO_asic;
logic glb_mux;

always_comb begin
    // output (mux)
    GLB_DO_dma = (glb_mux == `DMA)?GLB_DO:`DATA_BITS'd0;
    GLB_DO_asic = (glb_mux == `ASIC)?GLB_DO:`DATA_BITS'd0;

    // input (mux)
    if(glb_mux == `ASIC) begin
        GLB_EN = GLB_EN_asic;
        GLB_WEB = GLB_WEB_asic;
        GLB_MODE = GLB_MODE_asic;
        GLB_A = GLB_A_asic;
        GLB_DI = GLB_DI_asic;
    end else begin
        GLB_EN = GLB_EN_dma;
        GLB_WEB = GLB_WEB_dma;
        GLB_MODE = GLB_MODE_dma;
        GLB_A = GLB_A_dma;
        GLB_DI = GLB_DI_dma;
    end
end
/***********************************
            Global Buffer
************************************/
GLB GLB_0(
  .clk(ACLK),
  .EN(GLB_EN),
  .WEB(GLB_WEB),
  .MODE(GLB_MODE),
  .A(GLB_A),
  .DI(GLB_DI),
  .DO(GLB_DO)
);

/***********************************
            ASIC DMA
************************************/
logic DMA_EN;
logic [1:0] DMA_MODE;
logic [1:0] DMA_BYTE_BIAS;
logic DMA_DONE;
logic [`AXI_ADDR_BITS-1:0] DMA_DRAM_ADDR;
logic [`GLB_ADDR_BITS-1:0] DMA_GLB_ADDR;
logic [`GLB_ADDR_BITS-1:0] DMA_LEN;

DMA DMA_0(
    .clk(ACLK),
    .rst(~ARESETn),

    /* controller */
    .EN(DMA_EN),
    .MODE(DMA_MODE),
    .BYTE_BIAS(DMA_BYTE_BIAS),
    .DONE(DMA_DONE),
    .DRAM_ADDR(DMA_DRAM_ADDR),
    .GLB_ADDR(DMA_GLB_ADDR),
    .LEN(DMA_LEN),

    /*************** AXI master ***************/
    //WRITE ADDRESS0
    .AWID_M(AWID_M),
    .AWADDR_M(AWADDR_M),
    .AWLEN_M(AWLEN_M),
    .AWSIZE_M(AWSIZE_M),
    .AWBURST_M(AWBURST_M),
    .AWVALID_M(AWVALID_M),
    .AWREADY_M(AWREADY_M),

    //WRITE DATA0
    .WDATA_M(WDATA_M),
    .WSTRB_M(WSTRB_M),
    .WLAST_M(WLAST_M),
    .WVALID_M(WVALID_M),
    .WREADY_M(WREADY_M),

    //WRITE RESPONSE0
    .BID_M(BID_M),
    .BRESP_M(BRESP_M),
    .BVALID_M(BVALID_M),
    .BREADY_M(BREADY_M),

    //READ ADDRESS0
    .ARID_M(ARID_M),
    .ARADDR_M(ARADDR_M),
    .ARLEN_M(ARLEN_M),
    .ARSIZE_M(ARSIZE_M),
    .ARBURST_M(ARBURST_M),
    .ARVALID_M(ARVALID_M),
    .ARREADY_M(ARREADY_M),

    //READ DATA0
    .RID_M(RID_M),
    .RDATA_M(RDATA_M),
    .RRESP_M(RRESP_M),
    .RLAST_M(RLAST_M),
    .RVALID_M(RVALID_M),
    .RREADY_M(RREADY_M),

    /* GLB */
    .GLB_EN(GLB_EN_dma),
    .GLB_WEB(GLB_WEB_dma),
    .GLB_MODE(GLB_MODE_dma),
    .GLB_A(GLB_A_dma),
    .GLB_DI(GLB_DI_dma),
    .GLB_DO(GLB_DO_dma)
);

/*********************************************
        ASIC (Eyeriss Based PE-array)
*********************************************/

asic asic_0(
    .clk(ACLK),
    .rst(~ARESETn),

    .asic_interrupt(ASIC_interrupt),

    .asic_en(asic_en),
    .maxpool_i(ASIC_ENABLE[1]),
    .relu_i(ASIC_ENABLE[2]),
    .operation_mode_i(ASIC_ENABLE[3]),
    .scaling_factor_i(ASIC_ENABLE[9:4]),

    .im_init_en(im_init_en),
    .im_init_addr(im_init_addr),
    .im_init_wdata(im_init_wdata),


    /* mapping parameters */
    .m_i(ASIC_MAPPING_PARAM[25:16]), // number of ofmap channels stored in GLB
    .e_i(ASIC_MAPPING_PARAM[15:12]), // width of the PE sets
    .p_i(ASIC_MAPPING_PARAM[11:9]), // number of filters processed by a PE set
    .q_i(ASIC_MAPPING_PARAM[8:6]), // number of channels processed by a PE
    .r_i(ASIC_MAPPING_PARAM[5:3]), // number of PE sets that process different channels in the PE arrays
    .t_i(ASIC_MAPPING_PARAM[2:0]), // number of PE sets that process different filters in the PE arrays

    /* shape parameters */
    .C_i(ASIC_SHAPE_PARAM1[19:10]),
    .M_i(ASIC_SHAPE_PARAM1[9:0]),
    .W_i(ASIC_SHAPE_PARAM2[15:8]),
    .H_i(ASIC_SHAPE_PARAM2[7:0]),

    /* DRAM config */
    .ifmap_addr_i(ASIC_IFMAP_ADDR),
    .filter_addr_i(ASIC_FILTER_ADDR),
    .bias_addr_i(ASIC_BIAS_ADDR),
    .ofmap_addr_i(ASIC_OPSUM_ADDR),

    // staring address in GLB (Note: GLB_ifmap_addr = 0)
    .GLB_filter_addr_i(ASIC_GLB_FILTER_ADDR[`GLB_ADDR_BITS-1:0]),
    .GLB_bias_addr_i(ASIC_GLB_BIAS_ADDR[`GLB_ADDR_BITS-1:0]),
    .GLB_opsum_addr_i(ASIC_GLB_OFMAP_ADDR[`GLB_ADDR_BITS-1:0]),

    //FC Layer
    .DRAM_ifmap_base(DRAM_ifmap_base),
    .DRAM_weight_base(DRAM_weight_base),
    .DRAM_ofmap_base(DRAM_ofmap_base),
    .GLB_ifmap_base(GLB_ifmap_base),
    .GLB_weight_base(GLB_weight_base),
    .GLB_opsum_base(GLB_opsum_base),
    .OF_SIZE(OF_SIZE),
    .IF_SIZE(IF_SIZE),
    .B_SIZE(B_SIZE),
    .K_SIZE(K_SIZE),
    .N_SIZE(N_SIZE),
    .M_SIZE(M_SIZE),
    .DATAFLOW(DATAFLOW),
    
    /* GLB */
    .GLB_EN(GLB_EN_asic),
    .GLB_WEB(GLB_WEB_asic),
    .GLB_MODE(GLB_MODE_asic),
    .GLB_A(GLB_A_asic),
    .GLB_DI(GLB_DI_asic),
    .GLB_DO(GLB_DO_asic),
    .GLB_mux(glb_mux),

    /* DMA */
    .DMA_en(DMA_EN),
    .DMA_mode(DMA_MODE),
    .DMA_byte_bias(DMA_BYTE_BIAS),
    .DMA_DRAM_ADDR(DMA_DRAM_ADDR),
    .DMA_GLB_ADDR(DMA_GLB_ADDR),
    .DMA_len(DMA_LEN),
    .DMA_done(DMA_DONE)
);








endmodule
