module cmplx_add_sub #(
    parameter BIT_WIDTH = 16
)(
    input  wire signed [BIT_WIDTH-1:0] iA_r,
    input  wire signed [BIT_WIDTH-1:0] iA_i,
    input  wire signed [BIT_WIDTH-1:0] iB_r,
    input  wire signed [BIT_WIDTH-1:0] iB_i,

    output wire signed [BIT_WIDTH-1:0] oSum_r,
    output wire signed [BIT_WIDTH-1:0] oSum_i,
    output wire signed [BIT_WIDTH-1:0] oDif_r,
    output wire signed [BIT_WIDTH-1:0] oDif_i
);

    assign oSum_r = iA_r + iB_r;
    assign oSum_i = iA_i + iB_i;

    assign oDif_r = iA_r - iB_r;
    assign oDif_i = iA_i - iB_i;

endmodule