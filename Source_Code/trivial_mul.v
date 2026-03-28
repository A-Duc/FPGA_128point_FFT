module trivial_mul(
    input         [1:0]  mode,

    input  signed [15:0] iData_R,  
    input  signed [15:0] iData_I,  

    output reg signed [15:0] oData_R,
    output reg signed [15:0] oData_I
);
    always @(*) begin
        case (mode)
            2'b00: begin oData_I =  iData_I; oData_R =  iData_R; end
            2'b01: begin oData_I = -iData_I; oData_R = -iData_R; end
            2'b10: begin oData_I =  iData_R; oData_R = -iData_I; end
            2'b11: begin oData_I = -iData_R; oData_R =  iData_I; end
            default: begin oData_I = iData_I; oData_R = iData_R; end
        endcase
    end
    
endmodule