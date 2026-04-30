module fft_cordic_rotator #(
    parameter BIT_WIDTH       = 16,
    parameter QUAD_WIDTH      = 2,
    parameter SIGMA_WIDTH     = 24,
    parameter SCALE_CMD_WIDTH = 24,
    parameter FRAC_BITS       = 8,
    parameter GUARD_BITS      = 4
)(
    input  wire                              Clk,
    input  wire                              Reset,
    input  wire signed [BIT_WIDTH-1:0]       iData_r,
    input  wire signed [BIT_WIDTH-1:0]       iData_i,
    input  wire        [QUAD_WIDTH-1:0]      iQuad,
    input  wire        [SIGMA_WIDTH-1:0]     iSigma,
    input  wire        [SCALE_CMD_WIDTH-1:0] iScale_cmds,

    output reg signed [BIT_WIDTH-1:0]        oData_r,
    output reg signed [BIT_WIDTH-1:0]        oData_i
);

    localparam integer CORDIC_WIDTH = BIT_WIDTH + GUARD_BITS;
    localparam integer FINAL_SHIFT  = FRAC_BITS + GUARD_BITS;
    localparam integer MAX_SHIFT    = 8;
    localparam integer TERM_WIDTH   = CORDIC_WIDTH + MAX_SHIFT + 3;
    localparam integer PAIR_WIDTH   = TERM_WIDTH + 1;
    localparam integer FULL_WIDTH   = TERM_WIDTH + 2;

    reg signed [BIT_WIDTH-1:0] x0c;
    reg signed [BIT_WIDTH-1:0] y0c;

    always @(*) begin
        case (iQuad)
            2'd0: begin
                x0c =  iData_r;
                y0c =  iData_i;
            end

            2'd1: begin
                x0c = -iData_i;
                y0c =  iData_r;
            end

            2'd2: begin
                x0c = -iData_r;
                y0c = -iData_i;
            end

            2'd3: begin
                x0c =  iData_i;
                y0c = -iData_r;
            end

            default: begin
                x0c = iData_r;
                y0c = iData_i;
            end
        endcase
    end

    reg signed [CORDIC_WIDTH-1:0] x0r;
    reg signed [CORDIC_WIDTH-1:0] y0r;

    reg [SIGMA_WIDTH-1:0] sigma_s0;
    reg [SIGMA_WIDTH-1:0] sigma_s1;
    reg [SIGMA_WIDTH-1:0] sigma_s2;
    reg [SIGMA_WIDTH-1:0] sigma_s3;
    reg [SIGMA_WIDTH-1:0] sigma_s4;
    reg [SIGMA_WIDTH-1:0] sigma_s5;

    reg [SCALE_CMD_WIDTH-1:0] sc_d0;
    reg [SCALE_CMD_WIDTH-1:0] sc_d1;
    reg [SCALE_CMD_WIDTH-1:0] sc_d2;
    reg [SCALE_CMD_WIDTH-1:0] sc_d3;
    reg [SCALE_CMD_WIDTH-1:0] sc_d4;
    reg [SCALE_CMD_WIDTH-1:0] sc_d5;
    reg [SCALE_CMD_WIDTH-1:0] sc_d6;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            x0r      <= {CORDIC_WIDTH{1'b0}};
            y0r      <= {CORDIC_WIDTH{1'b0}};

            sigma_s0 <= {SIGMA_WIDTH{1'b0}};
            sigma_s1 <= {SIGMA_WIDTH{1'b0}};
            sigma_s2 <= {SIGMA_WIDTH{1'b0}};
            sigma_s3 <= {SIGMA_WIDTH{1'b0}};
            sigma_s4 <= {SIGMA_WIDTH{1'b0}};
            sigma_s5 <= {SIGMA_WIDTH{1'b0}};

            sc_d0    <= {SCALE_CMD_WIDTH{1'b0}};
            sc_d1    <= {SCALE_CMD_WIDTH{1'b0}};
            sc_d2    <= {SCALE_CMD_WIDTH{1'b0}};
            sc_d3    <= {SCALE_CMD_WIDTH{1'b0}};
            sc_d4    <= {SCALE_CMD_WIDTH{1'b0}};
            sc_d5    <= {SCALE_CMD_WIDTH{1'b0}};
            sc_d6    <= {SCALE_CMD_WIDTH{1'b0}};
        end else begin
            x0r      <= ({{GUARD_BITS{x0c[BIT_WIDTH-1]}}, x0c}) <<< GUARD_BITS;
            y0r      <= ({{GUARD_BITS{y0c[BIT_WIDTH-1]}}, y0c}) <<< GUARD_BITS;

            sigma_s0 <= iSigma;
            sigma_s1 <= sigma_s0;
            sigma_s2 <= sigma_s1;
            sigma_s3 <= sigma_s2;
            sigma_s4 <= sigma_s3;
            sigma_s5 <= sigma_s4;

            sc_d0    <= iScale_cmds;
            sc_d1    <= sc_d0;
            sc_d2    <= sc_d1;
            sc_d3    <= sc_d2;
            sc_d4    <= sc_d3;
            sc_d5    <= sc_d4;
            sc_d6    <= sc_d5;
        end
    end

    wire signed [CORDIC_WIDTH-1:0] x1c;
    wire signed [CORDIC_WIDTH-1:0] y1c;
    wire signed [CORDIC_WIDTH-1:0] x2c;
    wire signed [CORDIC_WIDTH-1:0] y2c;
    wire signed [CORDIC_WIDTH-1:0] x3c;
    wire signed [CORDIC_WIDTH-1:0] y3c;
    wire signed [CORDIC_WIDTH-1:0] x4c;
    wire signed [CORDIC_WIDTH-1:0] y4c;
    wire signed [CORDIC_WIDTH-1:0] x5c;
    wire signed [CORDIC_WIDTH-1:0] y5c;
    wire signed [CORDIC_WIDTH-1:0] x6c;
    wire signed [CORDIC_WIDTH-1:0] y6c;

    reg signed [CORDIC_WIDTH-1:0] x1r;
    reg signed [CORDIC_WIDTH-1:0] y1r;
    reg signed [CORDIC_WIDTH-1:0] x2r;
    reg signed [CORDIC_WIDTH-1:0] y2r;
    reg signed [CORDIC_WIDTH-1:0] x3r;
    reg signed [CORDIC_WIDTH-1:0] y3r;
    reg signed [CORDIC_WIDTH-1:0] x4r;
    reg signed [CORDIC_WIDTH-1:0] y4r;
    reg signed [CORDIC_WIDTH-1:0] x5r;
    reg signed [CORDIC_WIDTH-1:0] y5r;
    reg signed [CORDIC_WIDTH-1:0] x6r;
    reg signed [CORDIC_WIDTH-1:0] y6r;

    micro_rotation_stage #(
        .BIT_WIDTH   (CORDIC_WIDTH),
        .SHIFT_AMOUNT(0)
    ) stage0 (
        .iData_r(x0r),
        .iData_i(y0r),
        .iSigma (sigma_s0[23:20]),
        .oData_r(x1c),
        .oData_i(y1c)
    );

    micro_rotation_stage #(
        .BIT_WIDTH   (CORDIC_WIDTH),
        .SHIFT_AMOUNT(3)
    ) stage1 (
        .iData_r(x1r),
        .iData_i(y1r),
        .iSigma (sigma_s1[19:16]),
        .oData_r(x2c),
        .oData_i(y2c)
    );

    micro_rotation_stage #(
        .BIT_WIDTH   (CORDIC_WIDTH),
        .SHIFT_AMOUNT(6)
    ) stage2 (
        .iData_r(x2r),
        .iData_i(y2r),
        .iSigma (sigma_s2[15:12]),
        .oData_r(x3c),
        .oData_i(y3c)
    );

    micro_rotation_stage #(
        .BIT_WIDTH   (CORDIC_WIDTH),
        .SHIFT_AMOUNT(9)
    ) stage3 (
        .iData_r(x3r),
        .iData_i(y3r),
        .iSigma (sigma_s3[11:8]),
        .oData_r(x4c),
        .oData_i(y4c)
    );

    micro_rotation_stage #(
        .BIT_WIDTH   (CORDIC_WIDTH),
        .SHIFT_AMOUNT(12)
    ) stage4 (
        .iData_r(x4r),
        .iData_i(y4r),
        .iSigma (sigma_s4[7:4]),
        .oData_r(x5c),
        .oData_i(y5c)
    );

    micro_rotation_stage #(
        .BIT_WIDTH   (CORDIC_WIDTH),
        .SHIFT_AMOUNT(15)
    ) stage5 (
        .iData_r(x5r),
        .iData_i(y5r),
        .iSigma (sigma_s5[3:0]),
        .oData_r(x6c),
        .oData_i(y6c)
    );

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            x1r <= {CORDIC_WIDTH{1'b0}};
            y1r <= {CORDIC_WIDTH{1'b0}};
            x2r <= {CORDIC_WIDTH{1'b0}};
            y2r <= {CORDIC_WIDTH{1'b0}};
            x3r <= {CORDIC_WIDTH{1'b0}};
            y3r <= {CORDIC_WIDTH{1'b0}};
            x4r <= {CORDIC_WIDTH{1'b0}};
            y4r <= {CORDIC_WIDTH{1'b0}};
            x5r <= {CORDIC_WIDTH{1'b0}};
            y5r <= {CORDIC_WIDTH{1'b0}};
            x6r <= {CORDIC_WIDTH{1'b0}};
            y6r <= {CORDIC_WIDTH{1'b0}};
        end else begin
            x1r <= x1c;
            y1r <= y1c;
            x2r <= x2c;
            y2r <= y2c;
            x3r <= x3c;
            y3r <= y3c;
            x4r <= x4c;
            y4r <= y4c;
            x5r <= x5c;
            y5r <= y5c;
            x6r <= x6c;
            y6r <= y6c;
        end
    end

    wire       v0;
    wire       n0;
    wire [3:0] s0;
    wire       v1;
    wire       n1;
    wire [3:0] s1;
    wire       v2;
    wire       n2;
    wire [3:0] s2;
    wire       v3;
    wire       n3;
    wire [3:0] s3;

    assign v0 = sc_d6[5];
    assign n0 = sc_d6[4];
    assign s0 = sc_d6[3:0];

    assign v1 = sc_d6[11];
    assign n1 = sc_d6[10];
    assign s1 = sc_d6[9:6];

    assign v2 = sc_d6[17];
    assign n2 = sc_d6[16];
    assign s2 = sc_d6[15:12];

    assign v3 = sc_d6[23];
    assign n3 = sc_d6[22];
    assign s3 = sc_d6[21:18];

    wire signed [TERM_WIDTH-1:0] x6_e;
    wire signed [TERM_WIDTH-1:0] y6_e;

    assign x6_e = {{(TERM_WIDTH-CORDIC_WIDTH){x6r[CORDIC_WIDTH-1]}}, x6r};
    assign y6_e = {{(TERM_WIDTH-CORDIC_WIDTH){y6r[CORDIC_WIDTH-1]}}, y6r};

    wire signed [TERM_WIDTH-1:0] tx0;
    wire signed [TERM_WIDTH-1:0] tx1;
    wire signed [TERM_WIDTH-1:0] tx2;
    wire signed [TERM_WIDTH-1:0] tx3;

    wire signed [TERM_WIDTH-1:0] ty0;
    wire signed [TERM_WIDTH-1:0] ty1;
    wire signed [TERM_WIDTH-1:0] ty2;
    wire signed [TERM_WIDTH-1:0] ty3;

    assign tx0 = v0 ? (n0 ? -(x6_e <<< s0) : (x6_e <<< s0)) : {TERM_WIDTH{1'b0}};
    assign tx1 = v1 ? (n1 ? -(x6_e <<< s1) : (x6_e <<< s1)) : {TERM_WIDTH{1'b0}};
    assign tx2 = v2 ? (n2 ? -(x6_e <<< s2) : (x6_e <<< s2)) : {TERM_WIDTH{1'b0}};
    assign tx3 = v3 ? (n3 ? -(x6_e <<< s3) : (x6_e <<< s3)) : {TERM_WIDTH{1'b0}};

    assign ty0 = v0 ? (n0 ? -(y6_e <<< s0) : (y6_e <<< s0)) : {TERM_WIDTH{1'b0}};
    assign ty1 = v1 ? (n1 ? -(y6_e <<< s1) : (y6_e <<< s1)) : {TERM_WIDTH{1'b0}};
    assign ty2 = v2 ? (n2 ? -(y6_e <<< s2) : (y6_e <<< s2)) : {TERM_WIDTH{1'b0}};
    assign ty3 = v3 ? (n3 ? -(y6_e <<< s3) : (y6_e <<< s3)) : {TERM_WIDTH{1'b0}};

    reg signed [TERM_WIDTH-1:0] tx0r;
    reg signed [TERM_WIDTH-1:0] tx1r;
    reg signed [TERM_WIDTH-1:0] tx2r;
    reg signed [TERM_WIDTH-1:0] tx3r;

    reg signed [TERM_WIDTH-1:0] ty0r;
    reg signed [TERM_WIDTH-1:0] ty1r;
    reg signed [TERM_WIDTH-1:0] ty2r;
    reg signed [TERM_WIDTH-1:0] ty3r;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            tx0r <= {TERM_WIDTH{1'b0}};
            tx1r <= {TERM_WIDTH{1'b0}};
            tx2r <= {TERM_WIDTH{1'b0}};
            tx3r <= {TERM_WIDTH{1'b0}};

            ty0r <= {TERM_WIDTH{1'b0}};
            ty1r <= {TERM_WIDTH{1'b0}};
            ty2r <= {TERM_WIDTH{1'b0}};
            ty3r <= {TERM_WIDTH{1'b0}};
        end else begin
            tx0r <= tx0;
            tx1r <= tx1;
            tx2r <= tx2;
            tx3r <= tx3;

            ty0r <= ty0;
            ty1r <= ty1;
            ty2r <= ty2;
            ty3r <= ty3;
        end
    end

    wire signed [PAIR_WIDTH-1:0] px01;
    wire signed [PAIR_WIDTH-1:0] px23;
    wire signed [PAIR_WIDTH-1:0] py01;
    wire signed [PAIR_WIDTH-1:0] py23;

    assign px01 = $signed({tx0r[TERM_WIDTH-1], tx0r}) + $signed({tx1r[TERM_WIDTH-1], tx1r});
    assign px23 = $signed({tx2r[TERM_WIDTH-1], tx2r}) + $signed({tx3r[TERM_WIDTH-1], tx3r});

    assign py01 = $signed({ty0r[TERM_WIDTH-1], ty0r}) + $signed({ty1r[TERM_WIDTH-1], ty1r});
    assign py23 = $signed({ty2r[TERM_WIDTH-1], ty2r}) + $signed({ty3r[TERM_WIDTH-1], ty3r});

    reg signed [PAIR_WIDTH-1:0] px01r;
    reg signed [PAIR_WIDTH-1:0] px23r;
    reg signed [PAIR_WIDTH-1:0] py01r;
    reg signed [PAIR_WIDTH-1:0] py23r;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            px01r <= {PAIR_WIDTH{1'b0}};
            px23r <= {PAIR_WIDTH{1'b0}};
            py01r <= {PAIR_WIDTH{1'b0}};
            py23r <= {PAIR_WIDTH{1'b0}};
        end else begin
            px01r <= px01;
            px23r <= px23;
            py01r <= py01;
            py23r <= py23;
        end
    end

    wire signed [FULL_WIDTH-1:0] full_x;
    wire signed [FULL_WIDTH-1:0] full_y;

    assign full_x = $signed({px01r[PAIR_WIDTH-1], px01r}) + $signed({px23r[PAIR_WIDTH-1], px23r});
    assign full_y = $signed({py01r[PAIR_WIDTH-1], py01r}) + $signed({py23r[PAIR_WIDTH-1], py23r});

    wire signed [FULL_WIDTH-1:0] round_bias_pos;
    wire signed [FULL_WIDTH-1:0] round_bias_neg;

    assign round_bias_pos = {{(FULL_WIDTH-FINAL_SHIFT){1'b0}}, 1'b1, {(FINAL_SHIFT-1){1'b0}}};
    assign round_bias_neg = {{(FULL_WIDTH-(FINAL_SHIFT-1)){1'b0}}, {(FINAL_SHIFT-1){1'b1}}};

    wire signed [FULL_WIDTH-1:0] full_x_round;
    wire signed [FULL_WIDTH-1:0] full_y_round;

    assign full_x_round = full_x + (full_x[FULL_WIDTH-1] ? round_bias_neg : round_bias_pos);
    assign full_y_round = full_y + (full_y[FULL_WIDTH-1] ? round_bias_neg : round_bias_pos);

    wire signed [FULL_WIDTH-1:0] scaled_x;
    wire signed [FULL_WIDTH-1:0] scaled_y;

    assign scaled_x = full_x_round >>> FINAL_SHIFT;
    assign scaled_y = full_y_round >>> FINAL_SHIFT;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            oData_r <= {BIT_WIDTH{1'b0}};
            oData_i <= {BIT_WIDTH{1'b0}};
        end else begin
            oData_r <= scaled_x[BIT_WIDTH-1:0];
            oData_i <= scaled_y[BIT_WIDTH-1:0];
        end
    end

endmodule