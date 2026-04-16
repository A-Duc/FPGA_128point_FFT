module fft_s6_rom_path2(
    input  wire        iAddress,
    output reg  [49:0] oData
);

    always @(*) begin
    case (iAddress)
        1'd0: oData = {2'd0, 24'h000000, 24'h000028}; // th=-0.00000 a=-0.00000 Ki=1.000000 rc=1.000000 ke=0.00E+00(0.00L) ae=0.00E+00 sig={0,0,0,0,0,0}
        1'd1: oData = {2'd3, 24'h100000, 24'hC739A7}; // th=-0.78540 a=0.78540 Ki=0.707107 rc=0.710938 ke=3.83E-03(0.98L) ae=0.00E+00 sig={1,0,0,0,0,0}
        default: oData = 50'h0;
    endcase
end

endmodule