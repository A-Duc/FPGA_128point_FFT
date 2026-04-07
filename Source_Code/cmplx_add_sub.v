module cmplx_add_sub#(
    parameter BIT_WIDTH = 16
)(
    input  signed [BIT_WIDTH-1:0] iA_r,  // Real part
    input  signed [BIT_WIDTH-1:0] iA_i,  // Imaginary part
    
    input  signed [BIT_WIDTH-1:0] iB_r,  
    input  signed [BIT_WIDTH-1:0] iB_i,  

    output signed [BIT_WIDTH:0] oSum_r,
    output signed [BIT_WIDTH:0] oSum_i,
    
    output signed [BIT_WIDTH:0] oDif_r,
    output signed [BIT_WIDTH:0] oDif_i
);
    assign oSum_r = {iA_r[BIT_WIDTH-1], iA_r} + {iB_r[BIT_WIDTH-1], iB_r};
    assign oSum_i = {iA_i[BIT_WIDTH-1], iA_i} + {iB_i[BIT_WIDTH-1], iB_i};

    assign oDif_r = {iA_r[BIT_WIDTH-1], iA_r} - {iB_r[BIT_WIDTH-1], iB_r};
    assign oDif_i = {iA_i[BIT_WIDTH-1], iA_i} - {iB_i[BIT_WIDTH-1], iB_i};

endmodule