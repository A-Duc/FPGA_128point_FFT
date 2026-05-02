module fft_cordic_rotator #(
    parameter BIT_WIDTH      = 16,
    parameter QUAD_WIDTH     = 2,
    parameter SIGMA_WIDTH    = 24,
    parameter SCALE_ID_WIDTH = 4,
    parameter FRAC_BITS      = 8
)(
    input  wire                             Clk,
    input  wire                             Reset,

    input  wire signed [BIT_WIDTH-1:0]      iData_r,
    input  wire signed [BIT_WIDTH-1:0]      iData_i,

    input  wire        [QUAD_WIDTH-1:0]     iQuad,
    input  wire        [SIGMA_WIDTH-1:0]    iSigma,
    input  wire        [SCALE_ID_WIDTH-1:0] iScale_id,

    output reg signed [BIT_WIDTH-1:0]       oData_r,
    output reg signed [BIT_WIDTH-1:0]       oData_i
);

    localparam integer EXT_WIDTH = BIT_WIDTH + FRAC_BITS;

    // -------------------------------------------------------------------------
    // Front-end quadrant rotation
    // -------------------------------------------------------------------------
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

    // -------------------------------------------------------------------------
    // Front-end pipeline register and ROM command delay pipeline
    // -------------------------------------------------------------------------
    reg signed [BIT_WIDTH-1:0] x0r;
    reg signed [BIT_WIDTH-1:0] y0r;

    reg [SIGMA_WIDTH-1:0] sigma_s0;
    reg [SIGMA_WIDTH-1:0] sigma_s1;
    reg [SIGMA_WIDTH-1:0] sigma_s2;
    reg [SIGMA_WIDTH-1:0] sigma_s3;
    reg [SIGMA_WIDTH-1:0] sigma_s4;
    reg [SIGMA_WIDTH-1:0] sigma_s5;

    reg [SCALE_ID_WIDTH-1:0] sc_id_d0;
    reg [SCALE_ID_WIDTH-1:0] sc_id_d1;
    reg [SCALE_ID_WIDTH-1:0] sc_id_d2;
    reg [SCALE_ID_WIDTH-1:0] sc_id_d3;
    reg [SCALE_ID_WIDTH-1:0] sc_id_d4;
    reg [SCALE_ID_WIDTH-1:0] sc_id_d5;
    reg [SCALE_ID_WIDTH-1:0] sc_id_d6;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            x0r      <= {BIT_WIDTH{1'b0}};
            y0r      <= {BIT_WIDTH{1'b0}};

            sigma_s0 <= {SIGMA_WIDTH{1'b0}};
            sigma_s1 <= {SIGMA_WIDTH{1'b0}};
            sigma_s2 <= {SIGMA_WIDTH{1'b0}};
            sigma_s3 <= {SIGMA_WIDTH{1'b0}};
            sigma_s4 <= {SIGMA_WIDTH{1'b0}};
            sigma_s5 <= {SIGMA_WIDTH{1'b0}};

            sc_id_d0 <= {SCALE_ID_WIDTH{1'b0}};
            sc_id_d1 <= {SCALE_ID_WIDTH{1'b0}};
            sc_id_d2 <= {SCALE_ID_WIDTH{1'b0}};
            sc_id_d3 <= {SCALE_ID_WIDTH{1'b0}};
            sc_id_d4 <= {SCALE_ID_WIDTH{1'b0}};
            sc_id_d5 <= {SCALE_ID_WIDTH{1'b0}};
            sc_id_d6 <= {SCALE_ID_WIDTH{1'b0}};
        end
        else begin
            x0r      <= x0c;
            y0r      <= y0c;

            sigma_s0 <= iSigma;
            sigma_s1 <= sigma_s0;
            sigma_s2 <= sigma_s1;
            sigma_s3 <= sigma_s2;
            sigma_s4 <= sigma_s3;
            sigma_s5 <= sigma_s4;

            sc_id_d0 <= iScale_id;
            sc_id_d1 <= sc_id_d0;
            sc_id_d2 <= sc_id_d1;
            sc_id_d3 <= sc_id_d2;
            sc_id_d4 <= sc_id_d3;
            sc_id_d5 <= sc_id_d4;
            sc_id_d6 <= sc_id_d5;
        end
    end

    // -------------------------------------------------------------------------
    // Micro-rotation stages
    // -------------------------------------------------------------------------
    wire signed [BIT_WIDTH-1:0] x1c;
    wire signed [BIT_WIDTH-1:0] y1c;
    wire signed [BIT_WIDTH-1:0] x2c;
    wire signed [BIT_WIDTH-1:0] y2c;
    wire signed [BIT_WIDTH-1:0] x3c;
    wire signed [BIT_WIDTH-1:0] y3c;
    wire signed [BIT_WIDTH-1:0] x4c;
    wire signed [BIT_WIDTH-1:0] y4c;
    wire signed [BIT_WIDTH-1:0] x5c;
    wire signed [BIT_WIDTH-1:0] y5c;
    wire signed [BIT_WIDTH-1:0] x6c;
    wire signed [BIT_WIDTH-1:0] y6c;

    reg signed [BIT_WIDTH-1:0] x1r;
    reg signed [BIT_WIDTH-1:0] y1r;
    reg signed [BIT_WIDTH-1:0] x2r;
    reg signed [BIT_WIDTH-1:0] y2r;
    reg signed [BIT_WIDTH-1:0] x3r;
    reg signed [BIT_WIDTH-1:0] y3r;
    reg signed [BIT_WIDTH-1:0] x4r;
    reg signed [BIT_WIDTH-1:0] y4r;
    reg signed [BIT_WIDTH-1:0] x5r;
    reg signed [BIT_WIDTH-1:0] y5r;
    reg signed [BIT_WIDTH-1:0] x6r;
    reg signed [BIT_WIDTH-1:0] y6r;

    micro_rotation_stage #(.BIT_WIDTH(BIT_WIDTH), .SHIFT_AMOUNT(0)) stage0 (
        .iData_r(x0r), .iData_i(y0r), .iSigma(sigma_s0[23:20]), .oData_r(x1c), .oData_i(y1c)
    );

    micro_rotation_stage #(.BIT_WIDTH(BIT_WIDTH), .SHIFT_AMOUNT(3)) stage1 (
        .iData_r(x1r), .iData_i(y1r), .iSigma(sigma_s1[19:16]), .oData_r(x2c), .oData_i(y2c)
    );

    micro_rotation_stage #(.BIT_WIDTH(BIT_WIDTH), .SHIFT_AMOUNT(6)) stage2 (
        .iData_r(x2r), .iData_i(y2r), .iSigma(sigma_s2[15:12]), .oData_r(x3c), .oData_i(y3c)
    );

    micro_rotation_stage #(.BIT_WIDTH(BIT_WIDTH), .SHIFT_AMOUNT(9)) stage3 (
        .iData_r(x3r), .iData_i(y3r), .iSigma(sigma_s3[11:8]), .oData_r(x4c), .oData_i(y4c)
    );

    micro_rotation_stage #(.BIT_WIDTH(BIT_WIDTH), .SHIFT_AMOUNT(12)) stage4 (
        .iData_r(x4r), .iData_i(y4r), .iSigma(sigma_s4[7:4]), .oData_r(x5c), .oData_i(y5c)
    );

    micro_rotation_stage #(.BIT_WIDTH(BIT_WIDTH), .SHIFT_AMOUNT(15)) stage5 (
        .iData_r(x5r), .iData_i(y5r), .iSigma(sigma_s5[3:0]), .oData_r(x6c), .oData_i(y6c)
    );

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            x1r <= {BIT_WIDTH{1'b0}}; y1r <= {BIT_WIDTH{1'b0}};
            x2r <= {BIT_WIDTH{1'b0}}; y2r <= {BIT_WIDTH{1'b0}};
            x3r <= {BIT_WIDTH{1'b0}}; y3r <= {BIT_WIDTH{1'b0}};
            x4r <= {BIT_WIDTH{1'b0}}; y4r <= {BIT_WIDTH{1'b0}};
            x5r <= {BIT_WIDTH{1'b0}}; y5r <= {BIT_WIDTH{1'b0}};
            x6r <= {BIT_WIDTH{1'b0}}; y6r <= {BIT_WIDTH{1'b0}};
        end else begin
            x1r <= x1c; y1r <= y1c;
            x2r <= x2c; y2r <= y2c;
            x3r <= x3c; y3r <= y3c;
            x4r <= x4c; y4r <= y4c;
            x5r <= x5c; y5r <= y5c;
            x6r <= x6c; y6r <= y6c;
        end
    end

    // -------------------------------------------------------------------------
    // Scale section: scale_id decoder
    // -------------------------------------------------------------------------
    // scale_id mapping:
    // 0  -> 24'h000028 : +2^8
    // 1  -> 24'h0008E6 : +2^6 +2^3
    // 2  -> 24'h000C68 : +2^8 -2^1
    // 3  -> 24'h000CE8 : +2^8 -2^3
    // 4  -> 24'h020CE8 : +2^8 -2^3 +2^0
    // 5  -> 24'h020D28 : +2^8 -2^4 +2^0
    // 6  -> 24'h024967 : +2^7 +2^5 +2^4
    // 7  -> 24'h030D28 : +2^8 -2^4 -2^0
    // 8  -> 24'h863967 : +2^7 +2^5 +2^3 +2^1
    // 9  -> 24'hC23966 : +2^6 +2^5 +2^3 -2^0
    // 10 -> 24'hC32D27 : +2^7 -2^4 -2^2 -2^0
    // 11 -> 24'hC739A7 : +2^7 +2^6 -2^3 -2^1

    wire signed [EXT_WIDTH-1:0] x6_e;
    wire signed [EXT_WIDTH-1:0] y6_e;

    assign x6_e = {{FRAC_BITS{x6r[BIT_WIDTH-1]}}, x6r};
    assign y6_e = {{FRAC_BITS{y6r[BIT_WIDTH-1]}}, y6r};

    reg signed [EXT_WIDTH-1:0] tx0;
    reg signed [EXT_WIDTH-1:0] tx1;
    reg signed [EXT_WIDTH-1:0] tx2;
    reg signed [EXT_WIDTH-1:0] tx3;

    reg signed [EXT_WIDTH-1:0] ty0;
    reg signed [EXT_WIDTH-1:0] ty1;
    reg signed [EXT_WIDTH-1:0] ty2;
    reg signed [EXT_WIDTH-1:0] ty3;

    always @(*) begin
        tx0 = {EXT_WIDTH{1'b0}}; tx1 = {EXT_WIDTH{1'b0}};
        tx2 = {EXT_WIDTH{1'b0}}; tx3 = {EXT_WIDTH{1'b0}};
        ty0 = {EXT_WIDTH{1'b0}}; ty1 = {EXT_WIDTH{1'b0}};
        ty2 = {EXT_WIDTH{1'b0}}; ty3 = {EXT_WIDTH{1'b0}};

        case (sc_id_d6)
            4'd0: begin
                tx0 =  (x6_e <<< 8);
                ty0 =  (y6_e <<< 8);
            end
            4'd1: begin
                tx0 =  (x6_e <<< 6); tx1 =  (x6_e <<< 3);
                ty0 =  (y6_e <<< 6); ty1 =  (y6_e <<< 3);
            end
            4'd2: begin
                tx0 =  (x6_e <<< 8); tx1 = -(x6_e <<< 1);
                ty0 =  (y6_e <<< 8); ty1 = -(y6_e <<< 1);
            end
            4'd3: begin
                tx0 =  (x6_e <<< 8); tx1 = -(x6_e <<< 3);
                ty0 =  (y6_e <<< 8); ty1 = -(y6_e <<< 3);
            end
            4'd4: begin
                tx0 =  (x6_e <<< 8); tx1 = -(x6_e <<< 3); tx2 = x6_e;
                ty0 =  (y6_e <<< 8); ty1 = -(y6_e <<< 3); ty2 = y6_e;
            end
            4'd5: begin
                tx0 =  (x6_e <<< 8); tx1 = -(x6_e <<< 4); tx2 = x6_e;
                ty0 =  (y6_e <<< 8); ty1 = -(y6_e <<< 4); ty2 = y6_e;
            end
            4'd6: begin
                tx0 =  (x6_e <<< 7); tx1 =  (x6_e <<< 5); tx2 = (x6_e <<< 4);
                ty0 =  (y6_e <<< 7); ty1 =  (y6_e <<< 5); ty2 = (y6_e <<< 4);
            end
            4'd7: begin
                tx0 =  (x6_e <<< 8); tx1 = -(x6_e <<< 4); tx2 = -x6_e;
                ty0 =  (y6_e <<< 8); ty1 = -(y6_e <<< 4); ty2 = -y6_e;
            end
            4'd8: begin
                tx0 =  (x6_e <<< 7); tx1 =  (x6_e <<< 5); tx2 = (x6_e <<< 3); tx3 = (x6_e <<< 1);
                ty0 =  (y6_e <<< 7); ty1 =  (y6_e <<< 5); ty2 = (y6_e <<< 3); ty3 = (y6_e <<< 1);
            end
            4'd9: begin
                tx0 =  (x6_e <<< 6); tx1 =  (x6_e <<< 5); tx2 = (x6_e <<< 3); tx3 = -x6_e;
                ty0 =  (y6_e <<< 6); ty1 =  (y6_e <<< 5); ty2 = (y6_e <<< 3); ty3 = -y6_e;
            end
            4'd10: begin
                tx0 =  (x6_e <<< 7); tx1 = -(x6_e <<< 4); tx2 = -(x6_e <<< 2); tx3 = -x6_e;
                ty0 =  (y6_e <<< 7); ty1 = -(y6_e <<< 4); ty2 = -(y6_e <<< 2); ty3 = -y6_e;
            end
            4'd11: begin
                tx0 =  (x6_e <<< 7); tx1 =  (x6_e <<< 6); tx2 = -(x6_e <<< 3); tx3 = -(x6_e <<< 1);
                ty0 =  (y6_e <<< 7); ty1 =  (y6_e <<< 6); ty2 = -(y6_e <<< 3); ty3 = -(y6_e <<< 1);
            end
            default: begin
                tx0 = {EXT_WIDTH{1'b0}}; tx1 = {EXT_WIDTH{1'b0}};
                tx2 = {EXT_WIDTH{1'b0}}; tx3 = {EXT_WIDTH{1'b0}};
                ty0 = {EXT_WIDTH{1'b0}}; ty1 = {EXT_WIDTH{1'b0}};
                ty2 = {EXT_WIDTH{1'b0}}; ty3 = {EXT_WIDTH{1'b0}};
            end
        endcase
    end

    // -------------------------------------------------------------------------
    // Register CSD terms
    // -------------------------------------------------------------------------
    reg signed [EXT_WIDTH-1:0] tx0r;
    reg signed [EXT_WIDTH-1:0] tx1r;
    reg signed [EXT_WIDTH-1:0] tx2r;
    reg signed [EXT_WIDTH-1:0] tx3r;

    reg signed [EXT_WIDTH-1:0] ty0r;
    reg signed [EXT_WIDTH-1:0] ty1r;
    reg signed [EXT_WIDTH-1:0] ty2r;
    reg signed [EXT_WIDTH-1:0] ty3r;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            tx0r <= {EXT_WIDTH{1'b0}}; tx1r <= {EXT_WIDTH{1'b0}};
            tx2r <= {EXT_WIDTH{1'b0}}; tx3r <= {EXT_WIDTH{1'b0}};
            ty0r <= {EXT_WIDTH{1'b0}}; ty1r <= {EXT_WIDTH{1'b0}};
            ty2r <= {EXT_WIDTH{1'b0}}; ty3r <= {EXT_WIDTH{1'b0}};
        end else begin
            tx0r <= tx0; tx1r <= tx1; tx2r <= tx2; tx3r <= tx3;
            ty0r <= ty0; ty1r <= ty1; ty2r <= ty2; ty3r <= ty3;
        end
    end

    // -------------------------------------------------------------------------
    // Adder tree stage 1
    // -------------------------------------------------------------------------
    wire signed [EXT_WIDTH:0] px01;
    wire signed [EXT_WIDTH:0] px23;
    wire signed [EXT_WIDTH:0] py01;
    wire signed [EXT_WIDTH:0] py23;

    assign px01 = $signed({tx0r[EXT_WIDTH-1], tx0r}) + $signed({tx1r[EXT_WIDTH-1], tx1r});
    assign px23 = $signed({tx2r[EXT_WIDTH-1], tx2r}) + $signed({tx3r[EXT_WIDTH-1], tx3r});
    assign py01 = $signed({ty0r[EXT_WIDTH-1], ty0r}) + $signed({ty1r[EXT_WIDTH-1], ty1r});
    assign py23 = $signed({ty2r[EXT_WIDTH-1], ty2r}) + $signed({ty3r[EXT_WIDTH-1], ty3r});

    reg signed [EXT_WIDTH:0] px01r;
    reg signed [EXT_WIDTH:0] px23r;
    reg signed [EXT_WIDTH:0] py01r;
    reg signed [EXT_WIDTH:0] py23r;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            px01r <= {(EXT_WIDTH+1){1'b0}}; px23r <= {(EXT_WIDTH+1){1'b0}};
            py01r <= {(EXT_WIDTH+1){1'b0}}; py23r <= {(EXT_WIDTH+1){1'b0}};
        end else begin
            px01r <= px01; px23r <= px23; py01r <= py01; py23r <= py23;
        end
    end

    // -------------------------------------------------------------------------
    // Adder tree stage 2
    // -------------------------------------------------------------------------
    wire signed [EXT_WIDTH+1:0] full_x;
    wire signed [EXT_WIDTH+1:0] full_y;

    assign full_x = $signed({px01r[EXT_WIDTH], px01r}) + $signed({px23r[EXT_WIDTH], px23r});
    assign full_y = $signed({py01r[EXT_WIDTH], py01r}) + $signed({py23r[EXT_WIDTH], py23r});

    // -------------------------------------------------------------------------
    // Output truncation
    // -------------------------------------------------------------------------
    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            oData_r <= {BIT_WIDTH{1'b0}};
            oData_i <= {BIT_WIDTH{1'b0}};
        end else begin
            oData_r <= full_x[BIT_WIDTH+FRAC_BITS-1:FRAC_BITS];
            oData_i <= full_y[BIT_WIDTH+FRAC_BITS-1:FRAC_BITS];
        end
    end

endmodule
