module commutator#(
    parameter BIT_WIDTH   = 16,
    parameter DELAY_DEPTH = 1
)(
    input  wire       Clk,
    input  wire       Reset,
    input  wire [4:0] iData_slot,

    input  wire signed [BIT_WIDTH-1:0] iData0_r,
    input  wire signed [BIT_WIDTH-1:0] iData0_i,
    input  wire signed [BIT_WIDTH-1:0] iData1_r,
    input  wire signed [BIT_WIDTH-1:0] iData1_i,
    input  wire signed [BIT_WIDTH-1:0] iData2_r,
    input  wire signed [BIT_WIDTH-1:0] iData2_i,
    input  wire signed [BIT_WIDTH-1:0] iData3_r,
    input  wire signed [BIT_WIDTH-1:0] iData3_i,

    output reg  [4:0] oData_slot,

    output reg  signed [BIT_WIDTH-1:0] oData0_r,
    output reg  signed [BIT_WIDTH-1:0] oData0_i,
    output reg  signed [BIT_WIDTH-1:0] oData1_r,
    output reg  signed [BIT_WIDTH-1:0] oData1_i,
    output reg  signed [BIT_WIDTH-1:0] oData2_r,
    output reg  signed [BIT_WIDTH-1:0] oData2_i,
    output reg  signed [BIT_WIDTH-1:0] oData3_r,
    output reg  signed [BIT_WIDTH-1:0] oData3_i,

    input [1:0] upper_mux_sel,
    input [1:0] lower_mux_sel

);
endmodule