`include "AXI_define.svh"
`include "ASIC.svh"
`include "../include/ISA.svh"

module glb_addr_generator #(
    parameter int tk = 72,          // 
    parameter int tn = 32,          // 
    parameter int KK_STRIDE_BYTES = 12 //
)(
    input  logic clk,
    input  logic rst,
    input  logic en,
    input  logic [31:0] base_in,           // usually ALU_result
    input  logic [1:0] type_in,            // MODE_IFMAP/FILTER/BIAS/OFMAP
    // CSR[9]
    input  logic [31:0] K_bytes,
    // to id_sender
    output logic id_en,
    // output address to GLB
    output logic [`GLB_ADDR_BITS-1:0] glb_a,
    output logic done
    // optional: export internal counters for debug
    //output logic [31:0] count_k_bytes,
    //output logic [31:0] count_n_bytes,
    //output logic [31:0] count_kk
);
    // determine GLB_Addr
    logic [31:0]count_k; 
    logic [31:0]count_kk;
    logic [31:0]count_n;

    logic [31:0] base_reg;
    logic [1:0]  type_reg;
    logic [1:0] cs,ns;
    localparam IDLE  = 2'b00,
                RUN = 2'b01,
                 DONE  = 2'b10;
    
    always_ff@(posedge clk)begin
        if(rst)begin
            cs<='0;
        end
        else cs <=ns;
    end 
    always_comb begin
        unique case(cs)
            IDLE: begin
                if ( en ) begin
                    ns = RUN;
                end else begin
                    ns = IDLE;
                end
            end
            RUN: begin
                case(type_reg)
                    `MODE_IFMAP: begin
                        if(count_k == tk - 4)ns=DONE;
                    end
                    `MODE_FILTER: begin
                        if ( count_k == KK_STRIDE_BYTES - 4  && count_kk == 5 && count_n == tn - 1 ) begin
                            ns = DONE;
                        end
                    end
                    `MODE_BIAS,
                    `MODE_OFMAP:begin
                        if(count_n == tn-1) ns=DONE;
                    end
                endcase
            end
            DONE: begin
                ns = IDLE;
            end
            default: ns = IDLE;


        endcase

    end
    always_ff @ (posedge clk)begin
        if(rst)begin
            id_en <= 1'b0;
        end
        else begin
            if(cs==RUN) begin
                id_en <= 1'b1;
            end
            else if(cs==DONE) begin

                id_en <=1'b0;
            end
            
        end


    end
    // latch base/type
    always_ff @(posedge clk) begin
        if (rst) begin
            base_reg <= 32'b0;
            type_reg <= 2'b0;
        end else begin
            if (en) begin
            base_reg <= base_in;
            type_reg <= type_in;
        
            end
        end
    end

 
    //count_k 
    always_ff @( posedge clk ) begin
        if(rst) count_k <= 32'b0;
        else begin
            if(cs==RUN)begin
                unique case(type_reg)
                    `MODE_IFMAP: begin
                        if(count_k == tk - 4) count_k <= 32'b0;
                        else count_k <= count_k + 4; 
                    end
                    `MODE_FILTER: begin
                        if(count_k == 8) count_k <=32'b0;
                        else count_k <= count_k + 4;
                    end
                    default: begin
                        count_k <= count_k;
                    end
                endcase
            end
        end
    end
    //count_n
    always_ff @( posedge clk ) begin
        if(rst) count_n <= 32'b0;
        else begin
            if(cs==RUN)begin
                unique case(type_reg)
                    `MODE_FILTER: begin
                        if(count_n == tn - 1 && count_k == 8 ) count_n <= 32'b0;
                        else begin
                            if(count_k == 8) count_n <= count_n + 1;
                            else count_n <= count_n;
                        end 
                    end
                    `MODE_BIAS, `MODE_OFMAP: begin //4 byte, total 128 byte
                        if(count_n == tn-1) count_n <= 32'b0;
                        else  count_n <= count_n + 1;
                    end
                    default: begin
                        count_n <= count_n;
                    end
                endcase
            end
        end
    end
    
    //count_kk
    always_ff@(posedge clk)begin
        if(rst) count_kk <=32'b0;
        else begin
            if(cs==RUN) begin
                unique case (type_reg)
                    `MODE_FILTER:
                        if(count_k == 8 && count_kk == 5 && count_n == tn - 1)count_kk <= 32'b0;
                        else begin
                            if(count_k == 8 && count_n == tn - 1) count_kk <= count_kk + 1;
                            else count_kk <= count_kk;
                        end
                    default: count_kk <= count_kk;
                endcase
            end
        end
    end 
    //glb_addr
    always_comb begin
        unique case ( type_reg )
            `MODE_IFMAP: glb_a = base_reg [`GLB_ADDR_BITS-1:0]+ count_k; // IFMAP
            `MODE_FILTER: glb_a = base_reg[`GLB_ADDR_BITS-1:0] + count_n * K_bytes + count_k  + count_kk * KK_STRIDE_BYTES; // FILTER
            `MODE_BIAS: glb_a = base_reg[`GLB_ADDR_BITS-1:0] + (count_n <<2 ); // BIAS
            `MODE_OFMAP: glb_a =  base_reg[`GLB_ADDR_BITS-1:0] + (count_n <<2);  // OFMAP
            default:glb_a=base_reg[`GLB_ADDR_BITS-1:0];
        endcase

    end 

    always_comb begin
        if(cs==DONE) done=1'b1;
        else done=1'b0;

    end

  
endmodule
