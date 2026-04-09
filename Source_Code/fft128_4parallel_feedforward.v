module fft128_4parallel_feedforward#(
    parameter BIT_WIDTH = 16
)(
    input Clk,
    input Reset,
    input Start,

    input  [BIT_WIDTH-1:0] iData0,
    input  [BIT_WIDTH-1:0] iData1,
    input  [BIT_WIDTH-1:0] iData2,
    input  [BIT_WIDTH-1:0] iData3,

    output [BIT_WIDTH-1:0] oData0,
    output [BIT_WIDTH-1:0] oData1,
    output [BIT_WIDTH-1:0] oData2,
    output [BIT_WIDTH-1:0] oData3
);
    reg [4:0] data_slot = 5'd0;

    always @(posedge Clk, posedge Reset) begin
        if (Reset) begin
            data_slot <= 5'd0;
        end else begin
            data_slot <= data_slot + 1;
        end
    end
endmodule