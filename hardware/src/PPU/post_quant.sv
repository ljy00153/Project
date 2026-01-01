//postquant
`include "define.svh"

module post_quant (
    input [`DATA_BITS-1:0] data_in,
    input [5:0] scaling_factor,
    output logic[7:0] clamped_data
);
    



logic [`DATA_BITS-1:0] shifted_data;
logic [7:0] exclusive_data;

always_comb begin 
    
    // Shift the input data by the scaling factor
    // and adjust the sign bit for two's complement representation
    shifted_data = $signed(data_in) >>> scaling_factor;
    
    
    if ((~shifted_data[`DATA_BITS-1])&&(|shifted_data[`DATA_BITS-2:7]))
        clamped_data = 8'd255;
    else if ((shifted_data[`DATA_BITS-1]&&~(&shifted_data[`DATA_BITS-2:7]))) 
       clamped_data = 8'd0;
    else 
       clamped_data = {~shifted_data[7], shifted_data[6:0]};
    
end

endmodule