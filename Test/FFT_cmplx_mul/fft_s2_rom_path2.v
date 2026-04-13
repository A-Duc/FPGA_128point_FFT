module fft_s2_rom_path2(
    input  wire [4:0] iAddress,
    output reg  [31:0] oData
);
    // oData = {twiddle_real_q15, twiddle_imag_q15}
    always @(*) begin
        case (iAddress)
            5'd0: oData = {16'h7FFF, 16'h0000}; // k=  0
            5'd1: oData = {16'h7FD9, 16'hF9B8}; // k=  1
            5'd2: oData = {16'h7F62, 16'hF374}; // k=  2
            5'd3: oData = {16'h7E9D, 16'hED38}; // k=  3
            5'd4: oData = {16'h7D8A, 16'hE707}; // k=  4
            5'd5: oData = {16'h7C2A, 16'hE0E6}; // k=  5
            5'd6: oData = {16'h7A7D, 16'hDAD8}; // k=  6
            5'd7: oData = {16'h7885, 16'hD4E1}; // k=  7
            5'd8: oData = {16'h7642, 16'hCF04}; // k=  8
            5'd9: oData = {16'h73B6, 16'hC946}; // k=  9
            5'd10: oData = {16'h70E3, 16'hC3A9}; // k= 10
            5'd11: oData = {16'h6DCA, 16'hBE32}; // k= 11
            5'd12: oData = {16'h6A6E, 16'hB8E3}; // k= 12
            5'd13: oData = {16'h66D0, 16'hB3C0}; // k= 13
            5'd14: oData = {16'h62F2, 16'hAECC}; // k= 14
            5'd15: oData = {16'h5ED7, 16'hAA0A}; // k= 15
            5'd16: oData = {16'h5A82, 16'hA57E}; // k= 16
            5'd17: oData = {16'h55F6, 16'hA129}; // k= 17
            5'd18: oData = {16'h5134, 16'h9D0E}; // k= 18
            5'd19: oData = {16'h4C40, 16'h9930}; // k= 19
            5'd20: oData = {16'h471D, 16'h9592}; // k= 20
            5'd21: oData = {16'h41CE, 16'h9236}; // k= 21
            5'd22: oData = {16'h3C57, 16'h8F1D}; // k= 22
            5'd23: oData = {16'h36BA, 16'h8C4A}; // k= 23
            5'd24: oData = {16'h30FC, 16'h89BE}; // k= 24
            5'd25: oData = {16'h2B1F, 16'h877B}; // k= 25
            5'd26: oData = {16'h2528, 16'h8583}; // k= 26
            5'd27: oData = {16'h1F1A, 16'h83D6}; // k= 27
            5'd28: oData = {16'h18F9, 16'h8276}; // k= 28
            5'd29: oData = {16'h12C8, 16'h8163}; // k= 29
            5'd30: oData = {16'h0C8C, 16'h809E}; // k= 30
            5'd31: oData = {16'h0648, 16'h8027}; // k= 31
            default: oData = 32'h0000_0000;
        endcase
    end
endmodule
