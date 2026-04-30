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

    localparam EXT_WIDTH = BIT_WIDTH + 2;

    wire signed [BIT_WIDTH-1:0] shifted_r;
    wire signed [BIT_WIDTH-1:0] shifted_i;

    wire signed [BIT_WIDTH-1:0] sigma_mul_i;
    wire signed [BIT_WIDTH-1:0] sigma_mul_r;

    wire signed [EXT_WIDTH-1:0] shifted_r_ext;
    wire signed [EXT_WIDTH-1:0] shifted_i_ext;

    reg signed [EXT_WIDTH-1:0] sigma_mul_i_ext;
    reg signed [EXT_WIDTH-1:0] sigma_mul_r_ext;

    assign shifted_r = iData_r >>> SHIFT_AMOUNT;
    assign shifted_i = iData_i >>> SHIFT_AMOUNT;

    assign shifted_r_ext = {{2{shifted_r[BIT_WIDTH-1]}}, shifted_r};
    assign shifted_i_ext = {{2{shifted_i[BIT_WIDTH-1]}}, shifted_i};

    always @(*) begin
        case (iSigma)
            -4'sd4: begin
                sigma_mul_i_ext = -(shifted_i_ext <<< 2);
                sigma_mul_r_ext = -(shifted_r_ext <<< 2);
            end
            -4'sd3: begin
                sigma_mul_i_ext = -((shifted_i_ext <<< 1) + shifted_i_ext);
                sigma_mul_r_ext = -((shifted_r_ext <<< 1) + shifted_r_ext);
            end
            -4'sd2: begin
                sigma_mul_i_ext = -(shifted_i_ext <<< 1);
                sigma_mul_r_ext = -(shifted_r_ext <<< 1);
            end
            -4'sd1: begin
                sigma_mul_i_ext = -shifted_i_ext;
                sigma_mul_r_ext = -shifted_r_ext;
            end
             4'sd0: begin
                sigma_mul_i_ext = {EXT_WIDTH{1'b0}};
                sigma_mul_r_ext = {EXT_WIDTH{1'b0}};
            end
             4'sd1: begin
                sigma_mul_i_ext = shifted_i_ext;
                sigma_mul_r_ext = shifted_r_ext;
            end
             4'sd2: begin
                sigma_mul_i_ext = (shifted_i_ext <<< 1);
                sigma_mul_r_ext = (shifted_r_ext <<< 1);
            end
             4'sd3: begin
                sigma_mul_i_ext = (shifted_i_ext <<< 1) + shifted_i_ext;
                sigma_mul_r_ext = (shifted_r_ext <<< 1) + shifted_r_ext;
            end
             4'sd4: begin
                sigma_mul_i_ext = (shifted_i_ext <<< 2);
                sigma_mul_r_ext = (shifted_r_ext <<< 2);
            end
            default: begin
                sigma_mul_i_ext = {EXT_WIDTH{1'b0}};
                sigma_mul_r_ext = {EXT_WIDTH{1'b0}};
            end
        endcase
    end

    assign sigma_mul_i = sigma_mul_i_ext[BIT_WIDTH-1:0];
    assign sigma_mul_r = sigma_mul_r_ext[BIT_WIDTH-1:0];

    assign oData_r = iData_r - sigma_mul_i;
    assign oData_i = iData_i + sigma_mul_r;

endmodule