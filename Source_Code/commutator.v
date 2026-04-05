module commutator#(
    parameter BIT_WIDTH   = 16,
    parameter DELAY_DEPTH = 1
)(
    input  wire       clk,
    input  wire       reset,
    input  wire [4:0] idata_slot,

    input  wire signed [BIT_WIDTH-1:0] in0_re,
    input  wire signed [BIT_WIDTH-1:0] in0_im,
    input  wire signed [BIT_WIDTH-1:0] in1_re,
    input  wire signed [BIT_WIDTH-1:0] in1_im,
    input  wire signed [BIT_WIDTH-1:0] in2_re,
    input  wire signed [BIT_WIDTH-1:0] in2_im,
    input  wire signed [BIT_WIDTH-1:0] in3_re,
    input  wire signed [BIT_WIDTH-1:0] in3_im,

    output reg  [4:0] odata_slot,

    output reg  signed [BIT_WIDTH:0] out0_re,
    output reg  signed [BIT_WIDTH:0] out0_im,
    output reg  signed [BIT_WIDTH:0] out1_re,
    output reg  signed [BIT_WIDTH:0] out1_im,
    output reg  signed [BIT_WIDTH:0] out2_re,
    output reg  signed [BIT_WIDTH:0] out2_im,
    output reg  signed [BIT_WIDTH:0] out3_re,
    output reg  signed [BIT_WIDTH:0] out3_im,

    input [1:0] upper_mux_sel,
    input [1:0] lower_mux_sel

);
endmodule