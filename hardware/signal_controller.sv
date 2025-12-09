module signal_controller(
    input  logic clk,
    input  logic rst,
    input  logic asic_en,
    output logic asic_done,

    /* MMIO */
    input  logic [`AXI_ADDR_BITS-1:0] DRAM_IFMAP_BASE,
    input  logic [`AXI_ADDR_BITS-1:0] DRAM_WEIGHT_BASE,
    input  logic [`AXI_ADDR_BITS-1:0] DRAM_OFMAP_BASE,
    input  logic [`GLB_ADDR_BITS-1:0] GLB_IFMAP_BASE,
    input  logic [`GLB_ADDR_BITS-1:0] GLB_WEIGHT_BASE,
    input  logic [`GLB_ADDR_BITS-1:0] GLB_OPSUM_BASE,
    input  logic [31:0] OF_SIZE,
    input  logic [31:0] IF_SIZE,
    input  logic [31:0] B_SIZE,
    input  logic [31:0] K_SIZE,
    input  logic [31:0] N_SIZE,
    input  logic [31:0] M_SIZE,
    input  logic [31:0]  MODE,//1,2,3,6
    input  logic [31:0]  DATA_FLOW,
    // ---------------- DMA  ------------------------------
    output logic                    DMA_en,
    output logic [1:0]              DMA_mode,       // IFMAP:0, Filter:1, BIAS:2, OFMAP: 3
    output logic [`AXI_ADDR_BITS-1:0] DMA_DRAM_ADDR,
    output logic [`GLB_ADDR_BITS-1:0] DMA_GLB_ADDR,
    output logic [`GLB_ADDR_BITS-1:0] DMA_len,
    output logic [1:0]              DMA_byte_bias,
    input  logic                    DMA_done,

    //-----------------PE ID config--------------------------------------------------
    output logic                  ID_sender_en,
    
    output logic PEA_ifmap_valid,
    input PEA_ifmap_ready,

    output logic PEA_filter_valid,
    input PEA_filter_ready,

    output logic PEA_ipsum_valid,
    input PEA_ipsum_ready,

    input PEA_opsum_valid,
    output logic PEA_opsum_ready,
    //------------PE Array----------------------
    output logic [`PE_ARRAY_H*`PE_ARRAY_W-1:0] PE_en,
    output logic [10:0]                        PE_config,
    //------------GLB----------------------
    output logic                  GLB_EN,
    output logic                  GLB_WEB,
    output logic                  GLB_MODE,
    output logic [`GLB_ADDR_BITS-1:0] GLB_A,
    output logic                  relu_sel,
    output logic                  Maxpool_en,
    output logic                  Maxpool_init,
    //------------ALU-----------------------
    input [31:0]ALU_result,                  ,

    //------------control signal--------------------
    //decoder
    input [5:0]opcode,
    input [3:0]CSR_index,
    input [3:0]CFG_TYPE,
    input [31:0]imm,
    //
    output logic [31:0] CSR_output,

    /* PC counter control */
    output logic pc_hold,       // 1: PC 不加一（WAIT）
    output logic next_pc_sel    // 0: pc+1, 1: 分支/loop/jump target（假定由別處決定）
);

    logic [31:0] CSR [0:15]; // 16 CSR registers of 32 bits

    logic [2:0]cs,ns;

    localparam IDLE  = 3'b000,
               RUN = 3'b001,
               DONE  = 3'b010;
    
    always_ff @( posedge clk ) begin
        if ( rst ) begin
            cs <= IDLE;
        end else begin
            cs <= ns;
        end
    end

    always_comb begin
        ns = cs;
        unique case ( cs )
            IDLE: begin
                if ( asic_en ) begin
                    ns = RUN;
                end else begin
                    ns = IDLE;
                end
            end
            RUN: begin
                if ( DMA_done ) begin
                    ns = DONE;
                end else begin
                    ns = RUN;
                end
            end
            DONE: begin
                ns = DONE;
            end
            default: ns = IDLE;
        endcase
    end

    // CSR input
    always_ff @( posedge clk ) begin
        if ( rst ) begin
            // reset all CSR registers to 0
            for ( int i = 0; i < 16; i++ ) begin
                CSR[i] <= 32'b0;
            end
        end else begin
            if(opcode == `OP_CFG_SET) begin
                unique case ( CFG_TYPE )
                    // Load configuration into CSR registers
                    4'd0: CSR[CSR_index] <= DRAM_IFMAP_BASE;
                    4'd1: CSR[CSR_index] <= DRAM_WEIGHT_BASE;
                    4'd2: CSR[CSR_index] <= DRAM_OFMAP_BASE;
                    4'd3: CSR[CSR_index] <= GLB_IFMAP_BASE;
                    4'd4: CSR[CSR_index] <= GLB_WEIGHT_BASE;
                    4'd5: CSR[CSR_index] <= GLB_OPSUM_BASE;
                    4'd6: CSR[CSR_index] <= OF_SIZE;
                    4'd7: CSR[CSR_index] <= IF_SIZE;
                    4'd8: CSR[CSR_index] <= B_SIZE;
                    4'd9: CSR[CSR_index] <= K_SIZE;
                    4'd10: CSR[CSR_index] <= N_SIZE;
                    4'd11: CSR[CSR_index] <= M_SIZE;
                    4'd12: CSR[CSR_index] <= MODE;
                    4'd13: CSR[CSR_index] <= DATA_FLOW;
                    default: CSR[CSR_index] <= CSR[CSR_index];
                endcase
            end
        end
    end

    //combinational logic for output signals
    always_comb begin
        // Default values
        CSR_output = CSR[CSR_index];
        DMA_en = 1'b0;
        ID_sender_en = 1'b0;
        asic_done = 1'b0;
        pc_hold = 1'b0;
        next_pc_sel = 1'b0; 
        PEA_opsum_ready = 1'b0;
        unique case ( cs )
            IDLE: begin
                // Do nothing
            end
            RUN: begin
                unique case( opcode )
                    `OP_DMA_LOAD_IFMAP begin
                        DMA_en = 1'b1;
                        DMA_mode = 2'b00; // IFMAP
                        DMA_DRAM_ADDR = ALU_result; // DRAM_IFMAP_BASE
                        DMA_GLB_ADDR = CSR[3];  // GLB_IFMAP_BASE
                        DMA_len = CSR[7];       // IF_SIZE
                        DMA_byte_bias = 2'b00;  // assuming 4 bytes per data
                    end
                    `OP_DMA_LOAD_WEIGHT begin
                        DMA_en = 1'b1;
                        DMA_mode = 2'b01; // WEIGHT
                        DMA_DRAM_ADDR = CSR[1]; // DRAM_WEIGHT_BASE
                        DMA_GLB_ADDR = CSR[4];  // GLB_WEIGHT_BASE
                        DMA_len = CSR[9];       // N_SIZE * CSR[8]; // K_SIZE
                        DMA_byte_bias = 2'b00;  // assuming 4 bytes per data
                    end
                    `OP_DMA_LOAD_PSUM begin
                        DMA_en = 1'b1;
                        DMA_mode = 2'b10; // PSUM
                        DMA_DRAM_ADDR = CSR[2]; // DRAM_OFMAP_BASE
                        DMA_GLB_ADDR = CSR[5];  // GLB_OPSUM_BASE
                        DMA_len = CSR[10];      // M_SIZE * CSR[8]; // K_SIZE
                        DMA_byte_bias = 2'b00;  // assuming 4 bytes per data
                    end
                    `OP_DMA_STORE_OFMAP begin
                        DMA_en = 1'b1;
                        DMA_mode = 2'b11; // OFMAP
                        DMA_DRAM_ADDR = CSR[2]; // DRAM_OFMAP_BASE
                        DMA_GLB_ADDR = CSR[3];  // GLB_IFMAP_BASE
                        DMA_len = CSR[6];       // OF_SIZE
                        DMA_byte_bias = 2'b00;  // assuming 4 bytes per data
                    end
                    `OP_CPT_TAGXY: begin
                        ID_sender_en = 1'b1;
                    end
                    `OP_WAIT: begin
                        pc_hold = 1'b1;
                    end
                    `OP_JUMP: begin
                        next_pc_sel = 1'b1;
                    end
                    `OP_LOOP: begin
                        next_pc_sel = branch_result; //branch_result from ALU
                    end
                    default: begin
                        // Do nothing
                    end
                endcase
            end
            DONE: begin
                asic_done = 1'b1;
            end
            default: begin
                // Do nothing
            end
        endcase
    end
endmodule