module fft_twiddle_stage#(
    parameter BIT_WIDTH   = 16,
    parameter DELAY_DEPTH = 9,
    parameter SLOT_WIDTH  = 5
)(
    input  wire Clk,
    input  wire Reset,

    input  wire                  iData_valid,
    input  wire [SLOT_WIDTH-1:0] iData_slot,

    input  wire signed [BIT_WIDTH-1:0] iData0_r,
    input  wire signed [BIT_WIDTH-1:0] iData0_i,
    input  wire signed [BIT_WIDTH-1:0] iData1_r,
    input  wire signed [BIT_WIDTH-1:0] iData1_i,
    input  wire signed [BIT_WIDTH-1:0] iData2_r,
    input  wire signed [BIT_WIDTH-1:0] iData2_i,
    input  wire signed [BIT_WIDTH-1:0] iData3_r,
    input  wire signed [BIT_WIDTH-1:0] iData3_i,

    input  wire [53:0] iRom_data_path1,
    input  wire [53:0] iRom_data_path2,
    input  wire [53:0] iRom_data_path3,

    output reg                   oData_valid,
    output reg  [SLOT_WIDTH-1:0] oData_slot,

    output reg signed [BIT_WIDTH-1:0] oData0_r,
    output reg signed [BIT_WIDTH-1:0] oData0_i,
    output reg signed [BIT_WIDTH-1:0] oData1_r,
    output reg signed [BIT_WIDTH-1:0] oData1_i,
    output reg signed [BIT_WIDTH-1:0] oData2_r,
    output reg signed [BIT_WIDTH-1:0] oData2_i,
    output reg signed [BIT_WIDTH-1:0] oData3_r,
    output reg signed [BIT_WIDTH-1:0] oData3_i
);

    wire [1:0]  path1_quad;
    wire [23:0] path1_sigma;
    wire [27:0] path1_scale_cmds;

    wire [1:0]  path2_quad;
    wire [23:0] path2_sigma;
    wire [27:0] path2_scale_cmds;

    wire [1:0]  path3_quad;
    wire [23:0] path3_sigma;
    wire [27:0] path3_scale_cmds;

    assign {path1_quad, path1_sigma, path1_scale_cmds} = iRom_data_path1;
    assign {path2_quad, path2_sigma, path2_scale_cmds} = iRom_data_path2;
    assign {path3_quad, path3_sigma, path3_scale_cmds} = iRom_data_path3;

    wire signed [BIT_WIDTH-1:0] upper_sum_r_w;
    wire signed [BIT_WIDTH-1:0] upper_sum_i_w;
    wire signed [BIT_WIDTH-1:0] upper_dif_r_w;
    wire signed [BIT_WIDTH-1:0] upper_dif_i_w;

    wire signed [BIT_WIDTH-1:0] lower_sum_r_w;
    wire signed [BIT_WIDTH-1:0] lower_sum_i_w;
    wire signed [BIT_WIDTH-1:0] lower_dif_r_w;
    wire signed [BIT_WIDTH-1:0] lower_dif_i_w;

    cmplx_add_sub #(
        .BIT_WIDTH(BIT_WIDTH)
    ) upper_butterfly (
        .iA_r  (iData0_r),
        .iA_i  (iData0_i),
        .iB_r  (iData1_r),
        .iB_i  (iData1_i),
        .oSum_r(upper_sum_r_w),
        .oSum_i(upper_sum_i_w),
        .oDif_r(upper_dif_r_w),
        .oDif_i(upper_dif_i_w)
    );

    cmplx_add_sub #(
        .BIT_WIDTH(BIT_WIDTH)
    ) lower_butterfly (
        .iA_r  (iData2_r),
        .iA_i  (iData2_i),
        .iB_r  (iData3_r),
        .iB_i  (iData3_i),
        .oSum_r(lower_sum_r_w),
        .oSum_i(lower_sum_i_w),
        .oDif_r(lower_dif_r_w),
        .oDif_i(lower_dif_i_w)
    );

    delay_line #(
        .BIT_WIDTH(BIT_WIDTH),
        .DELAY_DEPTH(DELAY_DEPTH)
    ) delay_path0 (
        .Clk    (Clk),
        .Reset  (Reset),
        .iData_r(upper_sum_r_w),
        .iData_i(upper_sum_i_w),
        .oData_r(oData0_r),
        .oData_i(oData0_i)
    );

endmodule