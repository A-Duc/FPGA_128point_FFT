module fft_s2_rom_path2 (
    input  wire [4:0]  iAddress,
    output reg  [53:0] oData
);

    // Bit mapping of oData:
    // oData[53:52] = quad
    // oData[51:28] = sigma
    // oData[27:0]  = scale_cmds

    always @(*) begin
        case (iAddress)
            5'd00: oData = {2'd0, 24'h000000, 28'h000005E}; // Angle: 0.0000 rad
            5'd01: oData = {2'd0, 24'h003112, 28'hCFC7A5E}; // Angle: 0.0491 rad
            5'd02: oData = {2'd0, 24'h01E3DE, 28'hA1CFBDE}; // Angle: 0.0982 rad
            5'd03: oData = {2'd0, 24'h0114EF, 28'hCFC3BDE}; // Angle: 0.1473 rad
            5'd04: oData = {2'd0, 24'h02DF1D, 28'hE34FCDE}; // Angle: 0.1963 rad
            5'd05: oData = {2'd0, 24'h02002F, 28'hE757CDE}; // Angle: 0.2454 rad
            5'd06: oData = {2'd0, 24'h023131, 28'hE34FCDE}; // Angle: 0.2945 rad
            5'd07: oData = {2'd0, 24'h03F02F, 28'hE5D3D5E}; // Angle: 0.3436 rad
            5'd08: oData = {2'd0, 24'h032130, 28'hA5D7D5E}; // Angle: 0.3927 rad
            5'd09: oData = {2'd0, 24'h04FDE4, 28'hAD63DDE}; // Angle: 0.4418 rad
            5'd10: oData = {2'd0, 24'h1EDFDF, 28'hEBEBE5E}; // Angle: 0.4909 rad
            5'd11: oData = {2'd0, 24'h1E00E1, 28'hEBEBE5E}; // Angle: 0.5400 rad
            5'd12: oData = {2'd0, 24'h1E31F3, 28'hEBEBE5E}; // Angle: 0.5890 rad
            5'd13: oData = {2'd0, 24'h1FFC21, 28'hB1EBE5E}; // Angle: 0.6381 rad
            5'd14: oData = {2'd0, 24'h1F2D32, 28'hB1EBE5E}; // Angle: 0.6872 rad
            5'd15: oData = {2'd0, 24'h10DFFE, 28'hB1EBE5E}; // Angle: 0.7363 rad
            5'd16: oData = {2'd1, 24'hF00000, 28'hB1EBE5E}; // Angle: 0.7854 rad
            5'd17: oData = {2'd1, 24'hF03112, 28'hB1EBE5E}; // Angle: 0.8345 rad
            5'd18: oData = {2'd1, 24'hF1E3DE, 28'hB1EBE5E}; // Angle: 0.8836 rad
            5'd19: oData = {2'd1, 24'hF114EF, 28'hB1EBE5E}; // Angle: 0.9327 rad
            5'd20: oData = {2'd1, 24'hF2DF1D, 28'hEBEBE5E}; // Angle: 0.9817 rad
            5'd21: oData = {2'd1, 24'hF2002F, 28'hEBEBE5E}; // Angle: 1.0308 rad
            5'd22: oData = {2'd1, 24'hF23131, 28'hEBEBE5E}; // Angle: 1.0799 rad
            5'd23: oData = {2'd1, 24'h0C132C, 28'hAD63DDE}; // Angle: 1.1290 rad
            5'd24: oData = {2'd1, 24'h0DEFD0, 28'hA5D7D5E}; // Angle: 1.1781 rad
            5'd25: oData = {2'd1, 24'h0D10E1, 28'hE5D3D5E}; // Angle: 1.2272 rad
            5'd26: oData = {2'd1, 24'h0EDFDF, 28'hE34FCDE}; // Angle: 1.2763 rad
            5'd27: oData = {2'd1, 24'h0E00E1, 28'hE757CDE}; // Angle: 1.3254 rad
            5'd28: oData = {2'd1, 24'h0E31F3, 28'hE34FCDE}; // Angle: 1.3744 rad
            5'd29: oData = {2'd1, 24'h0FFC21, 28'hCFC3BDE}; // Angle: 1.4235 rad
            5'd30: oData = {2'd1, 24'h0F2D32, 28'hA1CFBDE}; // Angle: 1.4726 rad
            5'd31: oData = {2'd1, 24'h00DFFE, 28'hCFC7A5E}; // Angle: 1.5217 rad
            default: oData = 54'd0;
        endcase
    end

endmodule