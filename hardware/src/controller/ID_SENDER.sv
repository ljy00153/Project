
module ID_SENDER(
    input  clk,
    input  rst,
    input  en,
    //input  mode,//1-6
    input  [1:0]tag_type,
    //input  [2:0]valid_e,
    output logic                  set_XID,
    output logic [`XID_BITS-1:0]  ifmap_XID_scan_in,
    output logic [`XID_BITS-1:0]  weight_XID_scan_in,//weight
    output logic [`XID_BITS-1:0]  ipsum_XID_scan_in,
    output logic [`XID_BITS-1:0]  opsum_XID_scan_in,
    output logic                  set_YID,
    output logic [`YID_BITS-1:0]  ifmap_YID_scan_in,
    output logic [`YID_BITS-1:0]  weight_YID_scan_in,
    output logic [`YID_BITS-1:0]  ipsum_YID_scan_in,
    output logic [`YID_BITS-1:0]  opsum_YID_scan_in,
    output logic                  set_LN,
    output logic [`PE_ARRAY_H-2:0] LN_config_in,

    //send tag
    output logic PEA_ifmap_valid,
    input PEA_ifmap_ready,
    output logic [`XID_BITS-1:0]  ifmap_tag_X,
    output logic [`YID_BITS-1:0]  ifmap_tag_Y,

    output logic PEA_weight_valid,
    input PEA_weight_ready,
    output logic [`XID_BITS-1:0]  weight_tag_X,
    output logic [`YID_BITS-1:0]  weight_tag_Y,

    output logic PEA_ipsum_valid,
    input PEA_ipsum_ready,
    output logic [`XID_BITS-1:0]  ipsum_tag_X,
    output logic [`YID_BITS-1:0]  ipsum_tag_Y,

    input PEA_opsum_valid,
    output logic PEA_opsum_ready,
    output logic [`XID_BITS-1:0]  opsum_tag_X,
    output logic [`YID_BITS-1:0]  opsum_tag_Y
);
//tag counter
    logic [2:0] count_ifmap_y;
    logic [2:0] count_ifmap_x;
    logic [2:0] count_weight_y;
    logic [2:0] count_weight_x;
    logic [2:0] count_ipsum_y;
    logic [2:0] count_ipsum_x;
    logic [2:0] count_opsum_y;
    logic [2:0] count_opsum_x;

    logic [1:0] PE_ifmap_num;
    logic [3:0] PE_weight_num;
    logic [1:0] PE_ipsum_num;
    logic [1:0] PE_opsum_num;
//state definition
    typedef enum logic [2:0] 
    {
        IDLE, //0
        SEND_CONFIG_SCAN, // 1
        SEND_TAG //2
        //SEND_PE_CONFIG, //5
    } state_t;
    state_t cs, ns;

    logic [2:0] count_x;
    logic [2:0] count_y;
//FSM
    always_ff@(posedge clk or posedge rst) 
    begin
        if(rst) 
            cs <= IDLE;
        else 
            cs <= ns;
    end
//state transition
    always_comb
    begin
        case (cs)
            IDLE:
            begin
                if(en) 
                    ns = SEND_CONFIG_SCAN;
            end
            SEND_CONFIG_SCAN:
            begin
                if(count_x == ('d`PE_ARRAY_W-1) && count_y == ('d`PE_ARRAY_H-1)) 
                    ns = SEND_TAG;
            end
            SEND_TAG:
            begin
                ns = SEND_TAG;
            end
            default: ns = IDLE;
        endcase    
    end
// count_x count_y1 count_y2
    always_ff @(posedge clk or posedge rst) 
    begin 
        if (rst) 
        begin
            count_x <= 3'd0;
            count_y <= 3'd0;
        end
        else 
        begin
            if(cs == SEND_CONFIG_SCAN) 
            begin
                if(count_x == ('d`PE_ARRAY_W-1)) 
                begin
                    count_x <= 3'd0;
                    if(count_y == ('d`PE_ARRAY_H-1)) 
                        count_y <= 3'd0;
                    else 
                        count_y <= count_y + 3'd1;
                end
                else 
                    count_x <= count_x + 3'd1;
            end
        end
    end

/* Config Scan Chain Setup */
    assign set_XID = (cs == SEND_CONFIG_SCAN);
    assign ifmap_XID_scan_in    = 0;
    assign weight_XID_scan_in   = count_x;
    assign ipsum_XID_scan_in    = count_x;
    assign opsum_XID_scan_in    = count_x;

    assign set_YID = (cs == SEND_CONFIG_SCAN && count_x == 3'd0);
    assign ifmap_YID_scan_in    = count_y;
    assign weight_YID_scan_in   = count_y;
    assign ipsum_YID_scan_in    = count_y;
    assign opsum_YID_scan_in    = count_y;

    assign set_LN = (cs == SEND_CONFIG_SCAN && count_x == 'd0 && count_y == 'd0);
    assign LN_config_in = 5'b11111;

//tag counter
    always_ff @(posedge clk or posedge rst) 
    begin 
        if (rst) 
        begin
            count_ifmap_y <= 3'd0;
            count_ifmap_x <= 3'd0;
            count_weight_y <= 3'd0;
            count_weight_x <= 3'd0;
            count_ipsum_y <= 3'd0;
            count_ipsum_x <= 3'd0;
            count_opsum_y <= 3'd0;
            count_opsum_x <= 3'd0;
            PE_ifmap_num <= 2'd0;
            PE_weight_num <= 4'd0;
            PE_ipsum_num <= 2'd0;
            PE_opsum_num <= 2'd0;
        end
        else 
        begin
            count_opsum_y <= 3'd5;
            if(cs == SEND_TAG && en) 
            begin
                case(tag_type)
                    2'd0://ifmap tag
                    begin
                        if(PEA_ifmap_ready)
                        begin
                            count_ifmap_x <= 3'd0;
                            if(PE_ifmap_num == 2'd2)
                            begin
                                PE_ifmap_num <= 2'd0;
                                if(count_ifmap_y == ('d`PE_ARRAY_H-1))
                                    count_ifmap_y <= 3'd0;
                                else
                                    count_ifmap_y <= count_ifmap_y + 3'd1;
                            end
                            else
                                PE_ifmap_num <= PE_ifmap_num + 2'd1;
                        end
                    end
                    2'd1://weight tag
                    begin
                        if(PEA_weight_ready)
                        begin
                            if(PE_weight_num == 4'd11)
                            begin
                                PE_weight_num <= 4'd0;
                                if(count_weight_x == ('d`PE_ARRAY_W-1))
                                begin
                                    count_weight_x <= 3'd0;
                                    if(count_weight_y == ('d`PE_ARRAY_H-1))
                                        count_weight_y <= 3'd0;
                                    else
                                        count_weight_y <= count_weight_y + 3'd1;
                                end
                                else
                                    count_weight_x <= count_weight_x + 3'd1;
                            end
                            else
                                PE_weight_num <= PE_weight_num + 4'd1;
                        end
                    end
                    2'd2://ipsum tag
                    begin
                        if(PEA_ipsum_ready)
                        begin
                            count_ipsum_y <= 3'd0;
                            if(PE_ipsum_num == 2'd3)
                            begin
                                PE_ipsum_num <= 2'd0;
                                if(count_ipsum_x == ('d`PE_ARRAY_W-1))
                                    count_ipsum_x <= 3'd0;
                                else
                                    count_ipsum_x <= count_ipsum_x + 3'd1;
                            end
                            else    
                                PE_ipsum_num <= PE_ipsum_num + 2'd1;
                        end
                    end
                    2'd3://opsum tag
                    begin
                        if(PEA_opsum_valid)
                        begin
                            count_opsum_y <= 3'd5;
                            if(PE_opsum_num == 2'd3)
                            begin
                                PE_opsum_num <= 2'd0;
                                if(count_opsum_x == ('d`PE_ARRAY_W-1))
                                    count_opsum_x <= 3'd0;
                                else
                                    count_opsum_x <= count_opsum_x + 3'd1;
                            end
                            else
                                PE_opsum_num <= PE_opsum_num + 2'd1;
                        end
                    end
                endcase
            end
        end
    end
//tag output
    assign ifmap_tag_X = count_ifmap_x;
    assign ifmap_tag_Y = count_ifmap_y;
    assign weight_tag_X = count_weight_x;
    assign weight_tag_Y = count_weight_y;
    assign ipsum_tag_X = count_ipsum_x;
    assign ipsum_tag_Y = count_ipsum_y;
    assign opsum_tag_X = count_opsum_x;
    assign opsum_tag_Y = count_opsum_y;
//tag valid
    assign PEA_ifmap_valid  = (cs == SEND_TAG && PEA_ifmap_ready && tag_type==2'd0 && en)?  1'b1 : 1'b0;
    assign PEA_weight_valid = (cs == SEND_TAG && PEA_weight_ready && tag_type==2'd1 && en)? 1'b1 : 1'b0;
    assign PEA_ipsum_valid  = (cs == SEND_TAG && PEA_ipsum_ready && tag_type==2'd2 && en)?  1'b1 : 1'b0;
    assign PEA_opsum_ready  = (cs == SEND_TAG && PEA_opsum_valid && tag_type==2'd3 && en)?  1'b1 : 1'b0;
endmodule