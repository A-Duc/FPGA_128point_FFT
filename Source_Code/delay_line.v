module delay_line #(
    parameter BIT_WIDTH   = 16,
    parameter DELAY_DEPTH = 1
)(  
    input  wire Clk,
    input  wire Reset,

    input  wire signed [BIT_WIDTH - 1:0] iData_r,
    input  wire signed [BIT_WIDTH - 1:0] iData_i,
     
    output wire signed [BIT_WIDTH - 1:0] oData_r,
    output wire signed [BIT_WIDTH - 1:0] oData_i
);

    reg signed [BIT_WIDTH * DELAY_DEPTH - 1 : 0] shift_reg_r;
    reg signed [BIT_WIDTH * DELAY_DEPTH - 1 : 0] shift_reg_i;

    generate
        if (DELAY_DEPTH == 1) begin : gen_shift_1
            always @(posedge Clk or posedge Reset) begin
                if (Reset) begin
                    shift_reg_r <= {BIT_WIDTH{1'b0}};
                    shift_reg_i <= {BIT_WIDTH{1'b0}};
                end else begin
                    shift_reg_r <= iData_r;
                    shift_reg_i <= iData_i;
                end
            end
        end else begin : gen_shift_n
            always @(posedge Clk or posedge Reset) begin
                if (Reset) begin
                    shift_reg_r <= {(BIT_WIDTH * DELAY_DEPTH){1'b0}};
                    shift_reg_i <= {(BIT_WIDTH * DELAY_DEPTH){1'b0}};
                end else begin
                    shift_reg_r <= {iData_r, shift_reg_r[BIT_WIDTH * DELAY_DEPTH - 1 : BIT_WIDTH]};
                    shift_reg_i <= {iData_i, shift_reg_i[BIT_WIDTH * DELAY_DEPTH - 1 : BIT_WIDTH]};
                end
            end
        end
    endgenerate

    assign oData_r = shift_reg_r[BIT_WIDTH - 1 : 0];
    assign oData_i = shift_reg_i[BIT_WIDTH - 1 : 0];

endmodule