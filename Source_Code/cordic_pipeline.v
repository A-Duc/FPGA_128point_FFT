`timescale 1ns / 1ps
module cordic_pipeline (
    input wire clk,
    input wire signed [15:0] x_in,
    input wire signed [15:0] y_in,
    input wire [1:0] quad,
    input wire [23:0] sigma,
    input wire [27:0] scale_cmds,
    output reg [15:0] x_out,
    output reg [15:0] y_out
);
    localparam W = 16;
    reg signed [W-1:0] x0, y0;

    always @(*) begin
        case (quad)
            2'd0: begin x0 = x_in; y0 = y_in; end
            2'd1: begin x0 = -y_in; y0 = x_in; end
            2'd2: begin x0 = -x_in; y0 = -y_in; end
            2'd3: begin x0 = y_in; y0 = -x_in; end
            default: begin x0 = x_in; y0 = y_in; end
        endcase
    end

    // ====================== PIPELINE CONTROL SIGNALS ======================
    // Sigma pipeline (6 stage → delay chính xác theo stage)
    wire [23:0] sigma_stage0 = sigma;
    reg [23:0] sigma_stage1;
    reg [23:0] sigma_stage2;
    reg [23:0] sigma_stage3;
    reg [23:0] sigma_stage4;
    reg [23:0] sigma_stage5;

    // Scale_cmds pipeline (delay 6 clock để khớp với x6_reg)
    reg [27:0] scale_cmds_d1;
    reg [27:0] scale_cmds_d2;
    reg [27:0] scale_cmds_d3;
    reg [27:0] scale_cmds_d4;
    reg [27:0] scale_cmds_d5;
    reg [27:0] scale_cmds_d6;

    always @(posedge clk) begin
        // Sigma delay
        sigma_stage1 <= sigma_stage0;
        sigma_stage2 <= sigma_stage1;
        sigma_stage3 <= sigma_stage2;
        sigma_stage4 <= sigma_stage3;
        sigma_stage5 <= sigma_stage4;

        // Scale_cmds delay (6 stages)
        scale_cmds_d1 <= scale_cmds;
        scale_cmds_d2 <= scale_cmds_d1;
        scale_cmds_d3 <= scale_cmds_d2;
        scale_cmds_d4 <= scale_cmds_d3;
        scale_cmds_d5 <= scale_cmds_d4;
        scale_cmds_d6 <= scale_cmds_d5;
    end

    wire signed [W-1:0] x1_comb, y1_comb, x2_comb, y2_comb, x3_comb, y3_comb;
    wire signed [W-1:0] x4_comb, y4_comb, x5_comb, y5_comb, x6_comb, y6_comb;
   
    reg signed [W-1:0] x1_reg, y1_reg, x2_reg, y2_reg, x3_reg, y3_reg;
    reg signed [W-1:0] x4_reg, y4_reg, x5_reg, y5_reg, x6_reg, y6_reg;

    // Các stage giờ dùng sigma đã pipeline
    cordic_stage #(.Width(W), .SHIFT(0)) st0 (x0, y0, sigma_stage0[23:20], x1_comb, y1_comb);
    always @(posedge clk) begin x1_reg <= x1_comb; y1_reg <= y1_comb; end

    cordic_stage #(.Width(W), .SHIFT(3)) st1 (x1_reg, y1_reg, sigma_stage1[19:16], x2_comb, y2_comb);
    always @(posedge clk) begin x2_reg <= x2_comb; y2_reg <= y2_comb; end

    cordic_stage #(.Width(W), .SHIFT(6)) st2 (x2_reg, y2_reg, sigma_stage2[15:12], x3_comb, y3_comb);
    always @(posedge clk) begin x3_reg <= x3_comb; y3_reg <= y3_comb; end

    cordic_stage #(.Width(W), .SHIFT(9)) st3 (x3_reg, y3_reg, sigma_stage3[11:8], x4_comb, y4_comb);
    always @(posedge clk) begin x4_reg <= x4_comb; y4_reg <= y4_comb; end

    cordic_stage #(.Width(W), .SHIFT(12)) st4 (x4_reg, y4_reg, sigma_stage4[7:4], x5_comb, y5_comb);
    always @(posedge clk) begin x5_reg <= x5_comb; y5_reg <= y5_comb; end

    cordic_stage #(.Width(W), .SHIFT(15)) st5 (x5_reg, y5_reg, sigma_stage5[3:0], x6_comb, y6_comb);
    always @(posedge clk) begin x6_reg <= x6_comb; y6_reg <= y6_comb; end

    // Scale cmds giờ dùng version delay 6 clock
    wire [6:0] cmd0 = scale_cmds_d6[6:0];
    wire [6:0] cmd1 = scale_cmds_d6[13:7];
    wire [6:0] cmd2 = scale_cmds_d6[20:14];
    wire [6:0] cmd3 = scale_cmds_d6[27:21];

    wire signed [W+31:0] term_x0 = (cmd0[6]) ? (cmd0[5] ? -(x6_reg << cmd0[4:0]) : (x6_reg << cmd0[4:0])) : 0;
    wire signed [W+31:0] term_x1 = (cmd1[6]) ? (cmd1[5] ? -(x6_reg << cmd1[4:0]) : (x6_reg << cmd1[4:0])) : 0;
    wire signed [W+31:0] term_x2 = (cmd2[6]) ? (cmd2[5] ? -(x6_reg << cmd2[4:0]) : (x6_reg << cmd2[4:0])) : 0;
    wire signed [W+31:0] term_x3 = (cmd3[6]) ? (cmd3[5] ? -(x6_reg << cmd3[4:0]) : (x6_reg << cmd3[4:0])) : 0;

    wire signed [W+31:0] term_y0 = (cmd0[6]) ? (cmd0[5] ? -(y6_reg << cmd0[4:0]) : (y6_reg << cmd0[4:0])) : 0;
    wire signed [W+31:0] term_y1 = (cmd1[6]) ? (cmd1[5] ? -(y6_reg << cmd1[4:0]) : (y6_reg << cmd1[4:0])) : 0;
    wire signed [W+31:0] term_y2 = (cmd2[6]) ? (cmd2[5] ? -(y6_reg << cmd2[4:0]) : (y6_reg << cmd2[4:0])) : 0;
    wire signed [W+31:0] term_y3 = (cmd3[6]) ? (cmd3[5] ? -(y6_reg << cmd3[4:0]) : (y6_reg << cmd3[4:0])) : 0;

    reg signed [W+31:0] term_x0_r, term_x1_r, term_x2_r, term_x3_r;
    reg signed [W+31:0] term_y0_r, term_y1_r, term_y2_r, term_y3_r;

    always @(posedge clk) begin
        term_x0_r <= term_x0;
        term_x1_r <= term_x1;
        term_x2_r <= term_x2;
        term_x3_r <= term_x3;
        term_y0_r <= term_y0;
        term_y1_r <= term_y1;
        term_y2_r <= term_y2;
        term_y3_r <= term_y3;
    end

    wire signed [W+32:0] pair_x01 = term_x0_r + term_x1_r;
    wire signed [W+32:0] pair_x23 = term_x2_r + term_x3_r;
    wire signed [W+32:0] pair_y01 = term_y0_r + term_y1_r;
    wire signed [W+32:0] pair_y23 = term_y2_r + term_y3_r;

    reg signed [W+32:0] pair_x01_reg, pair_x23_reg, pair_y01_reg, pair_y23_reg;

    always @(posedge clk) begin
        pair_x01_reg <= pair_x01;
        pair_x23_reg <= pair_x23;
        pair_y01_reg <= pair_y01;
        pair_y23_reg <= pair_y23;
    end

    wire signed [W+33:0] full_x = pair_x01_reg + pair_x23_reg;
    wire signed [W+33:0] full_y = pair_y01_reg + pair_y23_reg;

    always @(posedge clk) begin
        x_out <= full_x[45:30];
        y_out <= full_y[45:30];
    end
endmodule