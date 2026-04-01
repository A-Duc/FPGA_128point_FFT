module cmplx_mul(
    input  signed [15:0] iA_R,
    input  signed [15:0] iA_I,

    input  signed [15:0] iB_R,
    input  signed [15:0] iB_I,

    output signed [33:0] out_R,
    output signed [33:0] out_I
);
    wire signed [16:0] sum_cd;
    wire signed [16:0] sum_ab;
    wire signed [16:0] dif_ba;

    wire signed [32:0] k1;
    wire signed [32:0] k2;
    wire signed [32:0] k3;

    assign sum_cd = iB_R + iB_I;  // c + d
    assign sum_ab = iA_R + iA_I;  // a + b
    assign dif_ba = iA_I - iA_R;  // b - a

    assign k1 = iA_R * sum_cd;    // a * (c + d)
    assign k2 = iB_I * sum_ab;    // d * (a + b)
    assign k3 = iB_R * dif_ba;    // c * (b - a)

    assign out_R = k1 - k2;
    assign out_I = k1 + k3;

endmodule