module fft_plain_stage #(
    parameter BIT_WIDTH = 16
)(
    input  wire       Clk,
    input  wire       Reset,
    input  wire       iData_valid,
    input  wire [4:0] iData_slot,

    input  wire signed [BIT_WIDTH-1:0] iData0_r,
    input  wire signed [BIT_WIDTH-1:0] iData0_i,
    input  wire signed [BIT_WIDTH-1:0] iData1_r,
    input  wire signed [BIT_WIDTH-1:0] iData1_i,
    input  wire signed [BIT_WIDTH-1:0] iData2_r,
    input  wire signed [BIT_WIDTH-1:0] iData2_i,
    input  wire signed [BIT_WIDTH-1:0] iData3_r,
    input  wire signed [BIT_WIDTH-1:0] iData3_i,

    output reg  [4:0] oData_slot,
    output reg        oData_valid,

    output reg  signed [BIT_WIDTH:0] oData0_r,
    output reg  signed [BIT_WIDTH:0] oData0_i,
    output reg  signed [BIT_WIDTH:0] oData1_r,
    output reg  signed [BIT_WIDTH:0] oData1_i,
    output reg  signed [BIT_WIDTH:0] oData2_r,
    output reg  signed [BIT_WIDTH:0] oData2_i,
    output reg  signed [BIT_WIDTH:0] oData3_r,
    output reg  signed [BIT_WIDTH:0] oData3_i
);

    wire signed [BIT_WIDTH:0] upper_sum_r_w;
    wire signed [BIT_WIDTH:0] upper_sum_i_w;
    wire signed [BIT_WIDTH:0] upper_dif_r_w;
    wire signed [BIT_WIDTH:0] upper_dif_i_w;

    wire signed [BIT_WIDTH:0] lower_sum_r_w;
    wire signed [BIT_WIDTH:0] lower_sum_i_w;
    wire signed [BIT_WIDTH:0] lower_dif_r_w;
    wire signed [BIT_WIDTH:0] lower_dif_i_w;

    cmplx_add_sub upper_butterfly(
        .iA_r(iData0_r),
        .iA_i(iData0_i),
        .iB_r(iData1_r),
        .iB_i(iData1_i),
        .oSum_r(upper_sum_r_w),
        .oSum_i(upper_sum_i_w),
        .oDif_r(upper_dif_r_w),
        .oDif_i(upper_dif_i_w)
    );

    cmplx_add_sub lower_butterfly(
        .iA_r(iData2_r),
        .iA_i(iData2_i),
        .iB_r(iData3_r),
        .iB_i(iData3_i),
        .oSum_r(lower_sum_r_w),
        .oSum_i(lower_sum_i_w),
        .oDif_r(lower_dif_r_w),
        .oDif_i(lower_dif_i_w)
    );

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            oData_valid <= 1'b0;
            oData_slot <= 5'b0;

            oData0_r <= {(BIT_WIDTH + 1){1'b0}};
            oData0_i <= {(BIT_WIDTH + 1){1'b0}};
            oData1_r <= {(BIT_WIDTH + 1){1'b0}};
            oData1_i <= {(BIT_WIDTH + 1){1'b0}};
            oData2_r <= {(BIT_WIDTH + 1){1'b0}};
            oData2_i <= {(BIT_WIDTH + 1){1'b0}};
            oData3_r <= {(BIT_WIDTH + 1){1'b0}};
            oData3_i <= {(BIT_WIDTH + 1){1'b0}};
        end else begin
            oData_valid <= iData_valid;
            oData_slot <= iData_slot;

            oData0_r <= upper_sum_r_w;
            oData0_i <= upper_sum_i_w;
            oData1_r <= upper_dif_r_w;
            oData1_i <= upper_dif_i_w;

            oData2_r <= lower_sum_r_w;
            oData2_i <= lower_sum_i_w;
            oData3_r <= lower_dif_r_w;
            oData3_i <= lower_dif_i_w;
        end
    end
endmodule