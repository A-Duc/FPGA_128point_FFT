module fft128_avalon_mm_wrapper(
    input  wire        Clk,
    input  wire        Reset_n,

    input  wire [8:0]  Address,
    input  wire [31:0] WriteData,
    input  wire        ChipSelect_n,
    input  wire        Write_n,
    input  wire        Read_n,

    output reg  [31:0] ReadData
);
endmodule