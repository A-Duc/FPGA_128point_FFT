module fft_plain_stage #(
    parameter BIT_WIDTH = 16
)(
    input  wire       clk,
    input  wire       reset,
    input  wire [4:0] idata_slot,

    input  wire signed [BIT_WIDTH-1:0] in_re [0:3],
    input  wire signed [BIT_WIDTH-1:0] in_im [0:3],

    output reg  [4:0] odata_slot,

    output reg  signed [BIT_WIDTH:0]   out_re[0:3],
    output reg  signed [BIT_WIDTH:0]   out_im[0:3]
);

    wire signed [BIT_WIDTH:0] upper_sum_re_w;
    wire signed [BIT_WIDTH:0] upper_sum_im_w;
    wire signed [BIT_WIDTH:0] upper_dif_re_w;
    wire signed [BIT_WIDTH:0] upper_dif_im_w;

    wire signed [BIT_WIDTH:0] lower_sum_re_w;
    wire signed [BIT_WIDTH:0] lower_sum_im_w;
    wire signed [BIT_WIDTH:0] lower_dif_re_w;
    wire signed [BIT_WIDTH:0] lower_dif_im_w;

    cmplx_add_sub upper_butterfly(
        .iA_R(in_re[0]),
        .iA_I(in_im[0]),
        .iB_R(in_re[1]),
        .iB_I(in_im[1]),
        .oSum_R(upper_sum_re_w),
        .oSum_I(upper_sum_im_w),
        .oDif_R(upper_dif_re_w),
        .oDif_I(upper_dif_im_w)
    );

    cmplx_add_sub lower_butterfly(
        .iA_R(in_re[2]),
        .iA_I(in_im[2]),
        .iB_R(in_re[3]),
        .iB_I(in_im[3]),
        .oSum_R(lower_sum_re_w),
        .oSum_I(lower_sum_im_w),
        .oDif_R(lower_dif_re_w),
        .oDif_I(lower_dif_im_w)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            odata_slot <= 5'b0;

            out_re[0] <= {(BIT_WIDTH + 1){1'b0}};
            out_im[0] <= {(BIT_WIDTH + 1){1'b0}};
            out_re[1] <= {(BIT_WIDTH + 1){1'b0}};
            out_im[1] <= {(BIT_WIDTH + 1){1'b0}};
            out_re[2] <= {(BIT_WIDTH + 1){1'b0}};
            out_im[2] <= {(BIT_WIDTH + 1){1'b0}};
            out_re[3] <= {(BIT_WIDTH + 1){1'b0}};
            out_im[3] <= {(BIT_WIDTH + 1){1'b0}};
        end else begin
            odata_slot <= idata_slot;

            out_re[0] <= upper_sum_re_w;
            out_im[0] <= upper_sum_im_w;
            out_re[1] <= upper_dif_re_w;
            out_im[1] <= upper_dif_im_w;

            out_re[2] <= lower_sum_re_w;
            out_im[2] <= lower_sum_im_w;
            out_re[3] <= lower_dif_re_w;
            out_im[3] <= lower_dif_im_w;
        end
    end
endmodule