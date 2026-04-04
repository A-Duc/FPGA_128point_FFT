module cmplx_add_sub#(
    parameter BIT_WIDTH = 16
)(
    input  signed [BIT_WIDTH - 1:0] iA_R,  // Real part
    input  signed [BIT_WIDTH - 1:0] iA_I,  // Imaginary part
    
    input  signed [BIT_WIDTH - 1:0] iB_R,  
    input  signed [BIT_WIDTH - 1:0] iB_I,  

    output signed [BIT_WIDTH:0] oSum_R,
    output signed [BIT_WIDTH:0] oSum_I,
    
    output signed [BIT_WIDTH:0] oDif_R,
    output signed [BIT_WIDTH:0] oDif_I
);
    assign oSum_R = iA_R + iB_R;
    assign oSum_I = iA_I + iB_I;
    
    assign oDif_R = iA_R - iB_R;
    assign oDif_I = iA_I - iB_I;

endmodule