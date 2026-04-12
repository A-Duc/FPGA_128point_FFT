module fft_s2_rom_path3(
    input  wire [4:0]  iAddress,
    output reg  [53:0] oData
);

    always @(*) begin
        case (iAddress)
            5'd0:  oData = {2'd0, 24'h000000, 28'h000005E}; // theta=-0.000000 rad, Kinv~=1.000000
            5'd1:  oData = {2'd0, 24'h0FFC21, 28'hCFC3BDE}; // theta=-0.147262 rad, Kinv~=0.992126
            5'd2:  oData = {2'd0, 24'h0EDFDF, 28'hE34FCDE}; // theta=-0.294524 rad, Kinv~=0.969076
            5'd3:  oData = {2'd0, 24'h0C132C, 28'hAD63DDE}; // theta=-0.441786 rad, Kinv~=0.894303
            5'd4:  oData = {2'd0, 24'hF2DF1D, 28'hEBEBE5E}; // theta=-0.589049 rad, Kinv~=0.685241
            5'd5:  oData = {2'd0, 24'hF03112, 28'hB1EBE5E}; // theta=-0.736311 rad, Kinv~=0.706330
            5'd6:  oData = {2'd3, 24'h1F2D32, 28'hB1EBE5E}; // theta=-0.883573 rad, Kinv~=0.701292
            5'd7:  oData = {2'd3, 24'h1E00E1, 28'hEBEBE5E}; // theta=-1.030835 rad, Kinv~=0.685994
            5'd8:  oData = {2'd3, 24'h032130, 28'hA5D7D5E}; // theta=-1.178097 rad, Kinv~=0.935870
            5'd9:  oData = {2'd3, 24'h02002F, 28'hE757CDE}; // theta=-1.325359 rad, Kinv~=0.970142
            5'd10: oData = {2'd3, 24'h01E3DE, 28'hA1CFBDE}; // theta=-1.472622 rad, Kinv~=0.991776
            5'd11: oData = {2'd3, 24'h00DFFE, 28'hCFC7A5E}; // theta=-1.619884 rad, Kinv~=0.998901
            5'd12: oData = {2'd3, 24'h0E31F3, 28'hE34FCDE}; // theta=-1.767146 rad, Kinv~=0.969077
            5'd13: oData = {2'd3, 24'h0D10E1, 28'hE5D3D5E}; // theta=-1.914408 rad, Kinv~=0.936215
            5'd14: oData = {2'd3, 24'hF23131, 28'hEBEBE5E}; // theta=-2.061670 rad, Kinv~=0.685240
            5'd15: oData = {2'd3, 24'hF114EF, 28'hB1EBE5E}; // theta=-2.208932 rad, Kinv~=0.701539
            5'd16: oData = {2'd3, 24'hF00000, 28'hB1EBE5E}; // theta=-2.356194 rad, Kinv~=0.707107
            5'd17: oData = {2'd2, 24'h1FFC21, 28'hB1EBE5E}; // theta=-2.503457 rad, Kinv~=0.701539
            5'd18: oData = {2'd2, 24'h1EDFDF, 28'hEBEBE5E}; // theta=-2.650719 rad, Kinv~=0.685240
            5'd19: oData = {2'd2, 24'h03F02F, 28'hE5D3D5E}; // theta=-2.797981 rad, Kinv~=0.936215
            5'd20: oData = {2'd2, 24'h02DF1D, 28'hE34FCDE}; // theta=-2.945243 rad, Kinv~=0.969077
            5'd21: oData = {2'd2, 24'h003112, 28'hCFC7A5E}; // theta=-3.092505 rad, Kinv~=0.998901
            5'd22: oData = {2'd2, 24'h0F2D32, 28'hA1CFBDE}; // theta=-3.239767 rad, Kinv~=0.991776
            5'd23: oData = {2'd2, 24'h0E00E1, 28'hE757CDE}; // theta=-3.387030 rad, Kinv~=0.970142
            5'd24: oData = {2'd2, 24'h0DEFD0, 28'hA5D7D5E}; // theta=-3.534292 rad, Kinv~=0.935870
            5'd25: oData = {2'd2, 24'hF2002F, 28'hEBEBE5E}; // theta=-3.681554 rad, Kinv~=0.685994
            5'd26: oData = {2'd2, 24'hF1E3DE, 28'hB1EBE5E}; // theta=-3.828816 rad, Kinv~=0.701292
            5'd27: oData = {2'd1, 24'h10DFFE, 28'hB1EBE5E}; // theta=-3.976078 rad, Kinv~=0.706330
            5'd28: oData = {2'd1, 24'h1E31F3, 28'hEBEBE5E}; // theta=-4.123340 rad, Kinv~=0.685241
            5'd29: oData = {2'd1, 24'h04FDE4, 28'hAD63DDE}; // theta=-4.270603 rad, Kinv~=0.894303
            5'd30: oData = {2'd1, 24'h023131, 28'hE34FCDE}; // theta=-4.417865 rad, Kinv~=0.969076
            5'd31: oData = {2'd1, 24'h0114EF, 28'hCFC3BDE}; // theta=-4.565127 rad, Kinv~=0.992126
            default: oData = 54'h0;
        endcase
    end

endmodule