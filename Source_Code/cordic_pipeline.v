`timescale 1ns / 1ps

module cordic_pipeline #(
    parameter W         = 16,   // datapath width (Q8.8 = 16)
    parameter FRAC_BITS = 8     // số fractional bit của Q format
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire signed [W-1:0]   x_in,
    input  wire signed [W-1:0]   y_in,
    input  wire [1:0]            quad,
    input  wire [23:0]           sigma,
    input  wire [23:0]           scale_cmds,   // 4 × 6-bit CSD terms
    output reg  signed [W-1:0]   x_out,
    output reg  signed [W-1:0]   y_out
);

    reg signed [W-1:0] x0, y0;

    always @(*) begin
        case (quad)
            2'd0: begin x0 =  x_in; y0 =  y_in; end
            2'd1: begin x0 = -y_in; y0 =  x_in; end
            2'd2: begin x0 = -x_in; y0 = -y_in; end
            2'd3: begin x0 =  y_in; y0 = -x_in; end
            default: begin x0 = x_in; y0 = y_in; end
        endcase
    end

    wire [23:0] sigma_s0 = sigma;
    reg  [23:0] sigma_s1, sigma_s2, sigma_s3, sigma_s4, sigma_s5;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sigma_s1 <= 0; sigma_s2 <= 0; sigma_s3 <= 0;
            sigma_s4 <= 0; sigma_s5 <= 0;
        end else begin
            sigma_s1 <= sigma_s0;
            sigma_s2 <= sigma_s1;
            sigma_s3 <= sigma_s2;
            sigma_s4 <= sigma_s3;
            sigma_s5 <= sigma_s4;
        end
    end

    reg [23:0] sc_d1, sc_d2, sc_d3, sc_d4, sc_d5, sc_d6;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sc_d1<=0; sc_d2<=0; sc_d3<=0;
            sc_d4<=0; sc_d5<=0; sc_d6<=0;
        end else begin
            sc_d1 <= scale_cmds;
            sc_d2 <= sc_d1;
            sc_d3 <= sc_d2;
            sc_d4 <= sc_d3;
            sc_d5 <= sc_d4;
            sc_d6 <= sc_d5;
        end
    end

    wire signed [W-1:0] x1c, y1c, x2c, y2c, x3c, y3c;
    wire signed [W-1:0] x4c, y4c, x5c, y5c, x6c, y6c;

    reg  signed [W-1:0] x1r, y1r, x2r, y2r, x3r, y3r;
    reg  signed [W-1:0] x4r, y4r, x5r, y5r, x6r, y6r;

    cordic_stage #(.Width(W), .SHIFT(0))  st0 (.x_in(x0),  .y_in(y0),  .sigma(sigma_s0[23:20]), .x_out(x1c), .y_out(y1c));
    cordic_stage #(.Width(W), .SHIFT(3))  st1 (.x_in(x1r), .y_in(y1r), .sigma(sigma_s1[19:16]), .x_out(x2c), .y_out(y2c));
    cordic_stage #(.Width(W), .SHIFT(6))  st2 (.x_in(x2r), .y_in(y2r), .sigma(sigma_s2[15:12]), .x_out(x3c), .y_out(y3c));
    cordic_stage #(.Width(W), .SHIFT(9))  st3 (.x_in(x3r), .y_in(y3r), .sigma(sigma_s3[11:8]),  .x_out(x4c), .y_out(y4c));
    cordic_stage #(.Width(W), .SHIFT(12)) st4 (.x_in(x4r), .y_in(y4r), .sigma(sigma_s4[7:4]),   .x_out(x5c), .y_out(y5c));
    cordic_stage #(.Width(W), .SHIFT(15)) st5 (.x_in(x5r), .y_in(y5r), .sigma(sigma_s5[3:0]),   .x_out(x6c), .y_out(y6c));

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x1r<=0; y1r<=0; x2r<=0; y2r<=0;
            x3r<=0; y3r<=0; x4r<=0; y4r<=0;
            x5r<=0; y5r<=0; x6r<=0; y6r<=0;
        end else begin
            x1r<=x1c; y1r<=y1c;
            x2r<=x2c; y2r<=y2c;
            x3r<=x3c; y3r<=y3c;
            x4r<=x4c; y4r<=y4c;
            x5r<=x5c; y5r<=y5c;
            x6r<=x6c; y6r<=y6c;
        end
    end

    wire        v0 = sc_d6[5];  wire n0 = sc_d6[4];  wire [3:0] s0 = sc_d6[3:0];
    wire        v1 = sc_d6[11]; wire n1 = sc_d6[10]; wire [3:0] s1 = sc_d6[9:6];
    wire        v2 = sc_d6[17]; wire n2 = sc_d6[16]; wire [3:0] s2 = sc_d6[15:12];
    wire        v3 = sc_d6[23]; wire n3 = sc_d6[22]; wire [3:0] s3 = sc_d6[21:18];

    // EW = W + FRAC_BITS = 24 bit (đủ cho left shift tối đa FRAC_BITS=8)
    localparam EW = W + FRAC_BITS;  // 24

    wire signed [EW-1:0] x6_e = {{FRAC_BITS{x6r[W-1]}}, x6r};
    wire signed [EW-1:0] y6_e = {{FRAC_BITS{y6r[W-1]}}, y6r};

    // Tính từng CSD term (left shift rồi negate nếu neg)
    wire signed [EW-1:0] tx0 = v0 ? (n0 ? -(x6_e << s0) : (x6_e << s0)) : {EW{1'b0}};
    wire signed [EW-1:0] tx1 = v1 ? (n1 ? -(x6_e << s1) : (x6_e << s1)) : {EW{1'b0}};
    wire signed [EW-1:0] tx2 = v2 ? (n2 ? -(x6_e << s2) : (x6_e << s2)) : {EW{1'b0}};
    wire signed [EW-1:0] tx3 = v3 ? (n3 ? -(x6_e << s3) : (x6_e << s3)) : {EW{1'b0}};

    wire signed [EW-1:0] ty0 = v0 ? (n0 ? -(y6_e << s0) : (y6_e << s0)) : {EW{1'b0}};
    wire signed [EW-1:0] ty1 = v1 ? (n1 ? -(y6_e << s1) : (y6_e << s1)) : {EW{1'b0}};
    wire signed [EW-1:0] ty2 = v2 ? (n2 ? -(y6_e << s2) : (y6_e << s2)) : {EW{1'b0}};
    wire signed [EW-1:0] ty3 = v3 ? (n3 ? -(y6_e << s3) : (y6_e << s3)) : {EW{1'b0}};

    // Register terms (pipeline stage 7)
    reg signed [EW-1:0] tx0r, tx1r, tx2r, tx3r;
    reg signed [EW-1:0] ty0r, ty1r, ty2r, ty3r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx0r<=0; tx1r<=0; tx2r<=0; tx3r<=0;
            ty0r<=0; ty1r<=0; ty2r<=0; ty3r<=0;
        end else begin
            tx0r<=tx0; tx1r<=tx1; tx2r<=tx2; tx3r<=tx3;
            ty0r<=ty0; ty1r<=ty1; ty2r<=ty2; ty3r<=ty3;
        end
    end

    // Cộng theo cặp (EW+1 = 25 bit, tránh overflow)
    wire signed [EW:0] px01 = $signed({tx0r[EW-1], tx0r}) + $signed({tx1r[EW-1], tx1r});
    wire signed [EW:0] px23 = $signed({tx2r[EW-1], tx2r}) + $signed({tx3r[EW-1], tx3r});
    wire signed [EW:0] py01 = $signed({ty0r[EW-1], ty0r}) + $signed({ty1r[EW-1], ty1r});
    wire signed [EW:0] py23 = $signed({ty2r[EW-1], ty2r}) + $signed({ty3r[EW-1], ty3r});

    // Register pairs (pipeline stage 8)
    reg signed [EW:0] px01r, px23r, py01r, py23r;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            px01r<=0; px23r<=0;
            py01r<=0; py23r<=0;
        end else begin
            px01r<=px01; px23r<=px23;
            py01r<=py01; py23r<=py23;
        end
    end

    // Tổng cuối (EW+2 = 26 bit)
    wire signed [EW+1:0] full_x = $signed({px01r[EW], px01r}) + $signed({px23r[EW], px23r});
    wire signed [EW+1:0] full_y = $signed({py01r[EW], py01r}) + $signed({py23r[EW], py23r});

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x_out <= 0;
            y_out <= 0;
        end else begin
            x_out <= full_x[W+FRAC_BITS-1 : FRAC_BITS];   // [23:8]
            y_out <= full_y[W+FRAC_BITS-1 : FRAC_BITS];   // [23:8]
        end
    end

endmodule