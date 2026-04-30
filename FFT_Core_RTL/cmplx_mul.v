module cmplx_mul(
    input  signed [15:0] iA_r,
    input  signed [15:0] iA_i,

    input  signed [15:0] iB_r,
    input  signed [15:0] iB_i,

    output signed [33:0] out_r,
    output signed [33:0] out_i
);
    wire signed [16:0] sum_cd;
    wire signed [16:0] sum_ab;
    wire signed [16:0] dif_ba;

    wire signed [32:0] k1;
    wire signed [32:0] k2;
    wire signed [32:0] k3;

    assign sum_cd = iB_r + iB_i;  // c + d
    assign sum_ab = iA_r + iA_i;  // a + b
    assign dif_ba = iA_i - iA_r;  // b - a

    assign k1 = iA_r * sum_cd;    // a * (c + d)
    assign k2 = iB_i * sum_ab;    // d * (a + b)
    assign k3 = iB_r * dif_ba;    // c * (b - a)

    assign out_r = k1 - k2;
    assign out_i = k1 + k3;

endmodule