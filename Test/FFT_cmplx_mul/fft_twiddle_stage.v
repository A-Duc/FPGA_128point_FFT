
module fft_twiddle_stage#(
    parameter BIT_WIDTH   = 16,
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

    input  wire [31:0] iRom_data_path1,
    input  wire [31:0] iRom_data_path2,
    input  wire [31:0] iRom_data_path3,

    output reg                   oData_valid,
    output reg  [SLOT_WIDTH-1:0] oData_slot,

    output wire signed [BIT_WIDTH-1:0] oData0_r,
    output wire signed [BIT_WIDTH-1:0] oData0_i,
    output wire signed [BIT_WIDTH-1:0] oData1_r,
    output wire signed [BIT_WIDTH-1:0] oData1_i,
    output wire signed [BIT_WIDTH-1:0] oData2_r,
    output wire signed [BIT_WIDTH-1:0] oData2_i,
    output wire signed [BIT_WIDTH-1:0] oData3_r,
    output wire signed [BIT_WIDTH-1:0] oData3_i
);
    localparam PIPE_DEPTH = 9;

    wire signed [15:0] path1_wr = iRom_data_path1[31:16];
    wire signed [15:0] path1_wi = iRom_data_path1[15:0];
    wire signed [15:0] path2_wr = iRom_data_path2[31:16];
    wire signed [15:0] path2_wi = iRom_data_path2[15:0];
    wire signed [15:0] path3_wr = iRom_data_path3[31:16];
    wire signed [15:0] path3_wi = iRom_data_path3[15:0];

    wire signed [BIT_WIDTH-1:0] upper_sum_r_w;
    wire signed [BIT_WIDTH-1:0] upper_sum_i_w;
    wire signed [BIT_WIDTH-1:0] upper_dif_r_w;
    wire signed [BIT_WIDTH-1:0] upper_dif_i_w;

    wire signed [BIT_WIDTH-1:0] lower_sum_r_w;
    wire signed [BIT_WIDTH-1:0] lower_sum_i_w;
    wire signed [BIT_WIDTH-1:0] lower_dif_r_w;
    wire signed [BIT_WIDTH-1:0] lower_dif_i_w;

    wire signed [BIT_WIDTH-1:0] path1_mul_r_w;
    wire signed [BIT_WIDTH-1:0] path1_mul_i_w;
    wire signed [BIT_WIDTH-1:0] path2_mul_r_w;
    wire signed [BIT_WIDTH-1:0] path2_mul_i_w;
    wire signed [BIT_WIDTH-1:0] path3_mul_r_w;
    wire signed [BIT_WIDTH-1:0] path3_mul_i_w;

    reg [PIPE_DEPTH-2:0]                valid_pipe;
    reg [SLOT_WIDTH*(PIPE_DEPTH-1)-1:0] slot_pipe;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            oData_valid <= 1'b0;
            oData_slot  <= {SLOT_WIDTH{1'b0}};
            valid_pipe  <= {(PIPE_DEPTH-1){1'b0}};
            slot_pipe   <= {(SLOT_WIDTH*(PIPE_DEPTH-1)){1'b0}};
        end else begin
            valid_pipe  <= {valid_pipe[PIPE_DEPTH-3:0], iData_valid};
            slot_pipe   <= {slot_pipe[SLOT_WIDTH*(PIPE_DEPTH-2)-1:0], iData_slot};
            oData_valid <= valid_pipe[PIPE_DEPTH-2];
            oData_slot  <= slot_pipe[SLOT_WIDTH*(PIPE_DEPTH-1)-1:SLOT_WIDTH*(PIPE_DEPTH-2)];
        end
    end

    cmplx_add_sub #(.BIT_WIDTH(BIT_WIDTH)) upper_butterfly (
        .iA_r(iData0_r), .iA_i(iData0_i), .iB_r(iData1_r), .iB_i(iData1_i),
        .oSum_r(upper_sum_r_w), .oSum_i(upper_sum_i_w), .oDif_r(upper_dif_r_w), .oDif_i(upper_dif_i_w)
    );

    cmplx_add_sub #(.BIT_WIDTH(BIT_WIDTH)) lower_butterfly (
        .iA_r(iData2_r), .iA_i(iData2_i), .iB_r(iData3_r), .iB_i(iData3_i),
        .oSum_r(lower_sum_r_w), .oSum_i(lower_sum_i_w), .oDif_r(lower_dif_r_w), .oDif_i(lower_dif_i_w)
    );

    cmplx_mul #(.BIT_WIDTH(BIT_WIDTH)) mul_path1 (
        .iA_r(upper_dif_r_w), .iA_i(upper_dif_i_w), .iB_r(path1_wr), .iB_i(path1_wi), .out_r(path1_mul_r_w), .out_i(path1_mul_i_w)
    );

    cmplx_mul #(.BIT_WIDTH(BIT_WIDTH)) mul_path2 (
        .iA_r(lower_sum_r_w), .iA_i(lower_sum_i_w), .iB_r(path2_wr), .iB_i(path2_wi), .out_r(path2_mul_r_w), .out_i(path2_mul_i_w)
    );

    cmplx_mul #(.BIT_WIDTH(BIT_WIDTH)) mul_path3 (
        .iA_r(lower_dif_r_w), .iA_i(lower_dif_i_w), .iB_r(path3_wr), .iB_i(path3_wi), .out_r(path3_mul_r_w), .out_i(path3_mul_i_w)
    );

    delay_line #(.BIT_WIDTH(BIT_WIDTH), .DELAY_DEPTH(PIPE_DEPTH)) delay_path0 (
        .Clk(Clk), .Reset(Reset), .iData_r(upper_sum_r_w), .iData_i(upper_sum_i_w), .oData_r(oData0_r), .oData_i(oData0_i)
    );
    delay_line #(.BIT_WIDTH(BIT_WIDTH), .DELAY_DEPTH(PIPE_DEPTH)) delay_path1 (
        .Clk(Clk), .Reset(Reset), .iData_r(path1_mul_r_w), .iData_i(path1_mul_i_w), .oData_r(oData1_r), .oData_i(oData1_i)
    );
    delay_line #(.BIT_WIDTH(BIT_WIDTH), .DELAY_DEPTH(PIPE_DEPTH)) delay_path2 (
        .Clk(Clk), .Reset(Reset), .iData_r(path2_mul_r_w), .iData_i(path2_mul_i_w), .oData_r(oData2_r), .oData_i(oData2_i)
    );
    delay_line #(.BIT_WIDTH(BIT_WIDTH), .DELAY_DEPTH(PIPE_DEPTH)) delay_path3 (
        .Clk(Clk), .Reset(Reset), .iData_r(path3_mul_r_w), .iData_i(path3_mul_i_w), .oData_r(oData3_r), .oData_i(oData3_i)
    );
endmodule
