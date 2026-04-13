`timescale 1ns / 1ps

module tb_cordic_pipeline;

    localparam integer TCLK = 10;
    localparam integer N_SAMPLES = 15;
    localparam integer PIPELINE_LAT = 9;

    reg clk;
    reg rst;
    reg in_valid;

    reg signed [15:0] x_in;
    reg signed [15:0] y_in;
    reg [4:0] n3;

    wire [15:0] x_out;
    wire [15:0] y_out;

    reg [4:0] in_id;
    reg [4:0] id_d0, id_d1, id_d2, id_d3, id_d4, id_d5, id_d6, id_d7, id_d8;
    reg       v_d0,  v_d1,  v_d2,  v_d3,  v_d4,  v_d5,  v_d6,  v_d7,  v_d8;

    reg signed [15:0] x_vec [0:N_SAMPLES-1];
    reg signed [15:0] y_vec [0:N_SAMPLES-1];
    reg [4:0]         n3_vec [0:N_SAMPLES-1];

    reg signed [15:0] x_ref [0:N_SAMPLES-1];
    reg signed [15:0] y_ref [0:N_SAMPLES-1];

    integer i;
    integer cyc;
    integer in_cnt;
    integer out_cnt;
    integer pass_cnt;
    integer fail_cnt;
    integer dx;
    integer dy;
    real in_x_q88, in_y_q88;
    real out_x_q88, out_y_q88;
    real exp_x_q88, exp_y_q88;

    cor_st2_p1 dut (
        .n3         (n3),
        .clk        (clk),
        .rst        (rst),
        .x_in       (x_in),
        .y_in       (y_in),
        .x_out      (x_out),
        .y_out      (y_out)
    );

    initial clk = 1'b0;
    always #(TCLK/2) clk = ~clk;

    task load_vectors;
        begin
            x_vec[0]  = 16'sd16384;   y_vec[0]  = 16'sd8192;    n3_vec[0]  = 5'd0;
            x_vec[1]  = 16'sd12000;   y_vec[1]  = -16'sd6000;   n3_vec[1]  = 5'd1;
            x_vec[2]  = -16'sd14000;  y_vec[2]  = 16'sd4000;    n3_vec[2]  = 5'd2;
            x_vec[3]  = 16'sd7000;    y_vec[3]  = 16'sd15000;   n3_vec[3]  = 5'd3;
            x_vec[4]  = -16'sd9000;   y_vec[4]  = -16'sd9000;   n3_vec[4]  = 5'd4;
            x_vec[5]  = 16'sd3000;    y_vec[5]  = -16'sd12000;  n3_vec[5]  = 5'd5;
            x_vec[6]  = 16'sd500;     y_vec[6]  = 16'sd500;     n3_vec[6]  = 5'd6;
            x_vec[7]  = -16'sd4500;   y_vec[7]  = 16'sd2000;    n3_vec[7]  = 5'd7;
            x_vec[8]  = 16'sd15000;   y_vec[8]  = -16'sd3000;   n3_vec[8]  = 5'd8;
            x_vec[9]  = -16'sd2000;   y_vec[9]  = 16'sd16000;   n3_vec[9]  = 5'd9;
            x_vec[10] = 16'sd1000;    y_vec[10] = -16'sd1000;   n3_vec[10] = 5'd10;
            x_vec[11] = -16'sd12345;  y_vec[11] = 16'sd2345;    n3_vec[11] = 5'd11;
            x_vec[12] = 16'sd8191;    y_vec[12] = 16'sd4095;    n3_vec[12] = 5'd12;
            x_vec[13] = -16'sd8192;   y_vec[13] = -16'sd2048;   n3_vec[13] = 5'd13;
            x_vec[14] = 16'sd2047;    y_vec[14] = -16'sd16383;  n3_vec[14] = 5'd14;

            x_ref[0]  = 16'sd16384;   y_ref[0]  = 16'sd8192;
            x_ref[1]  = 16'sd11362;   y_ref[1]  = -16'sd7154;
            x_ref[2]  = -16'sd13545;  y_ref[2]  = 16'sd5352;
            x_ref[3]  = 16'sd9125;    y_ref[3]  = 16'sd13814;
            x_ref[4]  = -16'sd10575;  y_ref[4]  = -16'sd7072;
            x_ref[5]  = -16'sd7;      y_ref[5]  = -16'sd12353;
            x_ref[6]  = 16'sd619;     y_ref[6]  = 16'sd337;
            x_ref[7]  = -16'sd3570;   y_ref[7]  = 16'sd3404;
            x_ref[8]  = 16'sd12729;   y_ref[8]  = -16'sd8524;
            x_ref[9]  = 16'sd5034;    y_ref[9]  = 16'sd15321;
            x_ref[10] = 16'sd412;     y_ref[10] = -16'sd1353;
            x_ref[11] = -16'sd9403;   y_ref[11] = 16'sd8375;
            x_ref[12] = 16'sd9059;    y_ref[12] = -16'sd1141;
            x_ref[13] = -16'sd7818;   y_ref[13] = 16'sd3242;
            x_ref[14] = -16'sd8835;   y_ref[14] = -16'sd13998;
        end
    endtask

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cyc <= 0;
            in_cnt <= 0;
            out_cnt <= 0;
            pass_cnt <= 0;
            fail_cnt <= 0;

            id_d0 <= 0; id_d1 <= 0; id_d2 <= 0; id_d3 <= 0; id_d4 <= 0;
            id_d5 <= 0; id_d6 <= 0; id_d7 <= 0; id_d8 <= 0;
            v_d0 <= 0; v_d1 <= 0; v_d2 <= 0; v_d3 <= 0; v_d4 <= 0;
            v_d5 <= 0; v_d6 <= 0; v_d7 <= 0; v_d8 <= 0;
        end else begin
            cyc <= cyc + 1;

            id_d8 <= id_d7; id_d7 <= id_d6; id_d6 <= id_d5; id_d5 <= id_d4;
            id_d4 <= id_d3; id_d3 <= id_d2; id_d2 <= id_d1; id_d1 <= id_d0;
            id_d0 <= in_id;

            v_d8 <= v_d7; v_d7 <= v_d6; v_d6 <= v_d5; v_d5 <= v_d4;
            v_d4 <= v_d3; v_d3 <= v_d2; v_d2 <= v_d1; v_d1 <= v_d0;
            v_d0 <= in_valid;

            if (in_valid) begin
                in_cnt <= in_cnt + 1;
                in_x_q88 = $itor($signed(x_in)) / 256.0;
                in_y_q88 = $itor($signed(y_in)) / 256.0;
                $display("[C%0d] IN  id=%0d | n3=%0d | x=%0d y=%0d | x_q8.8=%0.6f y_q8.8=%0.6f",
                         cyc, in_id, n3,
                         $signed(x_in), $signed(y_in), in_x_q88, in_y_q88);
            end
        end
    end

    always @(negedge clk) begin
        if (!rst && v_d8) begin
            out_cnt = out_cnt + 1;
            out_x_q88 = $itor($signed(x_out)) / 256.0;
            out_y_q88 = $itor($signed(y_out)) / 256.0;
            exp_x_q88 = $itor($signed(x_ref[id_d8])) / 256.0;
            exp_y_q88 = $itor($signed(y_ref[id_d8])) / 256.0;
            dx = $signed(x_out) - $signed(x_ref[id_d8]);
            dy = $signed(y_out) - $signed(y_ref[id_d8]);

            if ((dx == 0) && (dy == 0)) begin
                pass_cnt = pass_cnt + 1;
                $display("[C%0d] OUT id=%0d | x_out=%0d y_out=%0d | x_q8.8=%0.6f y_q8.8=%0.6f | ref=%0.6f %0.6f | err=%0d/%0d | PASS",
                         cyc, id_d8, $signed(x_out), $signed(y_out), out_x_q88, out_y_q88,
                         exp_x_q88, exp_y_q88, dx, dy);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("[C%0d] OUT id=%0d | x_out=%0d y_out=%0d | x_q8.8=%0.6f y_q8.8=%0.6f | ref=%0.6f %0.6f | err=%0d/%0d | FAIL",
                         cyc, id_d8, $signed(x_out), $signed(y_out), out_x_q88, out_y_q88,
                         exp_x_q88, exp_y_q88, dx, dy);
            end
        end
    end

    initial begin
        load_vectors();

        $display("================================================================");
        $display("              CORDIC PIPELINE TESTBENCH");
        $display("  Streaming test: %0d samples, no wait between samples", N_SAMPLES);
        $display("  Pipeline latency tracking: %0d clock cycles", PIPELINE_LAT);
        $display("================================================================");

        rst = 1'b1;
        in_valid = 1'b0;
        x_in = 0;
        y_in = 0;
        n3 = 0;
        in_id = 0;

        repeat (4) @(posedge clk);
        rst = 1'b0;

        $display("\n--- Feed 15 samples continuously (1 sample / cycle) ---");
        for (i = 0; i < N_SAMPLES; i = i + 1) begin
            @(negedge clk);
            in_valid = 1'b1;
            x_in = x_vec[i];
            y_in = y_vec[i];
            n3 = n3_vec[i];
            in_id = i[4:0];
        end

        @(negedge clk);
        in_valid = 1'b0;
        x_in = 0;
        y_in = 0;
        n3 = 0;
        in_id = 0;

        repeat (PIPELINE_LAT-1) @(negedge clk);

        $display("\nInput samples  seen = %0d", in_cnt);
        $display("Output samples seen = %0d", out_cnt);
        $display("Pass count          = %0d", pass_cnt);
        $display("Fail count          = %0d", fail_cnt);
        $display("Pipeline drain wait was applied.");

        $display("================================================================");
        $display("                        END OF SIMULATION");
        $display("================================================================");
        $finish;
    end

endmodule
