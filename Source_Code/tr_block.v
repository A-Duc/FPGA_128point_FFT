module tr_block #(
    parameter BIT_WIDTH = 16
)(
    input  wire signed [BIT_WIDTH-1:0] iData_r,
    input  wire signed [BIT_WIDTH-1:0] iData_i,

    output wire signed [BIT_WIDTH-1:0] oData_r,
    output wire signed [BIT_WIDTH-1:0] oData_i
);

    assign oData_r = iData_i;
    assign oData_i = -iData_r;

endmodule