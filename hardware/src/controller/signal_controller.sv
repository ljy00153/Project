`include "AXI_define.svh"
`include "ASIC.svh"
`include "ISA.svh"
module signal_controller#(
     parameter tk = 72,tn = 32
)(
    input  logic clk,
    input  logic rst,
    input  logic asic_en,
    output logic asic_done,

    /* MMIO */
    output logic [3:0] mmio_sel,
    output logic csr_wen,

    input logic [31:0] DRAM_ifmap_base,
    input logic [31:0] DRAM_weight_base,
    input logic [31:0] DRAM_ofmap_base,
    input logic [31:0] GLB_ifmap_base,
    input logic [31:0] GLB_weight_base,
    input logic [31:0] GLB_opsum_base,
    input logic [31:0] OF_SIZE,
    input logic [31:0] IF_SIZE,
    input logic [31:0] B_SIZE,
    input logic [31:0] K_SIZE,
    input logic [31:0] N_SIZE,
    input logic [31:0] M_SIZE,
    input logic [31:0] DATAFLOW,
    
    // ---------------- DMA LOOPER------------------------------
    output logic [31:0] loop_start_point,
    output logic                    DMA_en,
    output logic [1:0]              DMA_mode,       // IFMAP:0, Filter:1, BIAS:2, OFMAP: 3
    output logic [`AXI_ADDR_BITS-1:0] DMA_DRAM_ADDR,
    output logic [`GLB_ADDR_BITS-1:0] DMA_GLB_ADDR,
    output logic [`GLB_ADDR_BITS-1:0] DMA_len,
    output logic [1:0]              DMA_byte_bias,
    input  logic                    DMA_done,
    // CSR output
    output logic [31:0] OF_BYTE,
    output logic [31:0] IF_BYTE,
    output logic [31:0] B_BYTE,
    output logic [31:0] K_BYTE,
    output logic [31:0] N_BYTE,
    output logic [31:0] M_BYTE,
    output logic [31:0] DRAM_in_features_addr_base,
    output logic [31:0] DRAM_weight_addr_base,

    //-----------------PE ID config--------------------------------------------------
    output logic ID_sender_en,
    input logic PEA_ifmap_ready,
    input logic PEA_filter_ready,
    input logic PEA_ipsum_ready,
    input logic PEA_opsum_valid,
    input logic [5:0]PE_finish,
    //------------PE Array----------------------
    output logic [`PE_ARRAY_H*`PE_ARRAY_W-1:0] PE_en,
    output logic [10:0]                        PE_config,
    input logic GLB_opsum_valid, //for PE busy

    //------------GLB nux----------------------

    output logic GLB_mux,
    output logic GLB_DI_select,
    output logic GLB_DO_select,

    //------------GLB_addr------------------
    output logic [31:0]glb_addr_base,
    output logic [1:0]glb_type,
    input logic glb_done,
    //-------------GLB----------------------
    output logic glb_addr_en,
    //------------PPU-----------------------
    output logic                  relu_sel,
    output logic                  Maxpool_en,
    output logic                  Maxpool_init,
    //------------ALU-----------------------
    input [31:0]ALU_result,                  

    //------------control signal--------------------
    //decoder
    input [5:0]opcode,
    input [3:0]CSR_index,
    input [3:0]CFG_TYPE,
    input [1:0]inst_type,
    input [31:0]imm,
    //
    input logic branch_result,
    output logic [31:0] CSR_output,
    
    /* PC counter control */
    output logic pc_hold,       // 1: PC 不加一（WAIT）
    output logic next_pc_sel,    // 0: pc+1, 1: 分支/loop/jump target（假定由別處決定）
    output logic alu_op1_sel,
    output logic alu_op2_sel,
    output logic reg_wb_en



);
    // --------------------------------
    // internal registers / wires
    // --------------------------------
    logic [31:0] CSR [0:15]; //16 CSR registers
    logic [2:0]cs,ns;
    logic [`GLB_ADDR_BITS-1:0] glb_addr; //16 bits
    logic DMA_busy,GLB_busy,PE_busy;
    logic [2:0] valid_e ;
    //glb type reg 因為OP_CPT_TAGXY傳進來type只有1 cycle 要存起來才能等到OP_G2P 傳出去
    logic [1:0]glb_type_reg;
    logic [1:0]wait_type_reg;
    localparam IDLE  = 3'b000,
               RUN = 3'b001,
               PC_HOLD = 3'b010,
               DONE  = 3'b011;
    // --------------------------------
    // simple assigns
    // --------------------------------
    assign next_pc_sel = (branch_result||opcode==`OP_JUMP)? 1'b1 : 1'b0; //branch_result from ALU
    assign alu_op1_sel = (opcode[5:2]==`DMA_type || opcode[5:1]==`STREAM_type || opcode == `OP_LOOP)? 1'b0 : 1'b1; // 0 for CSR file,1 for reg
    assign alu_op2_sel = (opcode==`OP_ADDI || opcode==`OP_MULI || opcode == `OP_LOOP)? 1'b1 : 1'b0; // 0 for reg file,1 for imm
    assign csr_wen = (opcode==`OP_CFG_SET)? 1'b1 : 1'b0;
    assign mmio_sel = (opcode==`OP_CFG_SET)? CFG_TYPE : 4'b0000;
    assign reg_wb_en = (opcode==`OP_ADD||opcode==`OP_ADDI||opcode==`OP_MULI||opcode==`OP_MUL||opcode==`OP_LOOP)? 1'b1 : 1'b0;
    assign GLB_DO_select = `NO_PAD;
    assign GLB_DI_select = `GLB_DO_PSUM;
    assign GLB_mux = (opcode[5:2]==`DMA_type || wait_type_reg ==`WAIT_DMA)? 1'b`DMA : 1'b`ASIC;

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
                if (pc_hold) ns= PC_HOLD;
                else begin
                    if ( opcode==`OP_END ) begin
                        ns = DONE;
                    end else begin
                        ns = RUN;
                    end
                end
            end
            PC_HOLD: begin
                if(!pc_hold) ns = RUN;
                else ns =PC_HOLD;
            end
            DONE: begin
                ns = DONE;
            end
            default: ns = IDLE;
        endcase
    end

    //mmio mux
    logic [31:0] mmio_mux_out;
    always_comb begin
        case (mmio_sel)
            4'b0000: mmio_mux_out = DRAM_ifmap_base;
            4'b0001: mmio_mux_out = DRAM_weight_base;
            4'b0010: mmio_mux_out = DRAM_ofmap_base;
            4'b0011: mmio_mux_out = GLB_ifmap_base;
            4'b0100: mmio_mux_out = GLB_weight_base;
            4'b0101: mmio_mux_out = GLB_opsum_base;
            4'b0110: mmio_mux_out = OF_SIZE;
            4'b0111: mmio_mux_out = IF_SIZE;
            4'b1000: mmio_mux_out = B_SIZE;
            4'b1001: mmio_mux_out = K_SIZE;
            4'b1010: mmio_mux_out = N_SIZE;
            4'b1011: mmio_mux_out = M_SIZE;
            4'b1100: mmio_mux_out = DATAFLOW;
            default: mmio_mux_out = 32'b0;
        endcase
    end

    //csr input
    always_ff @( posedge clk ) begin
        if ( rst ) begin
            for ( int i = 0; i < 16; i++ ) begin
                CSR[i] <= 32'b0;
            end
        end else if (cs==RUN&& csr_wen ) begin
            CSR[CSR_index] <= mmio_mux_out;
        end 
    end

    //csr output
    assign CSR_output = CSR[CSR_index];

    always_comb begin
        DRAM_in_features_addr_base=CSR[0];
        DRAM_weight_addr_base=CSR[1];
        OF_BYTE = CSR[6];
        IF_BYTE = CSR[7];
        B_BYTE = CSR[8];
        K_BYTE = CSR[9];
        N_BYTE = CSR[10];
        M_BYTE = CSR[11];   

    end
        
    /* sequential logic */
    always_ff @( posedge clk ) begin
        if(rst) begin
            glb_type_reg <= 2'b0;
            wait_type_reg <= 2'b0;
            loop_start_point<=2'b0;

        end
        else begin
            
            if(cs==RUN && opcode==`OP_CPT_TAGXY) begin
                glb_type_reg <= inst_type;
            end
            if(cs==RUN && opcode==`OP_WAIT)begin
                wait_type_reg <= inst_type;
            end
            else if (!pc_hold)begin
                wait_type_reg <= 2'd3; 
            end
            if(cs==RUN && opcode==`OP_MULI)begin
                loop_start_point <= ALU_result;
            end

            
        end
    end
   
    //combinational logic for output signals
    always_comb begin
        // Default values
        PE_en={`PE_ARRAY_H*`PE_ARRAY_W{1'b0}};
        DMA_en = 1'b0;
        DMA_mode = 2'b00;
        DMA_DRAM_ADDR = 32'b0;
        DMA_GLB_ADDR = 32'b0;
        DMA_len = 32'b0;
        DMA_byte_bias = 2'b00;
        glb_addr_en = 1'b0;
        ID_sender_en = 1'b0;
        asic_done = 1'b0;
        relu_sel     = 1'b0;
        Maxpool_en   = 1'b0;
        Maxpool_init = 1'b0;      
       
        unique case ( cs )
            IDLE: begin
                // Do nothing
            end
            RUN: begin
                unique case( opcode )
                    `OP_SET_ID: begin
                        ID_sender_en = 1'b1;
                    end
                    `OP_DMA_LOAD_IFMAP: begin
                        DMA_en = 1'b1;
                        DMA_mode = 2'b00; // IFMAP
                        DMA_DRAM_ADDR = ALU_result; // DRAM_IFMAP_BASE
                        DMA_GLB_ADDR = CSR[3];  // GLB_IFMAP_BASE
                        DMA_len = imm[17:0];       // IF_SIZE
                        DMA_byte_bias = 2'b00;  // assuming 4 bytes per data
                    end
                    `OP_DMA_LOAD_WEIGHT: begin
                        DMA_en = 1'b1;
                        DMA_mode = 2'b01; // WEIGHT
                        DMA_DRAM_ADDR = ALU_result; // DRAM_WEIGHT_BASE
                        DMA_GLB_ADDR = CSR[4];  // GLB_WEIGHT_BASE
                        DMA_len = imm[17:0];       // N_SIZE * CSR[8]; // K_SIZE
                        DMA_byte_bias = 2'b00;  // assuming 4 bytes per data
                      
              
                      end
                    `OP_DMA_LOAD_PSUM: begin
                        DMA_en = 1'b1;
                        DMA_mode = 2'b10; // PSUM
                        DMA_DRAM_ADDR = ALU_result; // DRAM_OFMAP_BASE
                        DMA_GLB_ADDR = CSR[5];  // GLB_OPSUM_BASE
                        DMA_len = imm[17:0];      // M_SIZE * CSR[8]; // K_SIZE
                        DMA_byte_bias = 2'b00;  // assuming 4 bytes per data

                                          
                    end
                    `OP_DMA_STORE_OFMAP: begin
                        DMA_en = 1'b1;
                        DMA_mode = 2'b11; // OFMAP
                        DMA_DRAM_ADDR = ALU_result; // DRAM_OFMAP_BASE
                        DMA_GLB_ADDR = CSR[5];  // GLB_IFMAP_BASE
                        DMA_len = imm[17:0];       // OF_SIZE
                        DMA_byte_bias = 2'b00;  // assuming 4 bytes per data

                
                    end
                    `OP_G2P: begin
                        glb_addr_en=1'b1;
                        glb_addr_base=ALU_result;
                        glb_type=glb_type_reg;
                        
                    end
                    `OP_P2G_OPSUM: begin
                        glb_addr_en = 1'b1;
                        glb_addr_base=ALU_result;
                        glb_type=glb_type_reg;

                    end
                    `OP_CPT_TAGXY: begin
                        ID_sender_en = 1'b1;
                    end
                    `OP_COMPUTE:begin
                        valid_e = ALU_result[2:0];
                        case(valid_e)
                            'd0: PE_en = {6{8'b00000000}};
                            'd1: PE_en = {{1{8'b11111111}}, {5{8'b00000000}}};
                            'd2: PE_en = {{2{8'b11111111}}, {4{8'b00000000}}};
                            'd3: PE_en = {{3{8'b11111111}}, {3{8'b00000000}}};
                            'd4: PE_en = {{4{8'b11111111}}, {2{8'b00000000}}};
                            'd5: PE_en = {{5{8'b11111111}}, {1{8'b00000000}}};
                            'd6: PE_en = {6{8'b11111111}};
                        endcase
                        PE_config = {1'b1,2'b11,CSR[11][5:0]-1,2'b11};
                    end
                    `OP_WAIT: begin
                        


                    end
                    `OP_LOOP: begin
                    end
                    default: begin
                        // Do nothing
                    end
                endcase
            end
            PC_HOLD:begin
                 // Do nothing
            end
            DONE: begin
                asic_done = 1'b1;
            end
            default: begin
                // Do nothing
            end
        endcase
    end

   
    always_comb begin 
        
        case (wait_type_reg)
            `WAIT_GLB:begin
                if(GLB_busy)pc_hold=1;
                else pc_hold=0;
            end
            `WAIT_DMA:begin
                if(DMA_busy)pc_hold=1;
                else pc_hold=0;
            end
            `WAIT_PE:begin
                if(PE_busy)pc_hold=1;
                else pc_hold=0;
            end
        endcase
    end
    
    
    //assign pc_hold = (opcode == `OP_WAIT )? 1'b1 : 1'b0;

    //busy signal
    always_ff @( posedge clk ) begin
        if ( rst ) begin
            DMA_busy <= 1'b0;
            GLB_busy <= 1'b0;
            PE_busy  <= 1'b0;
        end else begin
            if ( DMA_en ) begin
                DMA_busy <= 1'b1;
            end else if ( DMA_done ) begin
                DMA_busy <= 1'b0;
            end

            if (glb_done ) begin
                GLB_busy <= 1'b0;

            end else if (glb_addr_en) begin
                GLB_busy <= 1'b1;
            end
            
            if (GLB_opsum_valid) begin//讀完GLB ifmap 開始算
                PE_busy <= 1'b0;
            end else if (!GLB_busy) begin
                PE_busy <= 1'b1;
            end 

        end
    end

    

endmodule