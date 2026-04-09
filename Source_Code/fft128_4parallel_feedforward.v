module fft128_4parallel_feedforward #(
    parameter BIT_WIDTH = 16
)(
    input  wire Clk,
    input  wire Reset,
    input  wire Pipeline_en,

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
    output wire signed [BIT_WIDTH-1:0] oData3_i
);
    reg [4:0] data_slot;

    always @(posedge Clk or posedge Reset) begin
        if (Reset)
            data_slot <= 5'd0;
        else if (Pipeline_en)
            data_slot <= data_slot + 1;
    end

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
        .iData_slot (data_slot),
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
        .iData1_r    (s1_out1_r),
        .iData1_i    (s1_out1_i),
        .iData2_r    (s1_out2_r),
        .iData2_i    (s1_out2_i),
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

    commutator#(
        .BIT_WIDTH(BIT_WIDTH),
        .DELAY_DEPTH(16)
    ) s2_to_s3(
        .Clk           (Clk),
        .Reset         (Reset),
        .upper_mux0_sel(s2_out_slot[0]),
        .upper_mux1_sel(~s2_out_slot[0]),
        .lower_mux0_sel(s2_out_slot[0]),
        .lower_mux1_sel(~s2_out_slot[0]),
        .iData0_r      (s2_out0_r),
        .iData0_i      (s2_out0_i),
        .iData1_r      (s2_out1_r),
        .iData1_i      (s2_out1_i),
        .iData2_r      (s2_out2_r),
        .iData2_i      (s2_out2_i),
        .iData3_r      (s2_out3_r),
        .iData3_i      (s2_out3_i),
        .oData0_r      (oData0_r),
        .oData0_i      (oData0_i),
        .oData1_r      (oData1_r),
        .oData1_i      (oData1_i),
        .oData2_r      (oData2_r),
        .oData2_i      (oData2_i),
        .oData3_r      (oData3_r),
        .oData3_i      (oData3_i)
    );

endmodule