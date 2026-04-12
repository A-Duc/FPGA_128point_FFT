module fft_cordic_rotator #(
    parameter BIT_WIDTH       = 16,
    parameter QUAD_WIDTH      = 2,
    parameter SIGMA_WIDTH     = 24,
    parameter SCALE_CMD_WIDTH = 28
)(
    input  wire                         Clk,
    input  wire                         Reset,
    input  wire signed [BIT_WIDTH-1:0]  iData_r,
    input  wire signed [BIT_WIDTH-1:0]  iData_i,
    input  wire        [QUAD_WIDTH-1:0] iQuad,
    input  wire        [SIGMA_WIDTH-1:0] iSigma,
    input  wire        [SCALE_CMD_WIDTH-1:0] iScale_cmds,

    output reg signed [BIT_WIDTH-1:0]   oData_r,
    output reg signed [BIT_WIDTH-1:0]   oData_i
);

    localparam integer NUM_ROT_STAGES   = 6;
    localparam integer SCALE_FIELD_WIDTH = 7;
    localparam integer EXT_WIDTH         = BIT_WIDTH + 32;
    localparam integer PAIR_SUM_WIDTH    = EXT_WIDTH + 1;
    localparam integer FULL_SUM_WIDTH    = EXT_WIDTH + 2;
    localparam integer OUTPUT_TRUNC_LSB  = 30;
    localparam integer OUTPUT_TRUNC_MSB  = OUTPUT_TRUNC_LSB + BIT_WIDTH - 1;

    reg signed [BIT_WIDTH-1:0] quadrant_rot_r;
    reg signed [BIT_WIDTH-1:0] quadrant_rot_i;

    wire [SIGMA_WIDTH-1:0] sigma_stage0;

    reg [SIGMA_WIDTH-1:0] sigma_stage1;
    reg [SIGMA_WIDTH-1:0] sigma_stage2;
    reg [SIGMA_WIDTH-1:0] sigma_stage3;
    reg [SIGMA_WIDTH-1:0] sigma_stage4;
    reg [SIGMA_WIDTH-1:0] sigma_stage5;

    reg [SCALE_CMD_WIDTH-1:0] scale_cmds_d1;
    reg [SCALE_CMD_WIDTH-1:0] scale_cmds_d2;
    reg [SCALE_CMD_WIDTH-1:0] scale_cmds_d3;
    reg [SCALE_CMD_WIDTH-1:0] scale_cmds_d4;
    reg [SCALE_CMD_WIDTH-1:0] scale_cmds_d5;
    reg [SCALE_CMD_WIDTH-1:0] scale_cmds_d6;

    wire signed [BIT_WIDTH-1:0] stage1_r_comb;
    wire signed [BIT_WIDTH-1:0] stage1_i_comb;
    wire signed [BIT_WIDTH-1:0] stage2_r_comb;
    wire signed [BIT_WIDTH-1:0] stage2_i_comb;
    wire signed [BIT_WIDTH-1:0] stage3_r_comb;
    wire signed [BIT_WIDTH-1:0] stage3_i_comb;
    wire signed [BIT_WIDTH-1:0] stage4_r_comb;
    wire signed [BIT_WIDTH-1:0] stage4_i_comb;
    wire signed [BIT_WIDTH-1:0] stage5_r_comb;
    wire signed [BIT_WIDTH-1:0] stage5_i_comb;
    wire signed [BIT_WIDTH-1:0] stage6_r_comb;
    wire signed [BIT_WIDTH-1:0] stage6_i_comb;

    reg signed [BIT_WIDTH-1:0] stage1_r_reg;
    reg signed [BIT_WIDTH-1:0] stage1_i_reg;
    reg signed [BIT_WIDTH-1:0] stage2_r_reg;
    reg signed [BIT_WIDTH-1:0] stage2_i_reg;
    reg signed [BIT_WIDTH-1:0] stage3_r_reg;
    reg signed [BIT_WIDTH-1:0] stage3_i_reg;
    reg signed [BIT_WIDTH-1:0] stage4_r_reg;
    reg signed [BIT_WIDTH-1:0] stage4_i_reg;
    reg signed [BIT_WIDTH-1:0] stage5_r_reg;
    reg signed [BIT_WIDTH-1:0] stage5_i_reg;
    reg signed [BIT_WIDTH-1:0] stage6_r_reg;
    reg signed [BIT_WIDTH-1:0] stage6_i_reg;

    wire [SCALE_FIELD_WIDTH-1:0] scale_cmd0;
    wire [SCALE_FIELD_WIDTH-1:0] scale_cmd1;
    wire [SCALE_FIELD_WIDTH-1:0] scale_cmd2;
    wire [SCALE_FIELD_WIDTH-1:0] scale_cmd3;

    wire signed [EXT_WIDTH-1:0] stage6_r_ext;
    wire signed [EXT_WIDTH-1:0] stage6_i_ext;

    wire signed [EXT_WIDTH-1:0] scale_term_r0;
    wire signed [EXT_WIDTH-1:0] scale_term_r1;
    wire signed [EXT_WIDTH-1:0] scale_term_r2;
    wire signed [EXT_WIDTH-1:0] scale_term_r3;
    wire signed [EXT_WIDTH-1:0] scale_term_i0;
    wire signed [EXT_WIDTH-1:0] scale_term_i1;
    wire signed [EXT_WIDTH-1:0] scale_term_i2;
    wire signed [EXT_WIDTH-1:0] scale_term_i3;

    reg signed [EXT_WIDTH-1:0] scale_term_r0_reg;
    reg signed [EXT_WIDTH-1:0] scale_term_r1_reg;
    reg signed [EXT_WIDTH-1:0] scale_term_r2_reg;
    reg signed [EXT_WIDTH-1:0] scale_term_r3_reg;
    reg signed [EXT_WIDTH-1:0] scale_term_i0_reg;
    reg signed [EXT_WIDTH-1:0] scale_term_i1_reg;
    reg signed [EXT_WIDTH-1:0] scale_term_i2_reg;
    reg signed [EXT_WIDTH-1:0] scale_term_i3_reg;

    wire signed [PAIR_SUM_WIDTH-1:0] pair_sum_r01;
    wire signed [PAIR_SUM_WIDTH-1:0] pair_sum_r23;
    wire signed [PAIR_SUM_WIDTH-1:0] pair_sum_i01;
    wire signed [PAIR_SUM_WIDTH-1:0] pair_sum_i23;

    reg signed [PAIR_SUM_WIDTH-1:0] pair_sum_r01_reg;
    reg signed [PAIR_SUM_WIDTH-1:0] pair_sum_r23_reg;
    reg signed [PAIR_SUM_WIDTH-1:0] pair_sum_i01_reg;
    reg signed [PAIR_SUM_WIDTH-1:0] pair_sum_i23_reg;

    wire signed [FULL_SUM_WIDTH-1:0] full_sum_r;
    wire signed [FULL_SUM_WIDTH-1:0] full_sum_i;

    assign sigma_stage0 = iSigma;

    always @(*) begin
        case (iQuad)
            2'd0: begin
                quadrant_rot_r =  iData_r;
                quadrant_rot_i =  iData_i;
            end
            2'd1: begin
                quadrant_rot_r = -iData_i;
                quadrant_rot_i =  iData_r;
            end
            2'd2: begin
                quadrant_rot_r = -iData_r;
                quadrant_rot_i = -iData_i;
            end
            2'd3: begin
                quadrant_rot_r =  iData_i;
                quadrant_rot_i = -iData_r;
            end
            default: begin
                quadrant_rot_r =  iData_r;
                quadrant_rot_i =  iData_i;
            end
        endcase
    end

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            sigma_stage1 <= {SIGMA_WIDTH{1'b0}};
            sigma_stage2 <= {SIGMA_WIDTH{1'b0}};
            sigma_stage3 <= {SIGMA_WIDTH{1'b0}};
            sigma_stage4 <= {SIGMA_WIDTH{1'b0}};
            sigma_stage5 <= {SIGMA_WIDTH{1'b0}};

            scale_cmds_d1 <= {SCALE_CMD_WIDTH{1'b0}};
            scale_cmds_d2 <= {SCALE_CMD_WIDTH{1'b0}};
            scale_cmds_d3 <= {SCALE_CMD_WIDTH{1'b0}};
            scale_cmds_d4 <= {SCALE_CMD_WIDTH{1'b0}};
            scale_cmds_d5 <= {SCALE_CMD_WIDTH{1'b0}};
            scale_cmds_d6 <= {SCALE_CMD_WIDTH{1'b0}};
        end else begin
            sigma_stage1 <= sigma_stage0;
            sigma_stage2 <= sigma_stage1;
            sigma_stage3 <= sigma_stage2;
            sigma_stage4 <= sigma_stage3;
            sigma_stage5 <= sigma_stage4;

            scale_cmds_d1 <= iScale_cmds;
            scale_cmds_d2 <= scale_cmds_d1;
            scale_cmds_d3 <= scale_cmds_d2;
            scale_cmds_d4 <= scale_cmds_d3;
            scale_cmds_d5 <= scale_cmds_d4;
            scale_cmds_d6 <= scale_cmds_d5;
        end
    end

    micro_rotation_stage #(
        .BIT_WIDTH   (BIT_WIDTH),
        .SHIFT_AMOUNT(0)
    ) stage0 (
        .iData_r(quadrant_rot_r),
        .iData_i(quadrant_rot_i),
        .iSigma (sigma_stage0[23:20]),
        .oData_r(stage1_r_comb),
        .oData_i(stage1_i_comb)
    );

    micro_rotation_stage #(
        .BIT_WIDTH   (BIT_WIDTH),
        .SHIFT_AMOUNT(3)
    ) stage1 (
        .iData_r(stage1_r_reg),
        .iData_i(stage1_i_reg),
        .iSigma (sigma_stage1[19:16]),
        .oData_r(stage2_r_comb),
        .oData_i(stage2_i_comb)
    );

    micro_rotation_stage #(
        .BIT_WIDTH   (BIT_WIDTH),
        .SHIFT_AMOUNT(6)
    ) stage2 (
        .iData_r(stage2_r_reg),
        .iData_i(stage2_i_reg),
        .iSigma (sigma_stage2[15:12]),
        .oData_r(stage3_r_comb),
        .oData_i(stage3_i_comb)
    );

    micro_rotation_stage #(
        .BIT_WIDTH   (BIT_WIDTH),
        .SHIFT_AMOUNT(9)
    ) stage3 (
        .iData_r(stage3_r_reg),
        .iData_i(stage3_i_reg),
        .iSigma (sigma_stage3[11:8]),
        .oData_r(stage4_r_comb),
        .oData_i(stage4_i_comb)
    );

    micro_rotation_stage #(
        .BIT_WIDTH   (BIT_WIDTH),
        .SHIFT_AMOUNT(12)
    ) stage4 (
        .iData_r(stage4_r_reg),
        .iData_i(stage4_i_reg),
        .iSigma (sigma_stage4[7:4]),
        .oData_r(stage5_r_comb),
        .oData_i(stage5_i_comb)
    );

    micro_rotation_stage #(
        .BIT_WIDTH   (BIT_WIDTH),
        .SHIFT_AMOUNT(15)
    ) stage5 (
        .iData_r(stage5_r_reg),
        .iData_i(stage5_i_reg),
        .iSigma (sigma_stage5[3:0]),
        .oData_r(stage6_r_comb),
        .oData_i(stage6_i_comb)
    );

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            stage1_r_reg <= {BIT_WIDTH{1'b0}};
            stage1_i_reg <= {BIT_WIDTH{1'b0}};
            stage2_r_reg <= {BIT_WIDTH{1'b0}};
            stage2_i_reg <= {BIT_WIDTH{1'b0}};
            stage3_r_reg <= {BIT_WIDTH{1'b0}};
            stage3_i_reg <= {BIT_WIDTH{1'b0}};
            stage4_r_reg <= {BIT_WIDTH{1'b0}};
            stage4_i_reg <= {BIT_WIDTH{1'b0}};
            stage5_r_reg <= {BIT_WIDTH{1'b0}};
            stage5_i_reg <= {BIT_WIDTH{1'b0}};
            stage6_r_reg <= {BIT_WIDTH{1'b0}};
            stage6_i_reg <= {BIT_WIDTH{1'b0}};
        end else begin
            stage1_r_reg <= stage1_r_comb;
            stage1_i_reg <= stage1_i_comb;
            stage2_r_reg <= stage2_r_comb;
            stage2_i_reg <= stage2_i_comb;
            stage3_r_reg <= stage3_r_comb;
            stage3_i_reg <= stage3_i_comb;
            stage4_r_reg <= stage4_r_comb;
            stage4_i_reg <= stage4_i_comb;
            stage5_r_reg <= stage5_r_comb;
            stage5_i_reg <= stage5_i_comb;
            stage6_r_reg <= stage6_r_comb;
            stage6_i_reg <= stage6_i_comb;
        end
    end

    assign scale_cmd0 = scale_cmds_d6[6:0];
    assign scale_cmd1 = scale_cmds_d6[13:7];
    assign scale_cmd2 = scale_cmds_d6[20:14];
    assign scale_cmd3 = scale_cmds_d6[27:21];

    assign stage6_r_ext = {{32{stage6_r_reg[BIT_WIDTH-1]}}, stage6_r_reg};
    assign stage6_i_ext = {{32{stage6_i_reg[BIT_WIDTH-1]}}, stage6_i_reg};

    assign scale_term_r0 = scale_cmd0[6] ? (scale_cmd0[5] ? -(stage6_r_ext <<< scale_cmd0[4:0]) : (stage6_r_ext <<< scale_cmd0[4:0])) : {EXT_WIDTH{1'b0}};
    assign scale_term_r1 = scale_cmd1[6] ? (scale_cmd1[5] ? -(stage6_r_ext <<< scale_cmd1[4:0]) : (stage6_r_ext <<< scale_cmd1[4:0])) : {EXT_WIDTH{1'b0}};
    assign scale_term_r2 = scale_cmd2[6] ? (scale_cmd2[5] ? -(stage6_r_ext <<< scale_cmd2[4:0]) : (stage6_r_ext <<< scale_cmd2[4:0])) : {EXT_WIDTH{1'b0}};
    assign scale_term_r3 = scale_cmd3[6] ? (scale_cmd3[5] ? -(stage6_r_ext <<< scale_cmd3[4:0]) : (stage6_r_ext <<< scale_cmd3[4:0])) : {EXT_WIDTH{1'b0}};

    assign scale_term_i0 = scale_cmd0[6] ? (scale_cmd0[5] ? -(stage6_i_ext <<< scale_cmd0[4:0]) : (stage6_i_ext <<< scale_cmd0[4:0])) : {EXT_WIDTH{1'b0}};
    assign scale_term_i1 = scale_cmd1[6] ? (scale_cmd1[5] ? -(stage6_i_ext <<< scale_cmd1[4:0]) : (stage6_i_ext <<< scale_cmd1[4:0])) : {EXT_WIDTH{1'b0}};
    assign scale_term_i2 = scale_cmd2[6] ? (scale_cmd2[5] ? -(stage6_i_ext <<< scale_cmd2[4:0]) : (stage6_i_ext <<< scale_cmd2[4:0])) : {EXT_WIDTH{1'b0}};
    assign scale_term_i3 = scale_cmd3[6] ? (scale_cmd3[5] ? -(stage6_i_ext <<< scale_cmd3[4:0]) : (stage6_i_ext <<< scale_cmd3[4:0])) : {EXT_WIDTH{1'b0}};

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            scale_term_r0_reg <= {EXT_WIDTH{1'b0}};
            scale_term_r1_reg <= {EXT_WIDTH{1'b0}};
            scale_term_r2_reg <= {EXT_WIDTH{1'b0}};
            scale_term_r3_reg <= {EXT_WIDTH{1'b0}};
            scale_term_i0_reg <= {EXT_WIDTH{1'b0}};
            scale_term_i1_reg <= {EXT_WIDTH{1'b0}};
            scale_term_i2_reg <= {EXT_WIDTH{1'b0}};
            scale_term_i3_reg <= {EXT_WIDTH{1'b0}};
        end else begin
            scale_term_r0_reg <= scale_term_r0;
            scale_term_r1_reg <= scale_term_r1;
            scale_term_r2_reg <= scale_term_r2;
            scale_term_r3_reg <= scale_term_r3;
            scale_term_i0_reg <= scale_term_i0;
            scale_term_i1_reg <= scale_term_i1;
            scale_term_i2_reg <= scale_term_i2;
            scale_term_i3_reg <= scale_term_i3;
        end
    end

    assign pair_sum_r01 = scale_term_r0_reg + scale_term_r1_reg;
    assign pair_sum_r23 = scale_term_r2_reg + scale_term_r3_reg;
    assign pair_sum_i01 = scale_term_i0_reg + scale_term_i1_reg;
    assign pair_sum_i23 = scale_term_i2_reg + scale_term_i3_reg;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            pair_sum_r01_reg <= {PAIR_SUM_WIDTH{1'b0}};
            pair_sum_r23_reg <= {PAIR_SUM_WIDTH{1'b0}};
            pair_sum_i01_reg <= {PAIR_SUM_WIDTH{1'b0}};
            pair_sum_i23_reg <= {PAIR_SUM_WIDTH{1'b0}};
        end else begin
            pair_sum_r01_reg <= pair_sum_r01;
            pair_sum_r23_reg <= pair_sum_r23;
            pair_sum_i01_reg <= pair_sum_i01;
            pair_sum_i23_reg <= pair_sum_i23;
        end
    end

    assign full_sum_r = pair_sum_r01_reg + pair_sum_r23_reg;
    assign full_sum_i = pair_sum_i01_reg + pair_sum_i23_reg;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            oData_r <= {BIT_WIDTH{1'b0}};
            oData_i <= {BIT_WIDTH{1'b0}};
        end else begin
            oData_r <= full_sum_r[OUTPUT_TRUNC_MSB:OUTPUT_TRUNC_LSB];
            oData_i <= full_sum_i[OUTPUT_TRUNC_MSB:OUTPUT_TRUNC_LSB];
        end
    end

endmodule