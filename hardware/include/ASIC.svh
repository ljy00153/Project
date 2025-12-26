`ifndef ASIC_DEFINE
`define ASIC_DEFINE

`define DATA_BITS 32
`define GLB_ADDR_BITS 16

`define XID_BITS 4
`define YID_BITS 3
`define DEFAULT_XID  (2**`XID_BITS - 1)
`define DEFAULT_YID  (2**`YID_BITS - 1)
`define PE_ARRAY_W 8
`define PE_ARRAY_H 6
`define PE_NUMS 48
`define FILT_R 3
`define FILT_S 3
`define GLB_BANK_SIZE 4

/* OPERATION MODE */
`define CONV 0
`define FC 1

/* DMA MODE */
`define MODE_IFMAP 0
`define MODE_FILTER 1
`define MODE_BIAS 2
`define MODE_OFMAP 3

/* GLB MODE */
`define BYTE_MODE 0
`define WORD_MODE 1

/* WAIT TYPE */
`define WAIT_GLB 0
`define WAIT_DMA 1
`define WAIT_PE 2


/* GLB_MUX */
`define ASIC 0
`define DMA 1

/* GLB_DO_select */
`define GLB_DO_PSUM 0
`define GLB_DO_OFMAP 1

/* GLB_DI_select */
`define NO_PAD 0
`define WITH_PAD 1

`define ADDR_MMIO 32'h1004_0000
`define ASIC_ENABLE_OFFSET          (`ADDR_MMIO + 32'h0)
`define ASIC_MAPPING_PARAM_OFFSET   (`ADDR_MMIO + 32'h4)
`define ASIC_SHAPE_PARAM1_OFFSET    (`ADDR_MMIO + 32'h8)
`define ASIC_SHAPE_PARAM2_OFFSET    (`ADDR_MMIO + 32'hc)
`define ASIC_IFMAP_ADDR_OFFSET      (`ADDR_MMIO + 32'h10)
`define ASIC_FILTER_ADDR_OFFSET     (`ADDR_MMIO + 32'h14)
`define ASIC_BIAS_ADDR_OFFSET       (`ADDR_MMIO + 32'h18)
`define ASIC_OPSUM_ADDR_OFFSET      (`ADDR_MMIO + 32'h1c)
`define ASIC_GLB_FILTER_ADDR_OFFSET (`ADDR_MMIO + 32'h20)
`define ASIC_GLB_OFMAP_ADDR_OFFSET  (`ADDR_MMIO + 32'h24)
`define ASIC_GLB_BIAS_ADDR_OFFSET   (`ADDR_MMIO + 32'h28)
`define ASIC_IFMAP_LEN_OFFSET       (`ADDR_MMIO + 32'h2c)
`define ASIC_OFMAP_LEN_OFFSET       (`ADDR_MMIO + 32'h30)

`define FC_CSR0_DRAM_IFMAP_BASE_OFFSET   (`ADDR_MMIO + 32'h34)
`define FC_CSR1_DRAM_WEIGHT_BASE_OFFSET  (`ADDR_MMIO + 32'h38)
`define FC_CSR2_DRAM_OFMAP_BASE_OFFSET   (`ADDR_MMIO + 32'h3c)
`define FC_CSR3_GLB_IFMAP_BASE_OFFSET    (`ADDR_MMIO + 32'h40)
`define FC_CSR4_GLB_WEIGHT_BASE_OFFSET   (`ADDR_MMIO + 32'h44)
`define FC_CSR5_GLB_OPSUM_BASE_OFFSET    (`ADDR_MMIO + 32'h48)
`define FC_CSR6_OF_SIZE_OFFSET           (`ADDR_MMIO + 32'h4c)
`define FC_CSR7_IF_SIZE_OFFSET           (`ADDR_MMIO + 32'h50)
`define FC_CSR8_B_SIZE_OFFSET            (`ADDR_MMIO + 32'h54)
`define FC_CSR9_K_SIZE_OFFSET            (`ADDR_MMIO + 32'h58)
`define FC_CSR10_N_SIZE_OFFSET            (`ADDR_MMIO + 32'h5c)
`define FC_CSR11_M_SIZE_OFFSET            (`ADDR_MMIO + 32'h60)
`define FC_CSR12_DATA_FLOW_OFFSET         (`ADDR_MMIO + 32'h64)

`endif
