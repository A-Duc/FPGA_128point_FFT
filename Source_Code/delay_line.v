module delay_line_vector #(
    parameter BIT_WIDTH   = 32,
    parameter DELAY_DEPTH = 1
)(  
    input  wire                   clk,
    input  wire                   reset,
    input  wire [BIT_WIDTH - 1:0] iData,
    output wire [BIT_WIDTH - 1:0] oData
);
    reg [(BIT_WIDTH * DELAY_DEPTH) - 1 : 0] shift_reg;

    generate
        if (DELAY_DEPTH == 1) begin : gen_delay_1
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    shift_reg <= 0;
                end else begin
                    shift_reg <= iData;
                end
            end
        end else begin : gen_delay_n
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    shift_reg <= 0;
                end else begin
                    shift_reg <= {shift_reg[(BIT_WIDTH * (DELAY_DEPTH - 1)) - 1 : 0], iData};
                end
            end
        end
    endgenerate

    assign oData = shift_reg[(BIT_WIDTH * DELAY_DEPTH) - 1 : BIT_WIDTH * (DELAY_DEPTH - 1)];

endmodule