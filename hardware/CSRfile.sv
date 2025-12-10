module CSRfile(
    input logic clk,
    input logic rst,
    input logic [3:0] type,
    //decoder
    input logic [3:0] CSR_index,
    input logic [31:0] wdata,
    //controller 
    input logic CSR_write_en,
    
    output logic [31:0] CSR_output


);

// write CSR
    always_ff @( posedge clk ) begin
        if ( rst ) begin
            for ( int i = 0; i < 16; i++ ) begin
                CSR[i] <= 32'b0;
            end
        end else if ( CSR_write_en ) begin
            csr[CSR_index] <= wdata;
            
        end 
    end

    // read CSR
    always_comb begin
        CSR_output = CSR[CSR_index];
    end




endmodule