module fft_s2_rom_path3(
    input  wire [4:0] iAddress,
    output reg  [31:0] oData
);
    // oData = {twiddle_real_q15, twiddle_imag_q15}
    always @(*) begin
        case (iAddress)
            5'd0: oData = {16'h7FFF, 16'h0000}; // k=  0
            5'd1: oData = {16'h7E9D, 16'hED38}; // k=  3
            5'd2: oData = {16'h7A7D, 16'hDAD8}; // k=  6
            5'd3: oData = {16'h73B6, 16'hC946}; // k=  9
            5'd4: oData = {16'h6A6E, 16'hB8E3}; // k= 12
            5'd5: oData = {16'h5ED7, 16'hAA0A}; // k= 15
            5'd6: oData = {16'h5134, 16'h9D0E}; // k= 18
            5'd7: oData = {16'h41CE, 16'h9236}; // k= 21
            5'd8: oData = {16'h30FC, 16'h89BE}; // k= 24
            5'd9: oData = {16'h1F1A, 16'h83D6}; // k= 27
            5'd10: oData = {16'h0C8C, 16'h809E}; // k= 30
            5'd11: oData = {16'hF9B8, 16'h8027}; // k= 33
            5'd12: oData = {16'hE707, 16'h8276}; // k= 36
            5'd13: oData = {16'hD4E1, 16'h877B}; // k= 39
            5'd14: oData = {16'hC3A9, 16'h8F1D}; // k= 42
            5'd15: oData = {16'hB3C0, 16'h9930}; // k= 45
            5'd16: oData = {16'hA57E, 16'hA57E}; // k= 48
            5'd17: oData = {16'h9930, 16'hB3C0}; // k= 51
            5'd18: oData = {16'h8F1D, 16'hC3A9}; // k= 54
            5'd19: oData = {16'h877B, 16'hD4E1}; // k= 57
            5'd20: oData = {16'h8276, 16'hE707}; // k= 60
            5'd21: oData = {16'h8027, 16'hF9B8}; // k= 63
            5'd22: oData = {16'h809E, 16'h0C8C}; // k= 66
            5'd23: oData = {16'h83D6, 16'h1F1A}; // k= 69
            5'd24: oData = {16'h89BE, 16'h30FC}; // k= 72
            5'd25: oData = {16'h9236, 16'h41CE}; // k= 75
            5'd26: oData = {16'h9D0E, 16'h5134}; // k= 78
            5'd27: oData = {16'hAA0A, 16'h5ED7}; // k= 81
            5'd28: oData = {16'hB8E3, 16'h6A6E}; // k= 84
            5'd29: oData = {16'hC946, 16'h73B6}; // k= 87
            5'd30: oData = {16'hDAD8, 16'h7A7D}; // k= 90
            5'd31: oData = {16'hED38, 16'h7E9D}; // k= 93
            default: oData = 32'h0000_0000;
        endcase
    end
endmodule
