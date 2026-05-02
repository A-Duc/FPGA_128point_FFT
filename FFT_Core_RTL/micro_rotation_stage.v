module micro_rotation_stage #(
    parameter BIT_WIDTH    = 16,
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

    assign shifted_r = iData_r >>> SHIFT_AMOUNT;
    assign shifted_i = iData_i >>> SHIFT_AMOUNT;

    // sigma is encoded as signed 4-bit value in range -4..+4.
    // Old version used 9 explicit cases. This version separates:
    //   sign  = iSigma < 0
    //   mag   = abs(iSigma) = 0..4
    // and handles only 5 magnitude cases.
    wire sigma_neg;
    wire [3:0] sigma_abs;

    assign sigma_neg = iSigma[3];
    assign sigma_abs = sigma_neg ? ((~iSigma) + 4'd1) : iSigma;

    reg signed [BIT_WIDTH-1:0] mag_mul_i;
    reg signed [BIT_WIDTH-1:0] mag_mul_r;

    reg signed [BIT_WIDTH-1:0] sigma_mul_i;
    reg signed [BIT_WIDTH-1:0] sigma_mul_r;

    always @(*) begin
        case (sigma_abs)
            4'd0: begin
                mag_mul_i = {BIT_WIDTH{1'b0}};
                mag_mul_r = {BIT_WIDTH{1'b0}};
            end
            4'd1: begin
                mag_mul_i = shifted_i;
                mag_mul_r = shifted_r;
            end
            4'd2: begin
                mag_mul_i = shifted_i <<< 1;
                mag_mul_r = shifted_r <<< 1;
            end
            4'd3: begin
                mag_mul_i = (shifted_i <<< 1) + shifted_i;
                mag_mul_r = (shifted_r <<< 1) + shifted_r;
            end
            4'd4: begin
                mag_mul_i = shifted_i <<< 2;
                mag_mul_r = shifted_r <<< 2;
            end
            default: begin
                mag_mul_i = {BIT_WIDTH{1'b0}};
                mag_mul_r = {BIT_WIDTH{1'b0}};
            end
        endcase

        if (sigma_neg) begin
            sigma_mul_i = -mag_mul_i;
            sigma_mul_r = -mag_mul_r;
        end else begin
            sigma_mul_i =  mag_mul_i;
            sigma_mul_r =  mag_mul_r;
        end
    end

    assign oData_r = iData_r - sigma_mul_i;
    assign oData_i = iData_i + sigma_mul_r;

endmodule
