module delay_line#(
    parameter BIT_WIDTH   = 16,
    parameter DELAY_DEPTH = 1
)(  
    input  wire                   clk,
    input  wire                   reset,
    input  wire signed [BIT_WIDTH - 1:0] iData_R,
    input  wire signed [BIT_WIDTH - 1:0] iData_I,
    output wire signed [BIT_WIDTH - 1:0] oData_R,
    output wire signed [BIT_WIDTH - 1:0] oData_I
);
    reg signed [(BIT_WIDTH * DELAY_DEPTH) - 1 : 0] shift_reg_r;
    reg signed [(BIT_WIDTH * DELAY_DEPTH) - 1 : 0] shift_reg_i;

    generate
        if (DELAY_DEPTH == 1) begin : gen_delay_1
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    shift_reg_r <= {BIT_WIDTH{1'b0}};
                    shift_reg_i <= {BIT_WIDTH{1'b0}};
                end else begin
                    shift_reg_r <= iData_R;
                    shift_reg_i <= iData_I;
                end
            end
        end else begin : gen_delay_n
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    shift_reg_r <= {(BIT_WIDTH * DELAY_DEPTH){1'b0}};
                    shift_reg_i <= {(BIT_WIDTH * DELAY_DEPTH){1'b0}};
                end else begin
                    shift_reg_r <= {shift_reg_r[(BIT_WIDTH * (DELAY_DEPTH - 1)) - 1 : 0], iData_R};
                    shift_reg_i <= {shift_reg_i[(BIT_WIDTH * (DELAY_DEPTH - 1)) - 1 : 0], iData_I};
                end
            end
        end
    endgenerate

    assign oData_R = shift_reg_r[(BIT_WIDTH * DELAY_DEPTH) - 1 : BIT_WIDTH * (DELAY_DEPTH - 1)];
    assign oData_I = shift_reg_i[(BIT_WIDTH * DELAY_DEPTH) - 1 : BIT_WIDTH * (DELAY_DEPTH - 1)];

endmodule