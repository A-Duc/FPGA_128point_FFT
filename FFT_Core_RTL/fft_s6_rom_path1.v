module fft_s6_rom_path1(
    input  wire        iAddress,
    output reg  [49:0] oData
);

    always @(*) begin
    case (iAddress)
        1'd0: oData = {2'd0, 24'h000000, 24'h000028}; // th=-0.00000 a=-0.00000 Ki=1.000000 rc=1.000000 ke=0.00E+00(0.00L) ae=0.00E+00 sig={0,0,0,0,0,0}
        1'd1: oData = {2'd3, 24'h000000, 24'h000028}; // th=-1.57080 a=0.00000 Ki=1.000000 rc=1.000000 ke=0.00E+00(0.00L) ae=0.00E+00 sig={0,0,0,0,0,0}
        default: oData = 50'h0;
    endcase
end

endmodule