`timescale 1ns/1ps
`include "ASIC.svh"
`include "AXI_define.svh"
module DRAM(
    input logic clk,
    input logic rst_n,

    //WRIRE ADDRESS CHANNEL
    input  logic [`AXI_ID_BITS-1:0]    AWID_S,
    input  logic [`AXI_ADDR_BITS-1:0]  AWADDR_S,
    input  logic [7:0]                AWLEN_S,   // AXI4 LEN is 8 bits (0-255 beats)
    input  logic [2:0]                AWSIZE_S,  // 3'b010 = 4 bytes
    input  logic [1:0]                AWBURST_S, // 00:FIXED, 01:INCR, 10:WRAP
    input  logic                      AWVALID_S,
    output logic                      AWREADY_S,

    //WRITE DATA CHANNEL
    input  logic [`AXI_DATA_BITS-1:0]  WDATA_S,
    input  logic [`AXI_STRB_BITS-1:0]  WSTRB_S,
    input  logic                      WLAST_S,
    input  logic                      WVALID_S,
    output logic                      WREADY_S,

    //WRITE RESPONSE CHANNEL
    output logic [`AXI_ID_BITS-1:0]    BID_S,
    output logic [1:0]                BRESP_S,
    output logic                      BVALID_S,
    input  logic                      BREADY_S,

    //READ ADDRESS CHANNEL
    input  logic [`AXI_ID_BITS-1:0]    ARID_S,
    input  logic [`AXI_ADDR_BITS-1:0]  ARADDR_S,
    input  logic [7:0]                ARLEN_S,
    input  logic [2:0]                ARSIZE_S,
    input  logic [1:0]                ARBURST_S,
    input  logic                      ARVALID_S,
    output logic                      ARREADY_S,

    //READ DATA CHANNEL
    output logic [`AXI_ID_BITS-1:0]    RID_S,
    output logic [`AXI_DATA_BITS-1:0]  RDATA_S,
    output logic [1:0]                RRESP_S,
    output logic                      RLAST_S,
    output logic                      RVALID_S,
    input  logic                      RREADY_S
);

    //==============================================================
    // 1. 記憶體儲存 (使用 Associative Array)
    //    這允許你模擬 1GB 甚至 4GB 的空間，而只佔用實際寫入資料的記憶體
    //==============================================================
    logic [7:0] mem [*]; 

    // Helper function: 計算下一個地址
    function automatic [`AXI_ADDR_BITS-1:0] get_next_addr(
        input [`AXI_ADDR_BITS-1:0] current_addr,
        input [2:0]               size,   // AxSIZE
        input [1:0]               burst   // AxBURST
    );
        logic [`AXI_ADDR_BITS-1:0] incr_amount;
        incr_amount = 1 << size; // e.g., size=2 -> 4 bytes

        if (burst == 2'b00) begin
            // FIXED: Address 不變 (用於 FIFO)
            return current_addr;
        end else if (burst == 2'b01) begin
            // INCR: Address 增加
            return current_addr + incr_amount;
        end else begin
            // WRAP: 這裡簡化，視為 INCR。完整的 WRAP 需要 modulo 運算
            return current_addr + incr_amount; 
        end
    endfunction

    //==============================================================
    // 2. 寫入通道控制 (Write Channel FSM)
    //==============================================================
    typedef enum logic [1:0] {W_IDLE, W_BURST, W_RESP} w_state_t;
    w_state_t w_state;

    // Latch 寫入請求資訊
    logic [`AXI_ADDR_BITS-1:0] aw_addr_latch;
    logic [`AXI_ID_BITS-1:0]   aw_id_latch;
    logic [7:0]               aw_len_latch;
    logic [2:0]               aw_size_latch;
    logic [1:0]               aw_burst_latch;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_state   <= W_IDLE;
            AWREADY_S <= 1'b0;
            WREADY_S  <= 1'b0;
            BVALID_S  <= 1'b0;
            BID_S     <= '0;
            BRESP_S   <= '0;
        end else begin
            case (w_state)
                W_IDLE: begin
                    AWREADY_S <= 1'b1; // 準備接收地址
                    BVALID_S  <= 1'b0; // 清除之前的 Response

                    if (AWVALID_S && AWREADY_S) begin
                        // 鎖存地址資訊
                        aw_addr_latch  <= AWADDR_S;
                        aw_id_latch    <= AWID_S;
                        aw_len_latch   <= AWLEN_S;
                        aw_size_latch  <= AWSIZE_S;
                        aw_burst_latch <= AWBURST_S;
                        
                        AWREADY_S      <= 1'b0; // 關閉地址接收
                        WREADY_S       <= 1'b1; // 開啟資料接收
                        w_state        <= W_BURST;
                    end
                end

                W_BURST: begin
                    if (WVALID_S && WREADY_S) begin
                        // --- 寫入記憶體 (Byte Enable 處理) ---
                        // AXI 支援非對齊傳輸，但這是一個簡化的 32-bit width 範例
                        // 我們假設地址會對齊，並根據 WSTRB 寫入
                        if (WSTRB_S[0]) mem[aw_addr_latch]     = WDATA_S[7:0];
                        if (WSTRB_S[1]) mem[aw_addr_latch + 1] = WDATA_S[15:8];
                        if (WSTRB_S[2]) mem[aw_addr_latch + 2] = WDATA_S[23:16];
                        if (WSTRB_S[3]) mem[aw_addr_latch + 3] = WDATA_S[31:24];

                        // 計算下一個地址
                        aw_addr_latch <= get_next_addr(aw_addr_latch, aw_size_latch, aw_burst_latch);

                        // 檢查是否是最後一筆
                        if (WLAST_S) begin
                            WREADY_S <= 1'b0;
                            w_state  <= W_RESP;
                        end
                    end
                end

                W_RESP: begin
                    // 發送 Response
                    BVALID_S <= 1'b1;
                    BID_S    <= aw_id_latch;
                    BRESP_S  <= 2'b00; // OKAY

                    if (BREADY_S && BVALID_S) begin
                        BVALID_S <= 1'b0;
                        w_state  <= W_IDLE;
                    end
                end
            endcase
        end
    end

    //==============================================================
    // 3. 讀取通道控制 (Read Channel FSM)
    //==============================================================
    typedef enum logic [1:0] {R_IDLE, R_BURST} r_state_t;
    r_state_t r_state;

    // Latch 讀取請求資訊
    logic [`AXI_ADDR_BITS-1:0] ar_addr_latch;
    logic [`AXI_ID_BITS-1:0]   ar_id_latch;
    logic [7:0]               ar_len_count;
    logic [2:0]               ar_size_latch;
    logic [1:0]               ar_burst_latch;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_state   <= R_IDLE;
            ARREADY_S <= 1'b0;
            RVALID_S  <= 1'b0;
            RID_S     <= '0;
            RDATA_S   <= '0;
            RRESP_S   <= '0;
        end else begin
            case (r_state)
                R_IDLE: begin
                    RVALID_S  <= 1'b0;
                    ARREADY_S <= 1'b1; // 準備接收地址

                    if (ARVALID_S && ARREADY_S) begin
                        ar_addr_latch  <= ARADDR_S;
                        ar_id_latch    <= ARID_S;
                        ar_len_count   <= ARLEN_S;
                        ar_size_latch  <= ARSIZE_S;
                        ar_burst_latch <= ARBURST_S;

                        ARREADY_S      <= 1'b0;
                        r_state        <= R_BURST;
                    end
                end

                R_BURST: begin
                    // 當 Master 準備好接收 (或者我們剛進入這個狀態)
                    if (!RVALID_S || RREADY_S) begin
                        // 1. 準備資料
                        // 檢查 key 是否存在 (處理 uninitialized read 變 X 的問題)
                        RDATA_S[7:0]   <= (mem.exists(ar_addr_latch))   ? mem[ar_addr_latch]   : 8'h00;
                        RDATA_S[15:8]  <= (mem.exists(ar_addr_latch+1)) ? mem[ar_addr_latch+1] : 8'h00;
                        RDATA_S[23:16] <= (mem.exists(ar_addr_latch+2)) ? mem[ar_addr_latch+2] : 8'h00;
                        RDATA_S[31:24] <= (mem.exists(ar_addr_latch+3)) ? mem[ar_addr_latch+3] : 8'h00;

                        RVALID_S <= 1'b1;
                        RID_S    <= ar_id_latch;
                        RRESP_S  <= 2'b00; // OKAY

                        // 3. 如果握手成功，推進計數器與地址
                        // 注意：這裡有一個 pipeline 行為。
                        // 我們假設這個 cycle 把資料推上去，如果 master 接受了(RREADY=1)，下個 cycle 更新地址
                        if (RVALID_S) begin // 確保這一拍是真的有送資料
                             if (ar_len_count == 0) begin
                                 RVALID_S  <= 1'b0;
                                 r_state   <= R_IDLE;
                             end else begin
                                 ar_len_count <= ar_len_count - 1;
                                 ar_addr_latch <= get_next_addr(ar_addr_latch, ar_size_latch, ar_burst_latch);
                             end
                        end 
                        // 特別處理剛進入 R_BURST 的第一拍 (尚未 VALID)
                        else if (RVALID_S == 0) begin
                             // 什麼都不做，因為資料會在下一拍變 Valid
                        end
                    end
                end
            endcase
        end
    end

    assign RLAST_S = ((!RVALID_S || RREADY_S))?(r_state == R_BURST)? (ar_len_count == 0)? 1'b1 : 1'b0 : 1'b0 : 1'b0;

endmodule