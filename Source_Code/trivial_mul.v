module trivial_mul#(
    parameter BIT_WIDTH = 16
)(
    input         [1:0]  mode,

    input  signed [BIT_WIDTH - 1:0] iData_R,  
    input  signed [BIT_WIDTH - 1:0] iData_I,  

    output reg signed [BIT_WIDTH - 1:0] oData_R,
    output reg signed [BIT_WIDTH - 1:0] oData_I
);
    localparam MUL_POS1 = 2'b00;
    localparam MUL_NEG1 = 2'b01;
    localparam MUL_POSJ = 2'b10;
    localparam MUL_NEGJ = 2'b11;
    
    always @(*) begin
        case (mode)
            MUL_POS1: begin oData_I =  iData_I; oData_R =  iData_R; end
            MUL_NEG1: begin oData_I = -iData_I; oData_R = -iData_R; end
            MUL_POSJ: begin oData_I =  iData_R; oData_R = -iData_I; end
            MUL_NEGJ: begin oData_I = -iData_R; oData_R =  iData_I; end
            default: begin oData_I = iData_I; oData_R = iData_R; end
        endcase
    end
    
endmodule