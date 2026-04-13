module fft_s2_rom_path1(
    input  wire [4:0] iAddress,
    output reg  [31:0] oData
);
    // oData = {twiddle_real_q15, twiddle_imag_q15}
    always @(*) begin
        case (iAddress)
            5'd0: oData = {16'h7FFF, 16'h0000}; // k=  0
            5'd1: oData = {16'h7F62, 16'hF374}; // k=  2
            5'd2: oData = {16'h7D8A, 16'hE707}; // k=  4
            5'd3: oData = {16'h7A7D, 16'hDAD8}; // k=  6
            5'd4: oData = {16'h7642, 16'hCF04}; // k=  8
            5'd5: oData = {16'h70E3, 16'hC3A9}; // k= 10
            5'd6: oData = {16'h6A6E, 16'hB8E3}; // k= 12
            5'd7: oData = {16'h62F2, 16'hAECC}; // k= 14
            5'd8: oData = {16'h5A82, 16'hA57E}; // k= 16
            5'd9: oData = {16'h5134, 16'h9D0E}; // k= 18
            5'd10: oData = {16'h471D, 16'h9592}; // k= 20
            5'd11: oData = {16'h3C57, 16'h8F1D}; // k= 22
            5'd12: oData = {16'h30FC, 16'h89BE}; // k= 24
            5'd13: oData = {16'h2528, 16'h8583}; // k= 26
            5'd14: oData = {16'h18F9, 16'h8276}; // k= 28
            5'd15: oData = {16'h0C8C, 16'h809E}; // k= 30
            5'd16: oData = {16'h0000, 16'h8000}; // k= 32
            5'd17: oData = {16'hF374, 16'h809E}; // k= 34
            5'd18: oData = {16'hE707, 16'h8276}; // k= 36
            5'd19: oData = {16'hDAD8, 16'h8583}; // k= 38
            5'd20: oData = {16'hCF04, 16'h89BE}; // k= 40
            5'd21: oData = {16'hC3A9, 16'h8F1D}; // k= 42
            5'd22: oData = {16'hB8E3, 16'h9592}; // k= 44
            5'd23: oData = {16'hAECC, 16'h9D0E}; // k= 46
            5'd24: oData = {16'hA57E, 16'hA57E}; // k= 48
            5'd25: oData = {16'h9D0E, 16'hAECC}; // k= 50
            5'd26: oData = {16'h9592, 16'hB8E3}; // k= 52
            5'd27: oData = {16'h8F1D, 16'hC3A9}; // k= 54
            5'd28: oData = {16'h89BE, 16'hCF04}; // k= 56
            5'd29: oData = {16'h8583, 16'hDAD8}; // k= 58
            5'd30: oData = {16'h8276, 16'hE707}; // k= 60
            5'd31: oData = {16'h809E, 16'hF374}; // k= 62
            default: oData = 32'h0000_0000;
        endcase
    end
endmodule
