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

    input  wire [53:0] iRom_data_path1,
    input  wire [53:0] iRom_data_path2,
    input  wire [53:0] iRom_data_path3,

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
    localparam CORDIC_DEPTH = 9;

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

    reg [CORDIC_DEPTH-2:0]                valid_pipe;
    reg [SLOT_WIDTH*(CORDIC_DEPTH-1)-1:0] slot_pipe;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            oData_valid <= 1'b0;
            oData_slot  <= {SLOT_WIDTH{1'b0}};
            valid_pipe  <= {(CORDIC_DEPTH-1){1'b0}};
            slot_pipe   <= {(SLOT_WIDTH*(CORDIC_DEPTH-1)){1'b0}};
        end else begin
            valid_pipe  <= {valid_pipe[CORDIC_DEPTH-3:0], iData_valid};
            slot_pipe   <= {slot_pipe[SLOT_WIDTH*(CORDIC_DEPTH-2)-1:0], iData_slot};
            oData_valid <= valid_pipe[CORDIC_DEPTH-2];
            oData_slot  <= slot_pipe[SLOT_WIDTH*(CORDIC_DEPTH-1)-1:SLOT_WIDTH*(CORDIC_DEPTH-2)];
        end
    end

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
        .DELAY_DEPTH(CORDIC_DEPTH)
    ) delay_path0 (
        .Clk    (Clk),
        .Reset  (Reset),
        .iData_r(upper_sum_r_w),
        .iData_i(upper_sum_i_w),
        .oData_r(oData0_r),
        .oData_i(oData0_i)
    );

    fft_cordic_rotator rotator_path1 (
        .clk       (Clk),
        .rst       (Reset),
        .x_in      (upper_dif_r_w),
        .y_in      (upper_dif_i_w),
        .quad      (path1_quad),
        .sigma     (path1_sigma),
        .scale_cmds(path1_scale_cmds),
        .x_out     (oData1_r),
        .y_out     (oData1_i)
    );

    fft_cordic_rotator rotator_path2 (
        .clk       (Clk),
        .rst       (Reset),
        .x_in      (lower_sum_r_w),
        .y_in      (lower_sum_i_w),
        .quad      (path2_quad),
        .sigma     (path2_sigma),
        .scale_cmds(path2_scale_cmds),
        .x_out     (oData2_r),
        .y_out     (oData2_i)
    );

    fft_cordic_rotator rotator_path3 (
        .clk       (Clk),
        .rst       (Reset),
        .x_in      (lower_dif_r_w),
        .y_in      (lower_dif_i_w),
        .quad      (path3_quad),
        .sigma     (path3_sigma),
        .scale_cmds(path3_scale_cmds),
        .x_out     (oData3_r),
        .y_out     (oData3_i)
    );

endmodule
