`include "define.svh"
module PE (
    input clk,
    input rst,
    input PE_en,
    input [`CONFIG_SIZE-1:0] i_config,
    input [`DATA_BITS-1:0] ifmap,
    input [`DATA_BITS-1:0] filter,
    input [`DATA_BITS-1:0] ipsum,
    input ifmap_valid,
    input filter_valid,
    input ipsum_valid,
    input opsum_ready,
    output logic [`DATA_BITS-1:0] opsum,
    output logic ifmap_ready,
    output logic filter_ready,
    output logic ipsum_ready,
    output logic opsum_valid
);
/*
state0: idle
state1: receive filter
state2: receive ifmap
state3: compute
state4: add IPSUM
state5: Output OPSUM
state6: REUSE IFMAP





*/
parameter FILTER_COL = 2'b10; //filter col
logic [3:0] cs,ns ;
parameter IDLE = 4'd0,
          REC_FIL = 4'd1,
          REC_IFMAP = 4'd2,
          COMPUTE=4'd3,
          ADD_IPSUM = 4'd4,
          OUTPUT_OPSUM = 4'd5,
          REUSE_IFMAP = 4'd6;
logic [`IFMAP_SIZE-1:0] ifmap_spad [0:`IFMAP_SPAD_LEN-1];
logic [`FILTER_SIZE-1:0] filter_spad [0:`FILTER_SPAD_LEN-1];
logic [`PSUM_SIZE-1:0] ofmap_spad [0:`OFMAP_SPAD_LEN-1];


logic [`FILTER_INDEX_BIT-1:0]filter_count;
logic [`IFMAP_INDEX_BIT-1:0]ifmap_count;
logic [`OFMAP_INDEX_BIT-1:0]ofmap_count;




logic [`OFMAP_COL_BIT-1:0]ofmap_col,count_ofmap_col ;
logic [`OFMAP_INDEX_BIT-1:0]ofmap_ch,count_ofmap_ch;
logic [1:0] input_ch,count_input_ch;
logic [1:0]count_filter_col;

//filter_count {2bit filter col, 2bit ofmap channel,2bit filter channel}
assign filter_count={count_filter_col,count_ofmap_ch,count_input_ch};
assign ifmap_count = {count_filter_col,count_input_ch};
assign ofmap_count = count_ofmap_ch;

assign filter_ready = (cs == REC_FIL)? 1'b1 : 1'b0;
assign ifmap_ready = (cs == REC_IFMAP||cs == REUSE_IFMAP)? 1'b1 : 1'b0;
assign ipsum_ready = (cs == ADD_IPSUM)? 1'b1 : 1'b0;
assign opsum_valid = (cs == OUTPUT_OPSUM)? 1'b1 : 1'b0;
assign opsum = ofmap_spad[ofmap_count];
always_ff@(posedge clk or posedge rst)begin
    if(rst)begin
        cs<=IDLE;
    end 
    else begin
        cs<=ns;
    end 
end 
logic test;
assign test = ifmap_valid && (count_filter_col== FILTER_COL);
always_comb begin
    case (cs)
        IDLE:begin
            if(PE_en)ns=REC_FIL;
            else ns=IDLE;
        end
        REC_FIL:begin
            if(filter_valid && count_filter_col == FILTER_COL && count_ofmap_ch == ofmap_ch)ns=REC_IFMAP;
            else ns=REC_FIL;
        end
        REC_IFMAP:
            if(ifmap_valid &&  count_filter_col == FILTER_COL)ns=COMPUTE;
            else ns=REC_IFMAP;
        COMPUTE:
            if(count_filter_col == FILTER_COL&& count_input_ch == input_ch && count_ofmap_ch == ofmap_ch)ns=ADD_IPSUM;
            else ns=COMPUTE;
        ADD_IPSUM:
            if(ipsum_valid && count_ofmap_ch== ofmap_ch)ns=OUTPUT_OPSUM;
            else ns=ADD_IPSUM;
        OUTPUT_OPSUM:
            if(opsum_ready&&count_ofmap_ch==ofmap_ch)begin
                if(count_ofmap_col==ofmap_col)ns=IDLE;
                else ns=REUSE_IFMAP;   
            end 
            else ns=OUTPUT_OPSUM;
        REUSE_IFMAP:
            if(ifmap_valid)ns=COMPUTE;
            else ns=REUSE_IFMAP;
        default: ns=cs;
    endcase

end 





//load input_ch,ofmap_col,ofmap_ch
always_ff @( posedge clk or posedge rst ) begin
    if(rst)begin
        input_ch <= 2'd0;
        ofmap_col <= 5'd0;
        ofmap_ch <=2'd0;
    end 
    else begin
        if(cs==IDLE&&PE_en)begin
            input_ch <= i_config[1:0];
            ofmap_col <= i_config[`OFMAP_COL_BIT+1:2];
            ofmap_ch <= i_config[`OFMAP_COL_BIT+`OFMAP_INDEX_BIT+1:`OFMAP_COL_BIT+2];
        end 
        else begin
            input_ch <= input_ch;
            ofmap_col <= ofmap_col;
            ofmap_ch <= ofmap_ch;
        end 
    end

end 




//count_filter_col
always_ff @( posedge clk or posedge rst ) begin
    if(rst)begin
        count_filter_col <= 0;
    end 
    else begin
        case (cs)
            REC_FIL: 
                if(filter_valid)begin
                    if(count_filter_col == FILTER_COL)count_filter_col <= 0;
                    else count_filter_col <= count_filter_col + 1;
                end 
                else count_filter_col <= count_filter_col;
            REC_IFMAP: 
                if(ifmap_valid)begin
                    if(count_filter_col == FILTER_COL)count_filter_col <= 0;
                    else count_filter_col <= count_filter_col + 1;
                end
                else count_filter_col <= count_filter_col;
            COMPUTE: 
                if(count_input_ch == input_ch)begin
                    if(count_filter_col == FILTER_COL)count_filter_col <= 0;
                    else count_filter_col <=count_filter_col+1;
                    
                end 
                else count_filter_col <= count_filter_col;
               
            default: count_filter_col <= count_filter_col;
        endcase
      
    end 
end

//count_ofmap_ch
always_ff @( posedge clk or posedge rst ) begin
    if(rst)begin
        count_ofmap_ch <= 0;
    end 
    else begin
        case (cs)
            REC_FIL: 
                if(filter_valid&&count_filter_col == FILTER_COL)begin
                    if(count_ofmap_ch == ofmap_ch)count_ofmap_ch <= 0;
                    else count_ofmap_ch <= count_ofmap_ch + 1;
                end
                else count_ofmap_ch <= count_ofmap_ch;
            COMPUTE: 
                if(count_filter_col == FILTER_COL && count_input_ch == input_ch)begin
                    if(count_ofmap_ch == ofmap_ch)count_ofmap_ch <= 0;
                    else count_ofmap_ch <= count_ofmap_ch +1;
                end
                else count_ofmap_ch <= count_ofmap_ch;
            ADD_IPSUM:
                if(ipsum_valid)begin
                    if(count_ofmap_ch == ofmap_ch)count_ofmap_ch <= 0;
                    else count_ofmap_ch <= count_ofmap_ch + 1;
                end
                else count_ofmap_ch <= count_ofmap_ch;
            OUTPUT_OPSUM:  
                if(opsum_ready)begin
                    if(count_ofmap_ch == ofmap_ch)count_ofmap_ch <= 0;
                    else count_ofmap_ch <= count_ofmap_ch + 1;
                end
                else count_ofmap_ch <= count_ofmap_ch;  
            default: count_ofmap_ch <= count_ofmap_ch;
        endcase
    end
end

//count_input_ch
always_ff @( posedge clk,posedge rst ) begin 
    if (rst) begin
        count_input_ch <= 0;
    end 
    else begin
        case (cs)
            COMPUTE: 
                if(count_input_ch == input_ch)count_input_ch <= 0;
                else count_input_ch <= count_input_ch + 1;
            default: count_input_ch <= count_input_ch;
        endcase
    end
    
end

//count_ofmap_col
always_ff @( posedge clk or posedge rst ) begin
    if (rst) begin
        count_ofmap_col <= 0;
    end 
    else begin   
        if(cs==OUTPUT_OPSUM && opsum_ready&&(count_ofmap_ch == ofmap_ch)) begin
            if(count_ofmap_col == ofmap_col)count_ofmap_col <= 0;
            else count_ofmap_col <= count_ofmap_col + 1;
        end 
        else count_ofmap_col <= count_ofmap_col;
    end
end



// load filter into spad

always_ff @( posedge clk or posedge rst ) begin 
    integer i;
    if (rst) for (i = 0; i < 24; i = i + 1) filter_spad[i] <= 8'd0;
    else begin
        if (cs == REC_FIL && filter_valid) begin
            filter_spad[filter_count] <= filter[7:0];
            filter_spad[filter_count+6'd1] <= filter[15:8];
            filter_spad[filter_count+6'd2] <= filter[23:16];
            filter_spad[filter_count+6'd3] <= filter[31:24];
        end
        else begin
            filter_spad[filter_count] <= filter_spad[filter_count];
            filter_spad[filter_count+6'd1] <= filter_spad[filter_count+6'd1];
            filter_spad[filter_count+6'd2] <= filter_spad[filter_count+6'd2];
            filter_spad[filter_count+6'd3] <= filter_spad[filter_count+6'd3];
        end 
    end
end

// load ifmap into spad

always_ff @( posedge clk or posedge rst ) begin 
    integer i;
    if (rst) for (i = 0; i < 12; i = i + 1) ifmap_spad[i] <= 8'd0;
    else begin
        if (cs == REC_IFMAP&&ifmap_valid) begin
            ifmap_spad[ifmap_count] <= {!ifmap[7], ifmap[6:0]};
            ifmap_spad[ifmap_count+1] <= {!ifmap[15], ifmap[14:8]};
            ifmap_spad[ifmap_count+2] <= {!ifmap[23], ifmap[22:16]};
            ifmap_spad[ifmap_count+3] <= {!ifmap[31], ifmap[30:24]};
        end
        else if (cs == REUSE_IFMAP&&ifmap_valid) begin
            ifmap_spad[0] <= ifmap_spad[4];
            ifmap_spad[1] <= ifmap_spad[5];
            ifmap_spad[2] <= ifmap_spad[6];
            ifmap_spad[3] <= ifmap_spad[7];
            ifmap_spad[4] <= ifmap_spad[8];
            ifmap_spad[5] <= ifmap_spad[9];
            ifmap_spad[6] <= ifmap_spad[10];
            ifmap_spad[7] <= ifmap_spad[11];
            ifmap_spad[8] <= {!ifmap[7], ifmap[6:0]};
            ifmap_spad[9] <= {!ifmap[15], ifmap[14:8]};
            ifmap_spad[10] <= {!ifmap[23], ifmap[22:16]};
            ifmap_spad[11] <= {!ifmap[31], ifmap[30:24]};
        end
    end
end

logic signed [`IFMAP_SIZE+`FILTER_SIZE-1:0] mul_res;
assign mul_res = $signed (ifmap_spad[ifmap_count]) * $signed(filter_spad[filter_count]);
always_ff @( posedge clk or posedge rst ) begin 
    integer i;
    if (rst) for (i = 0; i < 12; i = i + 1) ofmap_spad[i] <= 32'b0;
    else begin
        if (cs == COMPUTE) begin
            ofmap_spad[ofmap_count] <= ofmap_spad[ofmap_count] +  {{(`PSUM_SIZE-`IFMAP_SIZE-`FILTER_SIZE){mul_res[`IFMAP_SIZE+`FILTER_SIZE-1]}}, mul_res};
        end
        else if (cs==ADD_IPSUM  && ipsum_valid)begin
            ofmap_spad[ofmap_count] <= ofmap_spad[ofmap_count] + ipsum;
        end
        else if (cs == REUSE_IFMAP) begin
            for (i = 0; i < `OFMAP_SPAD_LEN; i++) ofmap_spad[i] <= 'd0;
        end

        else begin
            ofmap_spad[ofmap_count] <= ofmap_spad[ofmap_count];
        end 
    end
end


endmodule


