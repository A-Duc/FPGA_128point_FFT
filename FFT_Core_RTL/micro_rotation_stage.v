module micro_rotation_stage #(
    parameter BIT_WIDTH    = 20,
    parameter SHIFT_AMOUNT = 0
)(
    input  wire signed [BIT_WIDTH-1:0] iData_r,
    input  wire signed [BIT_WIDTH-1:0] iData_i,
    input  wire signed [3:0]           iSigma,

    output wire signed [BIT_WIDTH-1:0] oData_r,
    output wire signed [BIT_WIDTH-1:0] oData_i
);

    wire signed [BIT_WIDTH-1:0] shifted_r;
    wire signed [BIT_WIDTH-1:0] shifted_i;

    wire signed [BIT_WIDTH-1:0] sigma_mul_i;
    wire signed [BIT_WIDTH-1:0] sigma_mul_r;

    assign shifted_r = iData_r >>> SHIFT_AMOUNT;
    assign shifted_i = iData_i >>> SHIFT_AMOUNT;

    assign sigma_mul_i = shifted_i * $signed(iSigma);
    assign sigma_mul_r = shifted_r * $signed(iSigma);

    assign oData_r = iData_r - sigma_mul_i;
    assign oData_i = iData_i + sigma_mul_r;

endmodule