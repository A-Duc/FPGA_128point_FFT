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

    reg signed [BIT_WIDTH-1:0] sigma_mul_i;
    reg signed [BIT_WIDTH-1:0] sigma_mul_r;

    assign shifted_r = iData_r >>> SHIFT_AMOUNT;
    assign shifted_i = iData_i >>> SHIFT_AMOUNT;

    always @(*) begin
        case (iSigma)
            4'b0100: begin
                sigma_mul_i =  shifted_i <<< 2;
                sigma_mul_r =  shifted_r <<< 2;
            end
            4'b0011: begin
                sigma_mul_i = (shifted_i <<< 1) + shifted_i;
                sigma_mul_r = (shifted_r <<< 1) + shifted_r;
            end
            4'b0010: begin
                sigma_mul_i =  shifted_i <<< 1;
                sigma_mul_r =  shifted_r <<< 1;
            end
            4'b0001: begin
                sigma_mul_i =  shifted_i;
                sigma_mul_r =  shifted_r;
            end
            4'b0000: begin
                sigma_mul_i = {BIT_WIDTH{1'b0}};
                sigma_mul_r = {BIT_WIDTH{1'b0}};
            end
            4'b1111: begin
                sigma_mul_i = -shifted_i;
                sigma_mul_r = -shifted_r;
            end
            4'b1110: begin
                sigma_mul_i = -(shifted_i <<< 1);
                sigma_mul_r = -(shifted_r <<< 1);
            end
            4'b1101: begin
                sigma_mul_i = -((shifted_i <<< 1) + shifted_i);
                sigma_mul_r = -((shifted_r <<< 1) + shifted_r);
            end
            4'b1100: begin
                sigma_mul_i = -(shifted_i <<< 2);
                sigma_mul_r = -(shifted_r <<< 2);
            end
            default: begin
                sigma_mul_i = {BIT_WIDTH{1'b0}};
                sigma_mul_r = {BIT_WIDTH{1'b0}};
            end
        endcase
    end

    assign oData_r = iData_r - sigma_mul_i;
    assign oData_i = iData_i + sigma_mul_r;

endmodule