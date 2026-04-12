`timescale 1ns/1ps

module fft128_4parallel_feedforward_tb;

    // ------------------------------------------------------------------
    // Parameters
    // ------------------------------------------------------------------
    localparam BIT_WIDTH   = 16;
    localparam FRAC_BITS   = 8;      // Q8.8
    localparam N_POINTS    = 128;
    localparam N_SLOTS     = 32;     // 128 / 4
    localparam FLUSH_SLOTS = 128;
`ifdef STREAM_2_FRAMES
    localparam FEED_FRAMES     = 2;
    localparam SKIP_HW_OUTPUTS = 128;
`else
    localparam FEED_FRAMES     = 1;
    localparam SKIP_HW_OUTPUTS = 0;
`endif

    // ------------------------------------------------------------------
    // DUT interface signals
    // ------------------------------------------------------------------
    reg                      Clk;
    reg                      Reset;
    reg                      Pipeline_en;
    reg       [4:0]          iData_slot;

    reg  signed [BIT_WIDTH-1:0] iData0_r, iData0_i;
    reg  signed [BIT_WIDTH-1:0] iData1_r, iData1_i;
    reg  signed [BIT_WIDTH-1:0] iData2_r, iData2_i;
    reg  signed [BIT_WIDTH-1:0] iData3_r, iData3_i;

    wire signed [BIT_WIDTH-1:0] oData0_r, oData0_i;
    wire signed [BIT_WIDTH-1:0] oData1_r, oData1_i;
    wire signed [BIT_WIDTH-1:0] oData2_r, oData2_i;
    wire signed [BIT_WIDTH-1:0] oData3_r, oData3_i;
    wire        [4:0]            oData_slot;

    // ------------------------------------------------------------------
    // Instantiate DUT
    // ------------------------------------------------------------------
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
        .oData_slot (oData_slot)
    );

    // ------------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------------
    initial begin
        Clk = 1'b0;
        forever #5 Clk = ~Clk;  // 100 MHz
    end

    // ------------------------------------------------------------------
    // Input storage (from file)
    // ------------------------------------------------------------------
    reg signed [BIT_WIDTH-1:0] xin_r [0:N_POINTS-1];
    reg signed [BIT_WIDTH-1:0] xin_i [0:N_POINTS-1];

    // ------------------------------------------------------------------
    // File handles
    // ------------------------------------------------------------------
    integer fin;
    integer fout;

    // Counters
    integer idx;
    integer slot;
    integer read_fields;
    integer out_count;
    integer total_out_count;
    integer tmp_re;
    integer tmp_im;
    integer pad_idx;
    integer frame;
    integer s;
    integer flush_slot;
    reg [1023:0] input_line;

    // ------------------------------------------------------------------
    // Stimulus and file I/O
    // ------------------------------------------------------------------
    initial begin
        // Init
        Reset       = 1'b1;
        Pipeline_en = 1'b0;
        iData_slot  = 5'd0;

        iData0_r = 0; iData0_i = 0;
        iData1_r = 0; iData1_i = 0;
        iData2_r = 0; iData2_i = 0;
        iData3_r = 0; iData3_i = 0;

        // Open input file (same as Python reference: input_diverse_q88.txt)
        fin = $fopen("input_diverse_q88.txt", "r");
        if (fin == 0) begin
            $display("ERROR: Cannot open input_diverse_q88.txt");
            $finish;
        end

        // Read 128 complex samples (Q8.8, two's complement)
        idx = 0;
        while (!$feof(fin) && idx < N_POINTS) begin
            read_fields = $fgets(input_line, fin);
            if (read_fields != 0) begin
                read_fields = $sscanf(input_line, "%d %d", tmp_re, tmp_im);
            end
            if (read_fields == 2) begin
                // Đủ cả phần thực và ảo
                xin_r[idx]  = tmp_re;
                xin_i[idx]  = tmp_im;
                idx         = idx + 1;
            end else if (read_fields == 1) begin
                // Chỉ có phần thực, phần ảo = 0
                tmp_im      = 0;
                xin_r[idx]  = tmp_re;
                xin_i[idx]  = tmp_im;
                idx         = idx + 1;
                // Có thể là dòng comment (bắt đầu bằng '#') hoặc trống: đọc bỏ cả dòng
            end
        end
        $fclose(fin);

        if (idx < N_POINTS) begin
            $display("WARNING: Only %0d samples read, zero-padding to %0d", idx, N_POINTS);
            for (pad_idx = idx; pad_idx < N_POINTS; pad_idx = pad_idx + 1) begin
                xin_r[pad_idx] = 0;
                xin_i[pad_idx] = 0;
            end
        end
        // Reset sequence
        #20;
        @(posedge Clk);
        Reset = 1'b0;
        @(negedge Clk);

        // Feed data: 4 samples per clock
        Pipeline_en = 1'b1;
        for (frame = 0; frame < FEED_FRAMES; frame = frame + 1) begin
            for (slot = 0; slot < N_SLOTS; slot = slot + 1) begin
                iData_slot = slot[4:0];

                // Mapping:
                // input0 = x[slot]
                // input1 = x[slot + 64]
                // input2 = x[slot + 32]
                // input3 = x[slot + 96]
                iData0_r = xin_r[slot];
                iData0_i = xin_i[slot];

                iData1_r = xin_r[slot + 64];
                iData1_i = xin_i[slot + 64];

                iData2_r = xin_r[slot + 32];
                iData2_i = xin_i[slot + 32];

                iData3_r = xin_r[slot + 96];
                iData3_i = xin_i[slot + 96];

                @(negedge Clk);
            end
        end

        // Stop feeding
        Pipeline_en = 1'b0;
        iData0_r = 0; iData0_i = 0;
        iData1_r = 0; iData1_i = 0;
        iData2_r = 0; iData2_i = 0;
        iData3_r = 0; iData3_i = 0;

        // Keep the slot phase running while the pipeline drains. The
        // commutators use slot bits as mux selects even after input valid
        // falls, so holding the last slot would route the delayed tail wrong.
        for (flush_slot = 0; flush_slot < FLUSH_SLOTS; flush_slot = flush_slot + 1) begin
            iData_slot = flush_slot % N_SLOTS;
            @(negedge Clk);
        end

        // Wait for pipeline to flush while output monitor is running
        // Simulation will finish when enough outputs (128) are captured.
    end

    // ------------------------------------------------------------------
    // Output monitor: capture outputs in 4-parallel channel order and
    // write them to output_hw.txt as decimal (Q8.8 -> real)
    // ------------------------------------------------------------------
    real y_re[0:3];
    real y_im[0:3];
    real hw_re[0:N_POINTS-1];
    real hw_im[0:N_POINTS-1];
    integer out_index[0:3];
    integer monitor_cycles;
    integer write_idx;

    function integer bit_reverse5;
        input [4:0] value;
        begin
            bit_reverse5 = {value[0], value[1], value[2], value[3], value[4]};
        end
    endfunction

    initial begin
        fout = $fopen("output_hw.txt", "w");
        if (fout == 0) begin
            $display("ERROR: Cannot open output_hw.txt");
            $finish;
        end
        $fdisplay(fout, "# index  real  imag  (Q8.8 -> decimal)");

        out_count = 0;
        total_out_count = 0;
        monitor_cycles = 0;

        // Wait for reset deassertion
        @(negedge Reset);
        // Then monitor each clock
        forever begin
            @(posedge Clk);
            #1;
            monitor_cycles = monitor_cycles + 1;
            if (monitor_cycles > 5000) begin
                $display("ERROR: Timeout while waiting for FFT outputs. Captured %0d samples.", out_count);
                $fclose(fout);
                $finish;
            end

            // Dùng hierarchical reference tới tín hiệu valid cuối pipeline
            if (dut.s7_out_valid) begin
                s = oData_slot; // dataslot hiện tại (0..31)

                // Output channel order: bit-reversed slot within each 32-bin block.
                out_index[0] = bit_reverse5(s[4:0]);
                out_index[1] = 64 + bit_reverse5(s[4:0]);
                out_index[2] = 32 + bit_reverse5(s[4:0]);
                out_index[3] = 96 + bit_reverse5(s[4:0]);

                // Q8.8 -> số thực: value / 2^8
                if (total_out_count >= SKIP_HW_OUTPUTS) begin
                y_re[0] = $itor($signed(oData0_r)) / (1.0 * (1 << FRAC_BITS));
                y_im[0] = $itor($signed(oData0_i)) / (1.0 * (1 << FRAC_BITS));

                y_re[1] = $itor($signed(oData1_r)) / (1.0 * (1 << FRAC_BITS));
                y_im[1] = $itor($signed(oData1_i)) / (1.0 * (1 << FRAC_BITS));

                y_re[2] = $itor($signed(oData2_r)) / (1.0 * (1 << FRAC_BITS));
                y_im[2] = $itor($signed(oData2_i)) / (1.0 * (1 << FRAC_BITS));

                y_re[3] = $itor($signed(oData3_r)) / (1.0 * (1 << FRAC_BITS));
                y_im[3] = $itor($signed(oData3_i)) / (1.0 * (1 << FRAC_BITS));

                // Ghi ra file theo thứ tự mô tả
                hw_re[out_index[0]] = y_re[0];
                hw_im[out_index[0]] = y_im[0];
                hw_re[out_index[1]] = y_re[1];
                hw_im[out_index[1]] = y_im[1];
                hw_re[out_index[2]] = y_re[2];
                hw_im[out_index[2]] = y_im[2];
                hw_re[out_index[3]] = y_re[3];
                hw_im[out_index[3]] = y_im[3];

                out_count = out_count + 4;
                end
                total_out_count = total_out_count + 4;

                if (out_count >= N_POINTS) begin
                    for (write_idx = 0; write_idx < N_POINTS; write_idx = write_idx + 1) begin
                        $fdisplay(fout, "%3d %0.8f %0.8f", write_idx, hw_re[write_idx], hw_im[write_idx]);
                    end
                    $display("Captured %0d FFT outputs. Simulation finished.", out_count);
                    $fclose(fout);
                    #20;
                    $finish;
                end
            end
        end
    end

`ifdef DUMP_S2
    integer dump_s2_count;

    initial begin
        dump_s2_count = 0;
        @(negedge Reset);
        forever begin
            @(posedge Clk);
            #1;
            if (dut.s2_out_valid) begin
                $display("S2 slot=%0d ch0=%0d,%0d ch1=%0d,%0d ch2=%0d,%0d ch3=%0d,%0d",
                         dut.s2_out_slot,
                         dut.s2_out0_r, dut.s2_out0_i,
                         dut.s2_out1_r, dut.s2_out1_i,
                         dut.s2_out2_r, dut.s2_out2_i,
                         dut.s2_out3_r, dut.s2_out3_i);
                dump_s2_count = dump_s2_count + 1;
            end
        end
    end
`endif

`ifdef DUMP_S3
    initial begin
        @(negedge Reset);
        forever begin
            @(posedge Clk);
            #1;
            if (dut.s3_out_valid) begin
                $display("S3 slot=%0d ch0=%0d,%0d ch1=%0d,%0d ch2=%0d,%0d ch3=%0d,%0d",
                         dut.s3_out_slot,
                         dut.s3_out0_r, dut.s3_out0_i,
                         dut.s3_out1_r, dut.s3_out1_i,
                         dut.s3_out2_r, dut.s3_out2_i,
                         dut.s3_out3_r, dut.s3_out3_i);
            end
        end
    end
`endif

endmodule
