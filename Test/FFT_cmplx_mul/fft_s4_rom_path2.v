module fft_s4_rom_path2(
    input  wire [2:0] iAddress,
    output reg  [31:0] oData
);
    // oData = {twiddle_real_q15, twiddle_imag_q15}
    always @(*) begin
        case (iAddress)
            3'd0: oData = {16'h7FFF, 16'h0000}; // k=  0
            3'd1: oData = {16'h7D8A, 16'hE707}; // k=  4
            3'd2: oData = {16'h7642, 16'hCF04}; // k=  8
            3'd3: oData = {16'h6A6E, 16'hB8E3}; // k= 12
            3'd4: oData = {16'h5A82, 16'hA57E}; // k= 16
            3'd5: oData = {16'h471D, 16'h9592}; // k= 20
            3'd6: oData = {16'h30FC, 16'h89BE}; // k= 24
            3'd7: oData = {16'h18F9, 16'h8276}; // k= 28
            default: oData = 32'h0000_0000;
        endcase
    end
endmodule
