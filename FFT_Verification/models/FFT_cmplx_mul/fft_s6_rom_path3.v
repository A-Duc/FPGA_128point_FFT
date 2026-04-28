module fft_s6_rom_path3(
    input  wire [0:0] iAddress,
    output reg  [31:0] oData
);
    // oData = {twiddle_real_q15, twiddle_imag_q15}
    always @(*) begin
        case (iAddress)
            1'd0: oData = {16'h7FFF, 16'h0000}; // k=  0
            1'd1: oData = {16'hA57E, 16'hA57E}; // k= 48
            default: oData = 32'h0000_0000;
        endcase
    end
endmodule
