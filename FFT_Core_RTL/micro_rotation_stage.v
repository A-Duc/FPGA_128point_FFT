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

    localparam EXT_WIDTH = BIT_WIDTH + 3;

    wire signed [BIT_WIDTH-1:0] shifted_r;
    wire signed [BIT_WIDTH-1:0] shifted_i;

    wire signed [EXT_WIDTH-1:0] shifted_r_ext;
    wire signed [EXT_WIDTH-1:0] shifted_i_ext;

    reg  signed [EXT_WIDTH-1:0] sigma_mul_i_ext;
    reg  signed [EXT_WIDTH-1:0] sigma_mul_r_ext;

    wire signed [EXT_WIDTH-1:0] data_r_ext;
    wire signed [EXT_WIDTH-1:0] data_i_ext;
    wire signed [EXT_WIDTH-1:0] next_r_ext;
    wire signed [EXT_WIDTH-1:0] next_i_ext;

    assign shifted_r = iData_r >>> SHIFT_AMOUNT;
    assign shifted_i = iData_i >>> SHIFT_AMOUNT;

    assign shifted_r_ext = {{(EXT_WIDTH-BIT_WIDTH){shifted_r[BIT_WIDTH-1]}}, shifted_r};
    assign shifted_i_ext = {{(EXT_WIDTH-BIT_WIDTH){shifted_i[BIT_WIDTH-1]}}, shifted_i};

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
                sigma_mul_i_ext = shifted_i_ext <<< 1;
                sigma_mul_r_ext = shifted_r_ext <<< 1;
            end

             4'sd3: begin
                sigma_mul_i_ext = (shifted_i_ext <<< 1) + shifted_i_ext;
                sigma_mul_r_ext = (shifted_r_ext <<< 1) + shifted_r_ext;
            end

             4'sd4: begin
                sigma_mul_i_ext = shifted_i_ext <<< 2;
                sigma_mul_r_ext = shifted_r_ext <<< 2;
            end

            default: begin
                sigma_mul_i_ext = {EXT_WIDTH{1'b0}};
                sigma_mul_r_ext = {EXT_WIDTH{1'b0}};
            end
        endcase
    end

    assign data_r_ext = {{(EXT_WIDTH-BIT_WIDTH){iData_r[BIT_WIDTH-1]}}, iData_r};
    assign data_i_ext = {{(EXT_WIDTH-BIT_WIDTH){iData_i[BIT_WIDTH-1]}}, iData_i};

    assign next_r_ext = data_r_ext - sigma_mul_i_ext;
    assign next_i_ext = data_i_ext + sigma_mul_r_ext;

    assign oData_r = next_r_ext[BIT_WIDTH-1:0];
    assign oData_i = next_i_ext[BIT_WIDTH-1:0];

endmodule