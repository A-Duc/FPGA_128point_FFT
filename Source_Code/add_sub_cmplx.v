module add_sub_cmplx(
    input  signed [15:0] iA_R,  // Real part
    input  signed [15:0] iA_I,  // Imaginary part
    
    
    input  signed [15:0] iB_R,  
    input  signed [15:0] iB_I,  

    
    output signed [15:0] oSum_R,
    output signed [15:0] oSum_I,
    
    
    output signed [15:0] oDif_R,
    output signed [15:0] oDif_I
);
    assign oSum_R = iA_R + iB_R;
    assign oSum_I = iA_I + iB_I;


    assign oDif_R = iA_R - iB_R;
    assign oDif_I = iA_I - iB_I;

endmodule