module fft_plain_stage #(
    parameter BIT_WIDTH = 16
)(
    input  wire       clk,
    input  wire       reset,
    input  wire [4:0] idata_slot,

    input  wire signed [BIT_WIDTH-1:0] in0_re,
    input  wire signed [BIT_WIDTH-1:0] in0_im,
    input  wire signed [BIT_WIDTH-1:0] in1_re,
    input  wire signed [BIT_WIDTH-1:0] in1_im,
    input  wire signed [BIT_WIDTH-1:0] in2_re,
    input  wire signed [BIT_WIDTH-1:0] in2_im,
    input  wire signed [BIT_WIDTH-1:0] in3_re,
    input  wire signed [BIT_WIDTH-1:0] in3_im,

    output reg  [4:0] odata_slot,

    output reg  signed [BIT_WIDTH:0] out0_re,
    output reg  signed [BIT_WIDTH:0] out0_im,
    output reg  signed [BIT_WIDTH:0] out1_re,
    output reg  signed [BIT_WIDTH:0] out1_im,
    output reg  signed [BIT_WIDTH:0] out2_re,
    output reg  signed [BIT_WIDTH:0] out2_im,
    output reg  signed [BIT_WIDTH:0] out3_re,
    output reg  signed [BIT_WIDTH:0] out3_im
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
        .iA_R(in0_re),
        .iA_I(in0_im),
        .iB_R(in1_re),
        .iB_I(in1_im),
        .oSum_R(upper_sum_re_w),
        .oSum_I(upper_sum_im_w),
        .oDif_R(upper_dif_re_w),
        .oDif_I(upper_dif_im_w)
    );

    cmplx_add_sub lower_butterfly(
        .iA_R(in2_re),
        .iA_I(in2_im),
        .iB_R(in3_re),
        .iB_I(in3_im),
        .oSum_R(lower_sum_re_w),
        .oSum_I(lower_sum_im_w),
        .oDif_R(lower_dif_re_w),
        .oDif_I(lower_dif_im_w)
    );

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            odata_slot <= 5'b0;

            out0_re <= {(BIT_WIDTH + 1){1'b0}};
            out0_im <= {(BIT_WIDTH + 1){1'b0}};
            out1_re <= {(BIT_WIDTH + 1){1'b0}};
            out1_im <= {(BIT_WIDTH + 1){1'b0}};
            out2_re <= {(BIT_WIDTH + 1){1'b0}};
            out2_im <= {(BIT_WIDTH + 1){1'b0}};
            out3_re <= {(BIT_WIDTH + 1){1'b0}};
            out3_im <= {(BIT_WIDTH + 1){1'b0}};
        end else begin
            odata_slot <= idata_slot;

            out0_re <= upper_sum_re_w;
            out0_im <= upper_sum_im_w;
            out1_re <= upper_dif_re_w;
            out1_im <= upper_dif_im_w;

            out2_re <= lower_sum_re_w;
            out2_im <= lower_sum_im_w;
            out3_re <= lower_dif_re_w;
            out3_im <= lower_dif_im_w;
        end
    end
endmodule