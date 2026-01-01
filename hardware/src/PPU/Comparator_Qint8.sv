

module maxpooler (
    input clk,
    input rst,
    input [7:0] data_in,
    input maxpool_en,
    input maxpool_init,
    output logic[7:0] data_out
);

always_ff @( posedge clk ,posedge rst ) begin 
    if(rst)begin 
        data_out <= 8'd0; // Reset output to zero
    end 
    else begin
        if (maxpool_en) begin
            if (maxpool_init) begin
                data_out <= data_in; // Initialize with the first input
            end else begin
                if(data_in > data_out) begin
                    data_out <= data_in; // Update with the maximum value
                end else begin
                    data_out <= data_out; // Keep the current maximum
                end 
            end
        end else begin
            data_out <= 8'd0; // If maxpooling is not enabled, output zero
        end
    end 
end 


endmodule