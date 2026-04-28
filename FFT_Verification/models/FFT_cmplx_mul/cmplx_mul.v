
module cmplx_mul #(
    parameter BIT_WIDTH = 16
)(
    input  wire signed [BIT_WIDTH-1:0] iA_r,
    input  wire signed [BIT_WIDTH-1:0] iA_i,
    input  wire signed [15:0]          iB_r,
    input  wire signed [15:0]          iB_i,
    output wire signed [BIT_WIDTH-1:0] out_r,
    output wire signed [BIT_WIDTH-1:0] out_i
);
    // Data is Q8.8, twiddle is Q1.15.
    // Output returns to Q8.8 using round-to-nearest before shifting by 15.
    wire signed [31:0] m_ac = $signed(iA_r) * $signed(iB_r);
    wire signed [31:0] m_bd = $signed(iA_i) * $signed(iB_i);
    wire signed [31:0] m_ad = $signed(iA_r) * $signed(iB_i);
    wire signed [31:0] m_bc = $signed(iA_i) * $signed(iB_r);

    wire signed [32:0] acc_r = $signed({m_ac[31], m_ac}) - $signed({m_bd[31], m_bd});
    wire signed [32:0] acc_i = $signed({m_ad[31], m_ad}) + $signed({m_bc[31], m_bc});

    function automatic signed [15:0] round_shift15;
        input signed [32:0] x;
        reg   signed [32:0] x_round;
        begin
            if (x >= 0)
                x_round = x + 33'sd16384;
            else
                x_round = x - 33'sd16384;
            round_shift15 = x_round >>> 15;
        end
    endfunction

    assign out_r = round_shift15(acc_r);
    assign out_i = round_shift15(acc_i);
endmodule
