module fft_twiddle_stage #(
    parameter BIT_WIDTH  = 16,
    parameter SLOT_WIDTH = 5
)(
    input  wire                         Clk,
    input  wire                         Reset,

    input  wire                         iData_valid,
    input  wire [SLOT_WIDTH-1:0]        iData_slot,

    input  wire signed [BIT_WIDTH-1:0]  iData0_r,
    input  wire signed [BIT_WIDTH-1:0]  iData0_i,
    input  wire signed [BIT_WIDTH-1:0]  iData1_r,
    input  wire signed [BIT_WIDTH-1:0]  iData1_i,
    input  wire signed [BIT_WIDTH-1:0]  iData2_r,
    input  wire signed [BIT_WIDTH-1:0]  iData2_i,
    input  wire signed [BIT_WIDTH-1:0]  iData3_r,
    input  wire signed [BIT_WIDTH-1:0]  iData3_i,

    input  wire [53:0]                  iRom_data_path1,
    input  wire [53:0]                  iRom_data_path2,
    input  wire [53:0]                  iRom_data_path3,

    output reg                          oData_valid,
    output reg  [SLOT_WIDTH-1:0]        oData_slot,

    output wire signed [BIT_WIDTH-1:0]  oData0_r,
    output wire signed [BIT_WIDTH-1:0]  oData0_i,
    output wire signed [BIT_WIDTH-1:0]  oData1_r,
    output wire signed [BIT_WIDTH-1:0]  oData1_i,
    output wire signed [BIT_WIDTH-1:0]  oData2_r,
    output wire signed [BIT_WIDTH-1:0]  oData2_i,
    output wire signed [BIT_WIDTH-1:0]  oData3_r,
    output wire signed [BIT_WIDTH-1:0]  oData3_i
);

    localparam integer QUAD_WIDTH       = 2;
    localparam integer SIGMA_WIDTH      = 24;
    localparam integer SCALE_CMD_WIDTH  = 28;
    localparam integer CORDIC_DEPTH     = 10;
    localparam integer META_DELAY_DEPTH = CORDIC_DEPTH - 1;
    localparam integer META_SLOT_PIPE_W = SLOT_WIDTH * META_DELAY_DEPTH;

    wire [QUAD_WIDTH-1:0]      path1_quad;
    wire [SIGMA_WIDTH-1:0]     path1_sigma;
    wire [SCALE_CMD_WIDTH-1:0] path1_scale_cmds;

    wire [QUAD_WIDTH-1:0]      path2_quad;
    wire [SIGMA_WIDTH-1:0]     path2_sigma;
    wire [SCALE_CMD_WIDTH-1:0] path2_scale_cmds;

    wire [QUAD_WIDTH-1:0]      path3_quad;
    wire [SIGMA_WIDTH-1:0]     path3_sigma;
    wire [SCALE_CMD_WIDTH-1:0] path3_scale_cmds;

    wire signed [BIT_WIDTH-1:0] upper_sum_r;
    wire signed [BIT_WIDTH-1:0] upper_sum_i;
    wire signed [BIT_WIDTH-1:0] upper_dif_r;
    wire signed [BIT_WIDTH-1:0] upper_dif_i;

    wire signed [BIT_WIDTH-1:0] lower_sum_r;
    wire signed [BIT_WIDTH-1:0] lower_sum_i;
    wire signed [BIT_WIDTH-1:0] lower_dif_r;
    wire signed [BIT_WIDTH-1:0] lower_dif_i;

    reg  [META_DELAY_DEPTH-1:0] valid_pipe;
    reg  [META_SLOT_PIPE_W-1:0] slot_pipe;

    assign {path1_quad, path1_sigma, path1_scale_cmds} = iRom_data_path1;
    assign {path2_quad, path2_sigma, path2_scale_cmds} = iRom_data_path2;
    assign {path3_quad, path3_sigma, path3_scale_cmds} = iRom_data_path3;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            oData_valid <= 1'b0;
            oData_slot  <= {SLOT_WIDTH{1'b0}};
            valid_pipe  <= {META_DELAY_DEPTH{1'b0}};
            slot_pipe   <= {META_SLOT_PIPE_W{1'b0}};
        end else begin
            valid_pipe  <= {valid_pipe[META_DELAY_DEPTH-2:0], iData_valid};
            slot_pipe   <= {slot_pipe[META_SLOT_PIPE_W-SLOT_WIDTH-1:0], iData_slot};
            oData_valid <= valid_pipe[META_DELAY_DEPTH-1];
            oData_slot  <= slot_pipe[META_SLOT_PIPE_W-1 -: SLOT_WIDTH];
        end
    end

    cmplx_add_sub #(
        .BIT_WIDTH(BIT_WIDTH)
    ) upper_butterfly (
        .iA_r   (iData0_r),
        .iA_i   (iData0_i),
        .iB_r   (iData1_r),
        .iB_i   (iData1_i),
        .oSum_r (upper_sum_r),
        .oSum_i (upper_sum_i),
        .oDif_r (upper_dif_r),
        .oDif_i (upper_dif_i)
    );

    cmplx_add_sub #(
        .BIT_WIDTH(BIT_WIDTH)
    ) lower_butterfly (
        .iA_r   (iData2_r),
        .iA_i   (iData2_i),
        .iB_r   (iData3_r),
        .iB_i   (iData3_i),
        .oSum_r (lower_sum_r),
        .oSum_i (lower_sum_i),
        .oDif_r (lower_dif_r),
        .oDif_i (lower_dif_i)
    );

    delay_line #(
        .BIT_WIDTH  (BIT_WIDTH),
        .DELAY_DEPTH(CORDIC_DEPTH)
    ) path0_delay (
        .Clk     (Clk),
        .Reset   (Reset),
        .iData_r (upper_sum_r),
        .iData_i (upper_sum_i),
        .oData_r (oData0_r),
        .oData_i (oData0_i)
    );

    fft_cordic_rotator #(
        .BIT_WIDTH      (BIT_WIDTH),
        .QUAD_WIDTH     (QUAD_WIDTH),
        .SIGMA_WIDTH    (SIGMA_WIDTH),
        .SCALE_CMD_WIDTH(SCALE_CMD_WIDTH)
    ) path1_rotator (
        .Clk         (Clk),
        .Reset       (Reset),
        .iData_r     (upper_dif_r),
        .iData_i     (upper_dif_i),
        .iQuad       (path1_quad),
        .iSigma      (path1_sigma),
        .iScale_cmds (path1_scale_cmds),
        .oData_r     (oData1_r),
        .oData_i     (oData1_i)
    );

    fft_cordic_rotator #(
        .BIT_WIDTH      (BIT_WIDTH),
        .QUAD_WIDTH     (QUAD_WIDTH),
        .SIGMA_WIDTH    (SIGMA_WIDTH),
        .SCALE_CMD_WIDTH(SCALE_CMD_WIDTH)
    ) path2_rotator (
        .Clk         (Clk),
        .Reset       (Reset),
        .iData_r     (lower_sum_r),
        .iData_i     (lower_sum_i),
        .iQuad       (path2_quad),
        .iSigma      (path2_sigma),
        .iScale_cmds (path2_scale_cmds),
        .oData_r     (oData2_r),
        .oData_i     (oData2_i)
    );

    fft_cordic_rotator #(
        .BIT_WIDTH      (BIT_WIDTH),
        .QUAD_WIDTH     (QUAD_WIDTH),
        .SIGMA_WIDTH    (SIGMA_WIDTH),
        .SCALE_CMD_WIDTH(SCALE_CMD_WIDTH)
    ) path3_rotator (
        .Clk         (Clk),
        .Reset       (Reset),
        .iData_r     (lower_dif_r),
        .iData_i     (lower_dif_i),
        .iQuad       (path3_quad),
        .iSigma      (path3_sigma),
        .iScale_cmds (path3_scale_cmds),
        .oData_r     (oData3_r),
        .oData_i     (oData3_i)
    );

endmodule