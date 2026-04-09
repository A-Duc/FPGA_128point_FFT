module delay_line #(
    parameter BIT_WIDTH   = 16,
    parameter DELAY_DEPTH = 1
)(
    input  wire Clk,
    input  wire Reset,

    input  wire signed [BIT_WIDTH-1:0] iData_r,
    input  wire signed [BIT_WIDTH-1:0] iData_i,

    output wire signed [BIT_WIDTH-1:0] oData_r,
    output wire signed [BIT_WIDTH-1:0] oData_i
);

    reg signed [BIT_WIDTH*(DELAY_DEPTH+1)-1:0] shift_reg_r;
    reg signed [BIT_WIDTH*(DELAY_DEPTH+1)-1:0] shift_reg_i;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            shift_reg_r <= {(BIT_WIDTH*(DELAY_DEPTH+1)){1'b0}};
            shift_reg_i <= {(BIT_WIDTH*(DELAY_DEPTH+1)){1'b0}};
        end
        else begin
            shift_reg_r <= {shift_reg_r[BIT_WIDTH*DELAY_DEPTH-1:0], iData_r};
            shift_reg_i <= {shift_reg_i[BIT_WIDTH*DELAY_DEPTH-1:0], iData_i};
        end
    end

    assign oData_r = shift_reg_r[BIT_WIDTH*(DELAY_DEPTH+1)-1 : BIT_WIDTH*DELAY_DEPTH];
    assign oData_i = shift_reg_i[BIT_WIDTH*(DELAY_DEPTH+1)-1 : BIT_WIDTH*DELAY_DEPTH];

endmodule