`timescale 1ns/1ps
`include "ASIC.svh"
`include "AXI_define.svh"

module DRAM(
    input logic clk,
    input logic rst_n,

    // WRITE ADDRESS CHANNEL
    input  logic [`AXI_ID_BITS-1:0]    AWID_S,
    input  logic [`AXI_ADDR_BITS-1:0]  AWADDR_S,
    input  logic [7:0]                AWLEN_S,
    input  logic [2:0]                AWSIZE_S,
    input  logic [1:0]                AWBURST_S,
    input  logic                      AWVALID_S,
    output logic                      AWREADY_S,

    // WRITE DATA CHANNEL
    input  logic [`AXI_DATA_BITS-1:0]  WDATA_S,
    input  logic [`AXI_STRB_BITS-1:0]  WSTRB_S,
    input  logic                      WLAST_S,
    input  logic                      WVALID_S,
    output logic                      WREADY_S,

    // WRITE RESPONSE CHANNEL
    output logic [`AXI_ID_BITS-1:0]    BID_S,
    output logic [1:0]                BRESP_S,
    output logic                      BVALID_S,
    input  logic                      BREADY_S,

    // READ ADDRESS CHANNEL
    input  logic [`AXI_ID_BITS-1:0]    ARID_S,
    input  logic [`AXI_ADDR_BITS-1:0]  ARADDR_S,
    input  logic [7:0]                ARLEN_S,
    input  logic [2:0]                ARSIZE_S,
    input  logic [1:0]                ARBURST_S,
    input  logic                      ARVALID_S,
    output logic                      ARREADY_S,

    // READ DATA CHANNEL
    output logic [`AXI_ID_BITS-1:0]    RID_S,
    output logic [`AXI_DATA_BITS-1:0]  RDATA_S,
    output logic [1:0]                RRESP_S,
    output logic                      RLAST_S,
    output logic                      RVALID_S,
    input  logic                      RREADY_S
);

    //==============================================================
    // 記憶體宣告與 Helper Function (維持不變)
    //==============================================================
    logic [7:0] mem [*];

    function automatic [`AXI_ADDR_BITS-1:0] get_next_addr(
        input [`AXI_ADDR_BITS-1:0] current_addr,
        input [2:0]               size,
        input [1:0]               burst
    );
        logic [`AXI_ADDR_BITS-1:0] incr_amount;
        incr_amount = 1 << size;
        if (burst == 2'b00) return current_addr;
        else if (burst == 2'b01) return current_addr + incr_amount;
        else return current_addr + incr_amount; 
    endfunction

    //==============================================================
    // 寫入通道 (Write Channel) - (維持你的原始邏輯，這裡略過以節省篇幅)
    //==============================================================
    // ... (這部分可以保持原樣，或者也依照 Read 的方式改成 Comb 輸出) ...
    // 為求精簡，這裡假設 Write Channel 邏輯與你原本的一樣。
    // 如果需要我也幫忙改 Write Channel，請告訴我。
    
    // 這裡為了讓 Code 能跑，我先放一個簡化的 Write Channel 佔位符
    // 實際上請使用你原本代碼的 Part 2 部分
    typedef enum logic [1:0] {W_IDLE, W_BURST, W_RESP} w_state_t;
    w_state_t w_state;
    // ... (Write logic hidden for focus on Read) ...
    
    //==============================================================
    // 3. 讀取通道控制 (Read Channel) - 重大修改
    //==============================================================
    typedef enum logic [1:0] {R_IDLE, R_BURST} r_state_t;
    r_state_t r_state, r_next_state;

    // 內部暫存器 (Registers) - 這些仍然要是 Sequential 的
    logic [`AXI_ADDR_BITS-1:0] ar_addr_latch;
    logic [`AXI_ID_BITS-1:0]   ar_id_latch;
    logic [7:0]               ar_len_count;
    logic [2:0]               ar_size_latch;
    logic [1:0]               ar_burst_latch;

    //==============================================================
    // Part A: 狀態機與計數器更新 (Sequential Logic)
    // 只負責「記住」現在讀到哪裡、還剩多少
    //==============================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_state        <= R_IDLE;
            ar_addr_latch  <= '0;
            ar_id_latch    <= '0;
            ar_len_count   <= '0;
            ar_size_latch  <= '0;
            ar_burst_latch <= '0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    // 握手成功，鎖存資訊並切換狀態
                    if (ARVALID_S && ARREADY_S) begin
                        ar_addr_latch  <= ARADDR_S;
                        ar_id_latch    <= ARID_S;
                        ar_len_count   <= ARLEN_S;
                        ar_size_latch  <= ARSIZE_S;
                        ar_burst_latch <= ARBURST_S;
                        r_state        <= R_BURST;
                    end
                end

                R_BURST: begin
                    // 當 Master 接受了這一筆資料 (RVALID && RREADY)
                    if (RVALID_S && RREADY_S) begin
                        if (ar_len_count == 0) begin
                            // 傳輸結束
                            r_state <= R_IDLE;
                        end else begin
                            // 準備下一筆
                            ar_len_count  <= ar_len_count - 1;
                            ar_addr_latch <= get_next_addr(ar_addr_latch, ar_size_latch, ar_burst_latch);
                        end
                    end
                end
            endcase
        end
    end

    //==============================================================
    // Part B: 輸出邏輯 (Combinational Logic)
    // 根據當前的狀態，直接產生輸出，沒有 Clock Delay
    //==============================================================
    always_comb begin
        // 預設值 (避免 Latch)
        ARREADY_S = 1'b0;
        RVALID_S  = 1'b0;
        RLAST_S   = 1'b0;
        RRESP_S   = 2'b00; // OKAY
        RID_S     = ar_id_latch;
        RDATA_S   = '0;

        case (r_state)
            R_IDLE: begin
                ARREADY_S = 1'b1; // 隨時準備接收
            end

            R_BURST: begin
                // 在 BURST 狀態下，資料直接有效
                RVALID_S = 1'b1;
                
                // 組合邏輯直接讀取 mem (這就是你要的非 sequential 輸出)
                // 這樣只要 ar_addr_latch 一更新，RDATA 馬上變
                RDATA_S[7:0]   = (mem.exists(ar_addr_latch))   ? mem[ar_addr_latch]   : 8'h00;
                RDATA_S[15:8]  = (mem.exists(ar_addr_latch+1)) ? mem[ar_addr_latch+1] : 8'h00;
                RDATA_S[23:16] = (mem.exists(ar_addr_latch+2)) ? mem[ar_addr_latch+2] : 8'h00;
                RDATA_S[31:24] = (mem.exists(ar_addr_latch+3)) ? mem[ar_addr_latch+3] : 8'h00;

                // 判斷是否為最後一筆
                if (ar_len_count == 0) begin
                    RLAST_S = 1'b1;
                end
            end
        endcase
    end

    //==============================================================
    // 為了補全程式碼，這裡補上簡化的 Write Channel Part (Sequential 沒動)
    // 你可以替換回你原本的完整版
    //==============================================================
    logic [`AXI_ADDR_BITS-1:0] aw_addr_latch;
    // ... (省略變數宣告以保持簡潔) ...
    
    always_ff @(posedge clk or negedge rst_n) begin
       if(!rst_n) begin 
            AWREADY_S <= 0; 
            WREADY_S <= 0; 
            BVALID_S <= 0; 
            w_state <= W_IDLE;
            BRESP_S   <= 0;
 
       end else begin
           case(w_state)
               W_IDLE: begin
                    AWREADY_S <= 1;
                    WREADY_S <= 0;
                    BVALID_S <= 0;
                    if(AWVALID_S && AWREADY_S) begin
                        aw_addr_latch <= AWADDR_S;
                        AWREADY_S <= 0;
                        WREADY_S <= 1; 
                        w_state <= W_BURST;
                    end
               end
               W_BURST: begin
                   if(WVALID_S && WREADY_S) begin
                       if(WSTRB_S[0]) mem[aw_addr_latch] <= WDATA_S[7:0];
                       if(WSTRB_S[1]) mem[aw_addr_latch+1] <= WDATA_S[15:8];
                       if(WSTRB_S[2]) mem[aw_addr_latch+2] <= WDATA_S[23:16];
                       if(WSTRB_S[3]) mem[aw_addr_latch+3] <= WDATA_S[31:24];
                       // 簡化: 這裡省略了 Burst 計算，假設只寫一筆
                       if(WLAST_S) begin 
                        WREADY_S <= 0; 
                        w_state <= W_RESP; 
                        BRESP_S  <= 2'b00; // OKAY
                        end
                       else aw_addr_latch <= aw_addr_latch + 4; // 簡化 INCR
                   end
               end
               W_RESP: begin
                    BVALID_S <= 1; 
                    if(BREADY_S && BVALID_S) begin 
                        BVALID_S <= 0;
                        w_state <= W_IDLE; 
                    end
               end
           endcase
       end
    end

endmodule