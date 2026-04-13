module trivial_mul #(
    parameter BIT_WIDTH = 16
)(
    input  wire [1:0] mode,
    input  wire signed [BIT_WIDTH-1:0] iData_r,
    input  wire signed [BIT_WIDTH-1:0] iData_i,

    output reg  signed [BIT_WIDTH-1:0] oData_r,
    output reg  signed [BIT_WIDTH-1:0] oData_i
);

    localparam MUL_POS1 = 2'b00;
    localparam MUL_NEG1 = 2'b01;
    localparam MUL_POSJ = 2'b10;
    localparam MUL_NEGJ = 2'b11;

    always @(*) begin
        case (mode)
            MUL_POS1: begin
                oData_r =  iData_r;
                oData_i =  iData_i;
            end

            MUL_NEG1: begin
                oData_r = -iData_r;
                oData_i = -iData_i;
            end

            MUL_POSJ: begin
                oData_r = -iData_i;
                oData_i =  iData_r;
            end

            MUL_NEGJ: begin
                oData_r =  iData_i;
                oData_i = -iData_r;
            end

            default: begin
                oData_r = iData_r;
                oData_i = iData_i;
            end
        endcase
    end

endmodule