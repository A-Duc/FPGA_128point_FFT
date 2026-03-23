module mul_minus_j(
    input  signed [15:0] iData_R,  
    input  signed [15:0] iData_I,  

    output signed [15:0] oData_R,
    output signed [15:0] oData_I
);
    assign oData_I = -iData_R;
    assign oData_R =  iData_I;
    
endmodule