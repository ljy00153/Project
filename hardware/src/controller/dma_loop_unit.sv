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
    output logic CTRL_DMA_done,
    /* DMA */
    output logic DMA_en,
    output logic [`AXI_ADDR_BITS-1:0] DMA_DRAM_ADDR,
    output logic [`GLB_ADDR_BITS-1:0] DMA_GLB_ADDR,
    output logic [`GLB_ADDR_BITS-1:0] DMA_len,
    output logic [1:0]DMA_mode,
    input DMA_done,
    /* CSR */
    input [31:0] B, N, M, K,
    input [31:0] in_features, out_features
);


    localparam IFMAP_SIZE = 32'd3;
    localparam WEIGHT_H   = 32'd4;

    logic [`AXI_ADDR_BITS-1:0] dram_addr;
    logic [`GLB_ADDR_BITS-1:0] glb_addr;
    logic [`AXI_ADDR_BITS-1:0] dram_stride;
    logic [`GLB_ADDR_BITS-1:0] glb_stride;

    logic loop_finish;
    logic [31:0] loop_cnt;
    logic [31:0] loop_max;

    assign loop_finish = (loop_cnt == loop_max - 32'd1);

    
    // FSM states
    typedef enum logic [1:0] {
        IDLE   = 2'b00, 
        LOOP   = 2'b01, 
        FINISH = 2'b10 
    } state_t;

    state_t cs, ns;

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
            loop_cnt  <= 0;
            dram_addr <= 0;
            glb_addr  <= 0;
        end 
        else begin
            case (cs)
                IDLE: begin
                    loop_cnt <= 0;
                    if(CTRL_DMA_en)begin
                    // Load addr
                        loop_cnt  <= 0;
                        dram_addr <= CTRL_DMA_DRAM_ADDR;
                        glb_addr  <= CTRL_DMA_GLB_ADDR;
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

    // Calculate addr
    always_comb begin
        loop_max    = 0;
        dram_stride = 0;
        glb_stride  = 0;

        case (CTRL_DMA_mode)
            `MODE_IFMAP: begin // OP_DMA_LOAD_IFMAP
                loop_max = M;
                dram_stride = in_features; 
                // glb_addr + l * map.K * PE::IFMAP_SIZE * 4
                glb_stride = (K * IFMAP_SIZE) << 2; 
            end

            `MODE_FILTER: begin // OP_DMA_LOAD_WEIGHT
                loop_max = N; 
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

    // output logic
    always_comb begin
        DMA_DRAM_ADDR = dram_addr;
        DMA_GLB_ADDR  = glb_addr;
        DMA_en        = (cs == LOOP);
        DMA_mode      = CTRL_DMA_mode;
        CTRL_DMA_done = (cs == FINISH);

        case (CTRL_DMA_mode)
            `MODE_IFMAP, `MODE_FILTER: begin
                // DMA_len = min(Total_Len / loop_max, in_features)
                DMA_len = ((CTRL_DMA_len / loop_max) < in_features) ? 
                          (CTRL_DMA_len / loop_max) : in_features;
            end
            
            `MODE_BIAS, `MODE_OFMAP: begin
                // DMA_len = min(Total_Len / loop_max, out_features * 4)
                DMA_len = ((CTRL_DMA_len / loop_max) < (out_features << 2)) ? 
                          (CTRL_DMA_len / loop_max) : (out_features << 2);
            end
            
            default: begin
                DMA_len = CTRL_DMA_len / loop_max;
            end
        endcase
    end

 
endmodule