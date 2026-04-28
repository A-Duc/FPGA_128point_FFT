module fft_s6_rom_path1(
    input  wire [0:0] iAddress,
    output reg  [31:0] oData
);
    // oData = {twiddle_real_q15, twiddle_imag_q15}
    always @(*) begin
        case (iAddress)
            1'd0: oData = {16'h7FFF, 16'h0000}; // k=  0
            1'd1: oData = {16'h0000, 16'h8000}; // k= 32
            default: oData = 32'h0000_0000;
        endcase
    end
endmodule
