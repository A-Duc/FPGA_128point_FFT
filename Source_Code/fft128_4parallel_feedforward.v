module fft128_4parallel_feedforward #(
    parameter BIT_WIDTH = 16
)(
    input  wire Clk,
    input  wire Reset,
    input  wire Pipeline_en,

    input  wire [4:0] iData_slot,

    input  wire signed [BIT_WIDTH-1:0] iData0_r,
    input  wire signed [BIT_WIDTH-1:0] iData0_i,
    input  wire signed [BIT_WIDTH-1:0] iData1_r,
    input  wire signed [BIT_WIDTH-1:0] iData1_i,
    input  wire signed [BIT_WIDTH-1:0] iData2_r,
    input  wire signed [BIT_WIDTH-1:0] iData2_i,
    input  wire signed [BIT_WIDTH-1:0] iData3_r,
    input  wire signed [BIT_WIDTH-1:0] iData3_i,

    output wire signed [BIT_WIDTH-1:0] oData0_r,
    output wire signed [BIT_WIDTH-1:0] oData0_i,
    output wire signed [BIT_WIDTH-1:0] oData1_r,
    output wire signed [BIT_WIDTH-1:0] oData1_i,
    output wire signed [BIT_WIDTH-1:0] oData2_r,
    output wire signed [BIT_WIDTH-1:0] oData2_i,
    output wire signed [BIT_WIDTH-1:0] oData3_r,
    output wire signed [BIT_WIDTH-1:0] oData3_i,

    output wire       [4:0]            oData_slot
);

    wire signed [BIT_WIDTH-1:0] s1_out0_r, s1_out0_i;
    wire signed [BIT_WIDTH-1:0] s1_out1_r, s1_out1_i;
    wire signed [BIT_WIDTH-1:0] s1_out2_r, s1_out2_i;
    wire signed [BIT_WIDTH-1:0] s1_out3_r, s1_out3_i;
    wire        [4:0]           s1_out_slot;
    wire                        s1_out_valid;

    fft_plain_stage stage1(
        .Clk        (Clk),
        .Reset      (Reset),
        .iData_valid(Pipeline_en),
        .iData_slot (iData_slot),
        .iData0_r   (iData0_r),
        .iData0_i   (iData0_i),
        .iData1_r   (iData1_r),
        .iData1_i   (iData1_i),
        .iData2_r   (iData2_r),
        .iData2_i   (iData2_i),
        .iData3_r   (iData3_r),
        .iData3_i   (iData3_i),
        .oData_valid(s1_out_valid),
        .oData_slot (s1_out_slot),
        .oData0_r   (s1_out0_r),
        .oData0_i   (s1_out0_i),
        .oData1_r   (s1_out1_r),
        .oData1_i   (s1_out1_i),
        .oData2_r   (s1_out2_r),
        .oData2_i   (s1_out2_i),
        .oData3_r   (s1_out3_r),
        .oData3_i   (s1_out3_i)
    );

    wire signed [BIT_WIDTH-1:0] s2_out0_r, s2_out0_i;
    wire signed [BIT_WIDTH-1:0] s2_out1_r, s2_out1_i;
    wire signed [BIT_WIDTH-1:0] s2_out2_r, s2_out2_i;
    wire signed [BIT_WIDTH-1:0] s2_out3_r, s2_out3_i;
    wire        [4:0]           s2_out_slot;
    wire                        s2_out_valid;

    wire        [53:0]          data_rom_path1_s2;
    wire        [53:0]          data_rom_path2_s2;
    wire        [53:0]          data_rom_path3_s2;

    fft_s2_rom_path1 s2_rom_p1(
        .iAddress(s1_out_slot),
        .oData(data_rom_path1_s2)
    );

    fft_s2_rom_path2 s2_rom_p2(
        .iAddress(s1_out_slot),
        .oData(data_rom_path2_s2)
    );

    fft_s2_rom_path3 s2_rom_p3(
        .iAddress(s1_out_slot),
        .oData(data_rom_path3_s2)
    );

    fft_twiddle_stage stage2(
        .Clk         (Clk),
        .Reset       (Reset),
        .iData_valid (s1_out_valid),
        .iData_slot  (s1_out_slot),
        .iData0_r    (s1_out0_r),
        .iData0_i    (s1_out0_i),
        .iData1_r    (s1_out2_r),
        .iData1_i    (s1_out2_i),
        .iData2_r    (s1_out1_r),
        .iData2_i    (s1_out1_i),
        .iData3_r    (s1_out3_i),
        .iData3_i    (-s1_out3_r),
        .iRom_data_path1(data_rom_path1_s2),
        .iRom_data_path2(data_rom_path2_s2),
        .iRom_data_path3(data_rom_path3_s2),
        .oData_valid (s2_out_valid),
        .oData_slot  (s2_out_slot),
        .oData0_r    (s2_out0_r),
        .oData0_i    (s2_out0_i),
        .oData1_r    (s2_out1_r),
        .oData1_i    (s2_out1_i),
        .oData2_r    (s2_out2_r),
        .oData2_i    (s2_out2_i),
        .oData3_r    (s2_out3_r),
        .oData3_i    (s2_out3_i)
    );

    reg [79:0] s2_to_s3_slot_delay;
    reg [15:0] s2_to_s3_valid_delay;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            s2_to_s3_slot_delay  <= 80'd0;
            s2_to_s3_valid_delay <= 16'd0;
        end else begin
            s2_to_s3_slot_delay  <= {s2_to_s3_slot_delay[74:0], s2_out_slot};
            s2_to_s3_valid_delay <= {s2_to_s3_valid_delay[14:0], s2_out_valid};
        end
    end

    wire signed [BIT_WIDTH-1:0] s3_in0_r, s3_in0_i;
    wire signed [BIT_WIDTH-1:0] s3_in1_r, s3_in1_i;
    wire signed [BIT_WIDTH-1:0] s3_in2_r, s3_in2_i;
    wire signed [BIT_WIDTH-1:0] s3_in3_r, s3_in3_i;

    wire                        s3_out_valid;
    wire        [4:0]           s3_out_slot;
    wire signed [BIT_WIDTH-1:0] s3_out0_r, s3_out0_i;
    wire signed [BIT_WIDTH-1:0] s3_out1_r, s3_out1_i;
    wire signed [BIT_WIDTH-1:0] s3_out2_r, s3_out2_i;
    wire signed [BIT_WIDTH-1:0] s3_out3_r, s3_out3_i;

    commutator#(
        .BIT_WIDTH(BIT_WIDTH),
        .DELAY_DEPTH(16)
    ) s2_to_s3(
        .Clk      (Clk),
        .Reset    (Reset),
        .mux_sel  (s2_out_slot[4]),
        .iData0_r (s2_out0_r),
        .iData0_i (s2_out0_i),
        .iData1_r (s2_out1_r),
        .iData1_i (s2_out1_i),
        .iData2_r (s2_out2_r),
        .iData2_i (s2_out2_i),
        .iData3_r (s2_out3_r),
        .iData3_i (s2_out3_i),
        .oData0_r (s3_in0_r),
        .oData0_i (s3_in0_i),
        .oData1_r (s3_in1_r),
        .oData1_i (s3_in1_i),
        .oData2_r (s3_in2_r),
        .oData2_i (s3_in2_i),
        .oData3_r (s3_in3_r),
        .oData3_i (s3_in3_i)
    );

    fft_plain_stage stage3(
        .Clk        (Clk),
        .Reset      (Reset),
        .iData_valid(s2_to_s3_valid_delay[15]),
        .iData_slot (s2_to_s3_slot_delay[79:75]),
        .iData0_r   (s3_in0_r),
        .iData0_i   (s3_in0_i),
        .iData1_r   (s3_in1_r),
        .iData1_i   (s3_in1_i),
        .iData2_r   (s3_in2_r),
        .iData2_i   (s3_in2_i),
        .iData3_r   (s3_in3_r),
        .iData3_i   (s3_in3_i),
        .oData_valid(s3_out_valid),
        .oData_slot (s3_out_slot),
        .oData0_r   (s3_out0_r),
        .oData0_i   (s3_out0_i),
        .oData1_r   (s3_out1_r),
        .oData1_i   (s3_out1_i),
        .oData2_r   (s3_out2_r),
        .oData2_i   (s3_out2_i),
        .oData3_r   (s3_out3_r),
        .oData3_i   (s3_out3_i)
    );

        reg [39:0] s3_to_s4_slot_delay;
    reg [7:0]  s3_to_s4_valid_delay;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            s3_to_s4_slot_delay  <= 40'd0;
            s3_to_s4_valid_delay <= 8'd0;
        end else begin
            s3_to_s4_slot_delay  <= {s3_to_s4_slot_delay[34:0], s3_out_slot};
            s3_to_s4_valid_delay <= {s3_to_s4_valid_delay[6:0], s3_out_valid};
        end
    end

    wire signed [BIT_WIDTH-1:0] s4_in0_r, s4_in0_i;
    wire signed [BIT_WIDTH-1:0] s4_in1_r, s4_in1_i;
    wire signed [BIT_WIDTH-1:0] s4_in2_r, s4_in2_i;
    wire signed [BIT_WIDTH-1:0] s4_in3_r, s4_in3_i;

    wire        [4:0]           s4_in_slot;
    wire                        s4_in_valid;

    assign s4_in_slot  = s3_to_s4_slot_delay[39:35];
    assign s4_in_valid = s3_to_s4_valid_delay[7];

    commutator#(
        .BIT_WIDTH(BIT_WIDTH),
        .DELAY_DEPTH(8)
    ) s3_to_s4(
        .Clk      (Clk),
        .Reset    (Reset),
        .mux_sel  (s3_out_slot[3]),
        .iData0_r (s3_out0_r),
        .iData0_i (s3_out0_i),
        .iData1_r (s3_out1_r),
        .iData1_i (s3_out1_i),
        .iData2_r (s3_out2_r),
        .iData2_i (s3_out2_i),
        .iData3_r (s3_out3_r),
        .iData3_i (s3_out3_i),
        .oData0_r (s4_in0_r),
        .oData0_i (s4_in0_i),
        .oData1_r (s4_in1_r),
        .oData1_i (s4_in1_i),
        .oData2_r (s4_in2_r),
        .oData2_i (s4_in2_i),
        .oData3_r (s4_in3_r),
        .oData3_i (s4_in3_i)
    );

    wire signed [BIT_WIDTH-1:0] s4_out0_r, s4_out0_i;
    wire signed [BIT_WIDTH-1:0] s4_out1_r, s4_out1_i;
    wire signed [BIT_WIDTH-1:0] s4_out2_r, s4_out2_i;
    wire signed [BIT_WIDTH-1:0] s4_out3_r, s4_out3_i;
    wire        [4:0]           s4_out_slot;
    wire                        s4_out_valid;

    wire        [53:0]          data_rom_path1_s4;
    wire        [53:0]          data_rom_path2_s4;
    wire        [53:0]          data_rom_path3_s4;

    fft_s4_rom_path1 s4_rom_p1(
        .iAddress(s4_in_slot[2:0]),
        .oData   (data_rom_path1_s4)
    );

    fft_s4_rom_path2 s4_rom_p2(
        .iAddress(s4_in_slot[2:0]),
        .oData   (data_rom_path2_s4)
    );

    fft_s4_rom_path3 s4_rom_p3(
        .iAddress(s4_in_slot[2:0]),
        .oData   (data_rom_path3_s4)
    );

    fft_twiddle_stage stage4(
        .Clk            (Clk),
        .Reset          (Reset),
        .iData_valid    (s4_in_valid),
        .iData_slot     (s4_in_slot),
        .iData0_r       (s4_in0_r),
        .iData0_i       (s4_in0_i),
        .iData1_r       (s4_in1_r),
        .iData1_i       (s4_in1_i),
        .iData2_r       (s4_in2_r),
        .iData2_i       (s4_in2_i),
        .iData3_r       (s4_in3_i),
        .iData3_i       (-s4_in3_r),
        .iRom_data_path1(data_rom_path1_s4),
        .iRom_data_path2(data_rom_path2_s4),
        .iRom_data_path3(data_rom_path3_s4),
        .oData_valid    (s4_out_valid),
        .oData_slot     (s4_out_slot),
        .oData0_r       (s4_out0_r),
        .oData0_i       (s4_out0_i),
        .oData1_r       (s4_out1_r),
        .oData1_i       (s4_out1_i),
        .oData2_r       (s4_out2_r),
        .oData2_i       (s4_out2_i),
        .oData3_r       (s4_out3_r),
        .oData3_i       (s4_out3_i)
    );

    reg [19:0] s4_to_s5_slot_delay;
    reg [3:0]  s4_to_s5_valid_delay;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            s4_to_s5_slot_delay  <= 20'd0;
            s4_to_s5_valid_delay <= 4'd0;
        end else begin
            s4_to_s5_slot_delay  <= {s4_to_s5_slot_delay[14:0], s4_out_slot};
            s4_to_s5_valid_delay <= {s4_to_s5_valid_delay[2:0], s4_out_valid};
        end
    end

    wire signed [BIT_WIDTH-1:0] s5_in0_r, s5_in0_i;
    wire signed [BIT_WIDTH-1:0] s5_in1_r, s5_in1_i;
    wire signed [BIT_WIDTH-1:0] s5_in2_r, s5_in2_i;
    wire signed [BIT_WIDTH-1:0] s5_in3_r, s5_in3_i;

    wire        [4:0]           s5_in_slot;
    wire                        s5_in_valid;

    assign s5_in_slot  = s4_to_s5_slot_delay[19:15];
    assign s5_in_valid = s4_to_s5_valid_delay[3];

    commutator#(
        .BIT_WIDTH(BIT_WIDTH),
        .DELAY_DEPTH(4)
    ) s4_to_s5(
        .Clk      (Clk),
        .Reset    (Reset),
        .mux_sel  (s4_out_slot[2]),
        .iData0_r (s4_out0_r),
        .iData0_i (s4_out0_i),
        .iData1_r (s4_out1_r),
        .iData1_i (s4_out1_i),
        .iData2_r (s4_out2_r),
        .iData2_i (s4_out2_i),
        .iData3_r (s4_out3_r),
        .iData3_i (s4_out3_i),
        .oData0_r (s5_in0_r),
        .oData0_i (s5_in0_i),
        .oData1_r (s5_in1_r),
        .oData1_i (s5_in1_i),
        .oData2_r (s5_in2_r),
        .oData2_i (s5_in2_i),
        .oData3_r (s5_in3_r),
        .oData3_i (s5_in3_i)
    );

    wire signed [BIT_WIDTH-1:0] s5_out0_r, s5_out0_i;
    wire signed [BIT_WIDTH-1:0] s5_out1_r, s5_out1_i;
    wire signed [BIT_WIDTH-1:0] s5_out2_r, s5_out2_i;
    wire signed [BIT_WIDTH-1:0] s5_out3_r, s5_out3_i;
    wire        [4:0]           s5_out_slot;
    wire                        s5_out_valid;

    fft_plain_stage stage5(
        .Clk        (Clk),
        .Reset      (Reset),
        .iData_valid(s5_in_valid),
        .iData_slot (s5_in_slot),
        .iData0_r   (s5_in0_r),
        .iData0_i   (s5_in0_i),
        .iData1_r   (s5_in1_r),
        .iData1_i   (s5_in1_i),
        .iData2_r   (s5_in2_r),
        .iData2_i   (s5_in2_i),
        .iData3_r   (s5_in3_r),
        .iData3_i   (s5_in3_i),
        .oData_valid(s5_out_valid),
        .oData_slot (s5_out_slot),
        .oData0_r   (s5_out0_r),
        .oData0_i   (s5_out0_i),
        .oData1_r   (s5_out1_r),
        .oData1_i   (s5_out1_i),
        .oData2_r   (s5_out2_r),
        .oData2_i   (s5_out2_i),
        .oData3_r   (s5_out3_r),
        .oData3_i   (s5_out3_i)
    );

    reg [9:0] s5_to_s6_slot_delay;
    reg [1:0] s5_to_s6_valid_delay;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            s5_to_s6_slot_delay  <= 10'd0;
            s5_to_s6_valid_delay <= 2'd0;
        end else begin
            s5_to_s6_slot_delay  <= {s5_to_s6_slot_delay[4:0], s5_out_slot};
            s5_to_s6_valid_delay <= {s5_to_s6_valid_delay[0], s5_out_valid};
        end
    end

    wire signed [BIT_WIDTH-1:0] s6_in0_r, s6_in0_i;
    wire signed [BIT_WIDTH-1:0] s6_in1_r, s6_in1_i;
    wire signed [BIT_WIDTH-1:0] s6_in2_r, s6_in2_i;
    wire signed [BIT_WIDTH-1:0] s6_in3_r, s6_in3_i;

    wire        [4:0]           s6_in_slot;
    wire                        s6_in_valid;

    assign s6_in_slot  = s5_to_s6_slot_delay[9:5];
    assign s6_in_valid = s5_to_s6_valid_delay[1];

    commutator#(
        .BIT_WIDTH(BIT_WIDTH),
        .DELAY_DEPTH(2)
    ) s5_to_s6(
        .Clk      (Clk),
        .Reset    (Reset),
        .mux_sel  (s5_out_slot[1]),
        .iData0_r (s5_out0_r),
        .iData0_i (s5_out0_i),
        .iData1_r (s5_out1_r),
        .iData1_i (s5_out1_i),
        .iData2_r (s5_out2_r),
        .iData2_i (s5_out2_i),
        .iData3_r (s5_out3_r),
        .iData3_i (s5_out3_i),
        .oData0_r (s6_in0_r),
        .oData0_i (s6_in0_i),
        .oData1_r (s6_in1_r),
        .oData1_i (s6_in1_i),
        .oData2_r (s6_in2_r),
        .oData2_i (s6_in2_i),
        .oData3_r (s6_in3_r),
        .oData3_i (s6_in3_i)
    );

    wire signed [BIT_WIDTH-1:0] s6_out0_r, s6_out0_i;
    wire signed [BIT_WIDTH-1:0] s6_out1_r, s6_out1_i;
    wire signed [BIT_WIDTH-1:0] s6_out2_r, s6_out2_i;
    wire signed [BIT_WIDTH-1:0] s6_out3_r, s6_out3_i;
    wire        [4:0]           s6_out_slot;
    wire                        s6_out_valid;

    wire        [53:0]          data_rom_path1_s6;
    wire        [53:0]          data_rom_path2_s6;
    wire        [53:0]          data_rom_path3_s6;

    fft_s6_rom_path1 s6_rom_p1(
        .iAddress(s6_in_slot[0]),
        .oData   (data_rom_path1_s6)
    );

    fft_s6_rom_path2 s6_rom_p2(
        .iAddress(s6_in_slot[0]),
        .oData   (data_rom_path2_s6)
    );

    fft_s6_rom_path3 s6_rom_p3(
        .iAddress(s6_in_slot[0]),
        .oData   (data_rom_path3_s6)
    );

    fft_twiddle_stage stage6(
        .Clk            (Clk),
        .Reset          (Reset),
        .iData_valid    (s6_in_valid),
        .iData_slot     (s6_in_slot),
        .iData0_r       (s6_in0_r),
        .iData0_i       (s6_in0_i),
        .iData1_r       (s6_in1_r),
        .iData1_i       (s6_in1_i),
        .iData2_r       (s6_in2_r),
        .iData2_i       (s6_in2_i),
        .iData3_r       (s6_in3_i),
        .iData3_i       (-s6_in3_r),
        .iRom_data_path1(data_rom_path1_s6),
        .iRom_data_path2(data_rom_path2_s6),
        .iRom_data_path3(data_rom_path3_s6),
        .oData_valid    (s6_out_valid),
        .oData_slot     (s6_out_slot),
        .oData0_r       (s6_out0_r),
        .oData0_i       (s6_out0_i),
        .oData1_r       (s6_out1_r),
        .oData1_i       (s6_out1_i),
        .oData2_r       (s6_out2_r),
        .oData2_i       (s6_out2_i),
        .oData3_r       (s6_out3_r),
        .oData3_i       (s6_out3_i)
    );

    reg [4:0] s6_to_s7_slot_delay;
    reg       s6_to_s7_valid_delay;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            s6_to_s7_slot_delay  <= 5'd0;
            s6_to_s7_valid_delay <= 1'b0;
        end else begin
            s6_to_s7_slot_delay  <= s6_out_slot;
            s6_to_s7_valid_delay <= s6_out_valid;
        end
    end

    wire signed [BIT_WIDTH-1:0] s7_in0_r, s7_in0_i;
    wire signed [BIT_WIDTH-1:0] s7_in1_r, s7_in1_i;
    wire signed [BIT_WIDTH-1:0] s7_in2_r, s7_in2_i;
    wire signed [BIT_WIDTH-1:0] s7_in3_r, s7_in3_i;

    commutator#(
        .BIT_WIDTH(BIT_WIDTH),
        .DELAY_DEPTH(1)
    ) s6_to_s7(
        .Clk      (Clk),
        .Reset    (Reset),
        .mux_sel  (s6_out_slot[0]),
        .iData0_r (s6_out0_r),
        .iData0_i (s6_out0_i),
        .iData1_r (s6_out1_r),
        .iData1_i (s6_out1_i),
        .iData2_r (s6_out2_r),
        .iData2_i (s6_out2_i),
        .iData3_r (s6_out3_r),
        .iData3_i (s6_out3_i),
        .oData0_r (s7_in0_r),
        .oData0_i (s7_in0_i),
        .oData1_r (s7_in1_r),
        .oData1_i (s7_in1_i),
        .oData2_r (s7_in2_r),
        .oData2_i (s7_in2_i),
        .oData3_r (s7_in3_r),
        .oData3_i (s7_in3_i)
    );

    wire signed [BIT_WIDTH-1:0] s7_out0_r, s7_out0_i;
    wire signed [BIT_WIDTH-1:0] s7_out1_r, s7_out1_i;
    wire signed [BIT_WIDTH-1:0] s7_out2_r, s7_out2_i;
    wire signed [BIT_WIDTH-1:0] s7_out3_r, s7_out3_i;
    wire        [4:0]           s7_out_slot;
    wire                        s7_out_valid;

    fft_plain_stage stage7(
        .Clk        (Clk),
        .Reset      (Reset),
        .iData_valid(s6_to_s7_valid_delay),
        .iData_slot (s6_to_s7_slot_delay),
        .iData0_r   (s7_in0_r),
        .iData0_i   (s7_in0_i),
        .iData1_r   (s7_in1_r),
        .iData1_i   (s7_in1_i),
        .iData2_r   (s7_in2_r),
        .iData2_i   (s7_in2_i),
        .iData3_r   (s7_in3_r),
        .iData3_i   (s7_in3_i),
        .oData_valid(s7_out_valid),
        .oData_slot (s7_out_slot),
        .oData0_r   (s7_out0_r),
        .oData0_i   (s7_out0_i),
        .oData1_r   (s7_out1_r),
        .oData1_i   (s7_out1_i),
        .oData2_r   (s7_out2_r),
        .oData2_i   (s7_out2_i),
        .oData3_r   (s7_out3_r),
        .oData3_i   (s7_out3_i)
    );

    assign oData0_r  = s7_out0_r;
    assign oData0_i  = s7_out0_i;
    assign oData1_r  = s7_out1_r;
    assign oData1_i  = s7_out1_i;
    assign oData2_r  = s7_out2_r;
    assign oData2_i  = s7_out2_i;
    assign oData3_r   = s7_out3_r;
    assign oData3_i   = s7_out3_i;
    assign oData_slot = s7_out_slot;

endmodule
