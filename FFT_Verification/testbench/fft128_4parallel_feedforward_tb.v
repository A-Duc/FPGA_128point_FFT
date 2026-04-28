`timescale 1ns/1ps

module fft128_4parallel_feedforward_tb;

    parameter BIT_WIDTH = 16;
    parameter N_POINTS  = 128;
    parameter N_GROUPS  = 32;

    reg Clk;
    reg Reset;
    reg Pipeline_en;

    reg  [4:0] iData_slot;
    reg  signed [BIT_WIDTH-1:0] iData0_r, iData0_i;
    reg  signed [BIT_WIDTH-1:0] iData1_r, iData1_i;
    reg  signed [BIT_WIDTH-1:0] iData2_r, iData2_i;
    reg  signed [BIT_WIDTH-1:0] iData3_r, iData3_i;

    wire signed [BIT_WIDTH-1:0] oData0_r, oData0_i;
    wire signed [BIT_WIDTH-1:0] oData1_r, oData1_i;
    wire signed [BIT_WIDTH-1:0] oData2_r, oData2_i;
    wire signed [BIT_WIDTH-1:0] oData3_r, oData3_i;
    wire [4:0]                  oData_slot;
    wire                        oData_valid;

    reg signed [BIT_WIDTH-1:0] in_re [0:N_POINTS-1];
    reg signed [BIT_WIDTH-1:0] in_im [0:N_POINTS-1];

    reg signed [BIT_WIDTH-1:0] out_re [0:N_POINTS-1];
    reg signed [BIT_WIDTH-1:0] out_im [0:N_POINTS-1];
    reg                        out_valid_map [0:N_POINTS-1];

    integer fin;
    integer fout;
    integer idx;
    integer s;
    integer tmp_re;
    integer tmp_im;
    integer read_ok;
    integer line_len;
    integer captured_lines;
    integer wait_cycles;
    integer init_idx;
    integer dump_idx;

    reg [8*256-1:0] input_path;
    reg [8*256-1:0] output_path;
    reg [8*256-1:0] line_buf;

    reg [6:0] k0, k1, k2, k3;

    function real q88_to_real;
        input signed [BIT_WIDTH-1:0] x;
        begin
            q88_to_real = x / 256.0;
        end
    endfunction

    function [4:0] bit_reverse5;
        input [4:0] x;
        begin
            bit_reverse5 = {x[0], x[1], x[2], x[3], x[4]};
        end
    endfunction

    task load_input_file;
        begin
            fin = $fopen(input_path, "r");
            if (fin == 0) begin
                $display("ERROR: cannot open input file: %0s", input_path);
                $finish;
            end

            idx = 0;
            while (!$feof(fin) && idx < N_POINTS) begin
                line_buf = 0;
                line_len = $fgets(line_buf, fin);
                if (line_len != 0) begin
                    read_ok = $sscanf(line_buf, "%d %d", tmp_re, tmp_im);
                    if (read_ok == 2) begin
                        in_re[idx] = tmp_re;
                        in_im[idx] = tmp_im;
                        idx = idx + 1;
                    end
                end
            end

            $fclose(fin);

            if (idx != N_POINTS) begin
                $display("ERROR: Only %0d samples read, expected %0d", idx, N_POINTS);
                $finish;
            end
        end
    endtask

    task clear_inputs;
        begin
            Pipeline_en = 1'b0;
            iData_slot  = 5'd0;
            iData0_r    = 'd0; iData0_i = 'd0;
            iData1_r    = 'd0; iData1_i = 'd0;
            iData2_r    = 'd0; iData2_i = 'd0;
            iData3_r    = 'd0; iData3_i = 'd0;
        end
    endtask

    fft128_4parallel_feedforward #(
        .BIT_WIDTH(BIT_WIDTH)
    ) dut (
        .Clk        (Clk),
        .Reset      (Reset),
        .Pipeline_en(Pipeline_en),
        .iData_slot (iData_slot),

        .iData0_r   (iData0_r),
        .iData0_i   (iData0_i),
        .iData1_r   (iData1_r),
        .iData1_i   (iData1_i),
        .iData2_r   (iData2_r),
        .iData2_i   (iData2_i),
        .iData3_r   (iData3_r),
        .iData3_i   (iData3_i),

        .oData0_r   (oData0_r),
        .oData0_i   (oData0_i),
        .oData1_r   (oData1_r),
        .oData1_i   (oData1_i),
        .oData2_r   (oData2_r),
        .oData2_i   (oData2_i),
        .oData3_r   (oData3_r),
        .oData3_i   (oData3_i),
        .oData_slot (oData_slot),
        .oData_valid(oData_valid)
    );

    always #5 Clk = ~Clk;

    always @(posedge Clk) begin
        if (oData_valid) begin
            k0 = {2'b00, bit_reverse5(oData_slot)};
            k1 = {2'b10, bit_reverse5(oData_slot)};
            k2 = {2'b01, bit_reverse5(oData_slot)};
            k3 = {2'b11, bit_reverse5(oData_slot)};

            out_re[k0] = oData0_r;
            out_im[k0] = oData0_i;
            out_valid_map[k0] = 1'b1;

            out_re[k1] = oData1_r;
            out_im[k1] = oData1_i;
            out_valid_map[k1] = 1'b1;

            out_re[k2] = oData2_r;
            out_im[k2] = oData2_i;
            out_valid_map[k2] = 1'b1;

            out_re[k3] = oData3_r;
            out_im[k3] = oData3_i;
            out_valid_map[k3] = 1'b1;

            captured_lines = captured_lines + 4;
        end
    end

    initial begin
        Clk = 1'b0;
        Reset = 1'b1;
        captured_lines = 0;

        for (init_idx = 0; init_idx < N_POINTS; init_idx = init_idx + 1) begin
            in_re[init_idx] = 'd0;
            in_im[init_idx] = 'd0;
            out_re[init_idx] = 'd0;
            out_im[init_idx] = 'd0;
            out_valid_map[init_idx] = 1'b0;
        end

        if (!$value$plusargs("INPUT=%s", input_path))
            input_path = "inputs/input_rand_m1p5_to_1p5_q88.txt";

        if (!$value$plusargs("OUTPUT=%s", output_path))
            output_path = "outputs/output_rand_m1p5_to_1p5_q88.txt";

        load_input_file();

        fout = $fopen(output_path, "w");
        if (fout == 0) begin
            $display("ERROR: cannot open output file: %0s", output_path);
            $finish;
        end

        $fwrite(fout, "# k re_q88 im_q88\n");

        clear_inputs();

        repeat (5) @(posedge Clk);
        Reset = 1'b0;
        repeat (2) @(posedge Clk);

        for (s = 0; s < N_GROUPS; s = s + 1) begin
            @(negedge Clk);
            Pipeline_en = 1'b1;
            iData_slot  = s[4:0];

            iData0_r = in_re[s];
            iData0_i = in_im[s];

            iData1_r = in_re[s + 64];
            iData1_i = in_im[s + 64];

            iData2_r = in_re[s + 32];
            iData2_i = in_im[s + 32];

            iData3_r = in_re[s + 96];
            iData3_i = in_im[s + 96];
        end

        @(negedge Clk);
        clear_inputs();

        wait_cycles = 0;
        while ((captured_lines < N_POINTS) && (wait_cycles < 5000)) begin
            @(posedge Clk);
            wait_cycles = wait_cycles + 1;
        end

        if (captured_lines != N_POINTS) begin
            $display("ERROR: captured %0d output lines, expected %0d", captured_lines, N_POINTS);
        end else begin
            for (dump_idx = 0; dump_idx < N_POINTS; dump_idx = dump_idx + 1) begin
                if (!out_valid_map[dump_idx]) begin
                    $display("WARNING: missing output for k=%0d", dump_idx);
                end
                $fwrite(fout, "%0d %.6f %.6f\n",
                        dump_idx,
                        q88_to_real(out_re[dump_idx]),
                        q88_to_real(out_im[dump_idx]));
            end
            $display("DONE: wrote %0d output lines to %0s", N_POINTS, output_path);
        end

        $fclose(fout);
        $finish;
    end

endmodule