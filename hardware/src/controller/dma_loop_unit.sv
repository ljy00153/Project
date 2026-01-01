`include "AXI_define.svh"
`include "ASIC.svh"
`include "ISA.svh"

module DMA_Loop_Unit(
    input  clk,
    input  rst,
    /* Controller */
    input logic CTRL_DMA_en,
    input logic [`AXI_ADDR_BITS-1:0] CTRL_DMA_DRAM_ADDR,
    input logic [`GLB_ADDR_BITS-1:0] CTRL_DMA_GLB_ADDR,
    input logic [`GLB_ADDR_BITS-1:0] CTRL_DMA_len,
    input logic [1:0] CTRL_DMA_mode,
    input logic [1:0] CTRL_DMA_byte_bias,
    output logic CTRL_DMA_done,
    /* DMA */
    output logic DMA_en,
    output logic [`AXI_ADDR_BITS-1:0] DMA_DRAM_ADDR,
    output logic [`GLB_ADDR_BITS-1:0] DMA_GLB_ADDR,
    output logic [`GLB_ADDR_BITS-1:0] DMA_len,
    output logic [1:0]DMA_mode,
    output logic [1:0]DMA_byte_bias,
    input DMA_done,
    /* CSR */
    input [31:0] B, N, M, K,
    input [31:0] in_features, out_features,
    input [31:0] DRAM_ifmap_base,DRAM_weight_base
);
    
    localparam IFMAP_SIZE = 32'd3;
    localparam WEIGHT_H   = 32'd4;
    logic [`GLB_ADDR_BITS-1:0] CTRL_DMA_len_reg;
    logic [1:0] DMA_mode_reg,DMA_byte_bias_reg;
    logic [`AXI_ADDR_BITS-1:0] dram_addr;
    logic [`GLB_ADDR_BITS-1:0] glb_addr;
    logic [`AXI_ADDR_BITS-1:0] dram_stride;
    logic [`GLB_ADDR_BITS-1:0] glb_stride;

    logic loop_finish;
    logic [31:0] loop_cnt;
    logic [31:0] loop_max;
    logic [`GLB_ADDR_BITS-1:0] count_length;
    
    // FSM states
    typedef enum logic [1:0] {
        IDLE   = 2'b00, 
        LOOP   = 2'b01, 
        FINISH = 2'b10 
    } state_t;

    state_t cs, ns;

    /* output logic */
    //assign DMA_en = (cs==LOOP);
    assign DMA_DRAM_ADDR = dram_addr;
    assign DMA_GLB_ADDR = glb_addr;
    assign DMA_len = ()glb_stride>>2; 
    assign CTRL_DMA_done = (cs == FINISH) ;
    assign DMA_mode = DMA_mode_reg;
    assign DMA_byte_bias = DMA_byte_bias_reg;
    /* last loop finish then jump to FINISH STATE */
    assign loop_finish = (count_length == CTRL_DMA_len_reg - glb_stride && DMA_done);

    always_ff @(posedge clk ) begin
        if (rst) begin
            cs <= IDLE;
        end else begin
            cs <= ns;
        end
    end

    // FSM ns logic
    always_comb begin
        ns = cs;
        case (cs)
            IDLE: begin
                if (CTRL_DMA_en) ns =LOOP;
            end
            
            LOOP: begin
                if (DMA_done) begin
                    if (loop_finish) ns = FINISH;
                    else ns = LOOP;
                end
            end
            FINISH: begin
                ns = IDLE;
            end
            default: ns = IDLE;
        endcase
    end    

    // Update loop reg
    always_ff @(posedge clk) begin
        if (rst) begin
            loop_cnt  <= '0;
            dram_addr <= '0;
            glb_addr  <= '0;
            DMA_mode_reg <= '0;
            CTRL_DMA_len_reg <= '0;

        end 
        else begin
            case (cs)
                IDLE: begin
                    loop_cnt <= 0;
                    if(CTRL_DMA_en)begin
                    // Load addr
                        dram_addr <= CTRL_DMA_DRAM_ADDR;
                        glb_addr  <= CTRL_DMA_GLB_ADDR;
                        DMA_mode_reg <= CTRL_DMA_mode;
                        CTRL_DMA_len_reg <=  CTRL_DMA_len;
                        DMA_byte_bias_reg <= CTRL_DMA_byte_bias;
                    end
                end
                
                LOOP: begin
                    // Update addr and cnt 
                    if (DMA_done) begin
                        loop_cnt  <= loop_cnt + 32'd1;
                        dram_addr <= dram_addr + dram_stride;
                        glb_addr  <= glb_addr + glb_stride;
                    end
                end
                
                default: ;
            endcase
        end
    end

    // Calculate stride
    always_comb begin
        loop_max    = 0;
        dram_stride = 0;
        glb_stride  = 0;

        case (DMA_mode_reg)
            `MODE_IFMAP: begin // OP_DMA_LOAD_IFMAP
                loop_max = M;
                dram_stride = in_features; 
                // glb_addr + l * map.K * PE::IFMAP_SIZE * 4
                glb_stride = (K * IFMAP_SIZE) << 2; 
            end

            `MODE_FILTER: begin // OP_DMA_LOAD_WEIGHT
                loop_max = N<<2; 
                dram_stride = in_features; 
                // glb_addr + l * map.K * PE::IFMAP_SIZE * 4
                glb_stride = (K * IFMAP_SIZE) << 2;
            end

            `MODE_BIAS, `MODE_OFMAP: begin // OP_DMA_LOAD_PSUM, OP_DMA_STORE_OFMAP
                loop_max = B;
                dram_stride = out_features << 2; // shape.out_features * 4
                // glb_addr + l * map.N * PE::WEIGHT_H * 4
                glb_stride = (N * WEIGHT_H) << 2;
            end

            default: ;
        endcase
    end

    
    

    always_ff@(posedge clk)begin
        if(rst) DMA_en <= 1'b0;

        else begin
            if(CTRL_DMA_en) DMA_en <=1'b1;
            else if (cs==LOOP && DMA_done && count_length != CTRL_DMA_len_reg - glb_stride)DMA_en <=1'b1;
            else DMA_en<=1'b0;
        end

    end
       
    always_ff@(posedge clk)begin
        if(rst)begin
            count_length<='0;
        end else begin
            if(cs==LOOP && DMA_done)begin
                count_length <= count_length + glb_stride;
            end else if (cs==FINISH)begin
                count_length <=  '0;
            end
        end

    end

    
       
        

endmodule