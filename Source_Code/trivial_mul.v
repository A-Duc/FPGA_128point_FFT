module trivial_mul#(
    parameter BIT_WIDTH = 16
)(
    input         [1:0]  mode,

    input  signed [BIT_WIDTH-1:0] iData_r,  
    input  signed [BIT_WIDTH-1:0] iData_i,  

    output reg signed [BIT_WIDTH-1:0] oData_r,
    output reg signed [BIT_WIDTH-1:0] oData_i
);
    localparam MUL_POS1 = 2'b00;
    localparam MUL_NEG1 = 2'b01;
    localparam MUL_POSJ = 2'b10;
    localparam MUL_NEGJ = 2'b11;
    
    always @(*) begin
        case (mode)
            MUL_POS1: begin oData_i =  iData_i; oData_r =  iData_r; end
            MUL_NEG1: begin oData_i = -iData_i; oData_r = -iData_r; end
            MUL_POSJ: begin oData_i =  iData_r; oData_r = -iData_i; end
            MUL_NEGJ: begin oData_i = -iData_r; oData_r =  iData_i; end
            default: begin oData_i = iData_i; oData_r = iData_r; end
        endcase
    end
    
endmodule