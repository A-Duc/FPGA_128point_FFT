// Verilog ROM Table for Stage 2 - Path 3 (p=3)
always @(*) begin
    case (n3)
            5'd00: {quad, sigma, scale_cmds} = {2'd0, 24'h000000, 28'h000005E}; // Angle: 0.0000 rad
            5'd01: {quad, sigma, scale_cmds} = {2'd0, 24'h0114EF, 28'hCFC3BDE}; // Angle: 0.1473 rad
            5'd02: {quad, sigma, scale_cmds} = {2'd0, 24'h023131, 28'hE34FCDE}; // Angle: 0.2945 rad
            5'd03: {quad, sigma, scale_cmds} = {2'd0, 24'h04FDE4, 28'hAD63DDE}; // Angle: 0.4418 rad
            5'd04: {quad, sigma, scale_cmds} = {2'd0, 24'h1E31F3, 28'hEBEBE5E}; // Angle: 0.5890 rad
            5'd05: {quad, sigma, scale_cmds} = {2'd0, 24'h10DFFE, 28'hB1EBE5E}; // Angle: 0.7363 rad
            5'd06: {quad, sigma, scale_cmds} = {2'd1, 24'hF1E3DE, 28'hB1EBE5E}; // Angle: 0.8836 rad
            5'd07: {quad, sigma, scale_cmds} = {2'd1, 24'hF2002F, 28'hEBEBE5E}; // Angle: 1.0308 rad
            5'd08: {quad, sigma, scale_cmds} = {2'd1, 24'h0DEFD0, 28'hA5D7D5E}; // Angle: 1.1781 rad
            5'd09: {quad, sigma, scale_cmds} = {2'd1, 24'h0E00E1, 28'hE757CDE}; // Angle: 1.3254 rad
            5'd10: {quad, sigma, scale_cmds} = {2'd1, 24'h0F2D32, 28'hA1CFBDE}; // Angle: 1.4726 rad
            5'd11: {quad, sigma, scale_cmds} = {2'd1, 24'h003112, 28'hCFC7A5E}; // Angle: 1.6199 rad
            5'd12: {quad, sigma, scale_cmds} = {2'd1, 24'h02DF1D, 28'hE34FCDE}; // Angle: 1.7671 rad
            5'd13: {quad, sigma, scale_cmds} = {2'd1, 24'h03F02F, 28'hE5D3D5E}; // Angle: 1.9144 rad
            5'd14: {quad, sigma, scale_cmds} = {2'd1, 24'h1EDFDF, 28'hEBEBE5E}; // Angle: 2.0617 rad
            5'd15: {quad, sigma, scale_cmds} = {2'd1, 24'h1FFC21, 28'hB1EBE5E}; // Angle: 2.2089 rad
            5'd16: {quad, sigma, scale_cmds} = {2'd2, 24'hF00000, 28'hB1EBE5E}; // Angle: 2.3562 rad
            5'd17: {quad, sigma, scale_cmds} = {2'd2, 24'hF114EF, 28'hB1EBE5E}; // Angle: 2.5035 rad
            5'd18: {quad, sigma, scale_cmds} = {2'd2, 24'hF23131, 28'hEBEBE5E}; // Angle: 2.6507 rad
            5'd19: {quad, sigma, scale_cmds} = {2'd2, 24'h0D10E1, 28'hE5D3D5E}; // Angle: 2.7980 rad
            5'd20: {quad, sigma, scale_cmds} = {2'd2, 24'h0E31F3, 28'hE34FCDE}; // Angle: 2.9452 rad
            5'd21: {quad, sigma, scale_cmds} = {2'd2, 24'h00DFFE, 28'hCFC7A5E}; // Angle: 3.0925 rad
            5'd22: {quad, sigma, scale_cmds} = {2'd2, 24'h01E3DE, 28'hA1CFBDE}; // Angle: 3.2398 rad
            5'd23: {quad, sigma, scale_cmds} = {2'd2, 24'h02002F, 28'hE757CDE}; // Angle: 3.3870 rad
            5'd24: {quad, sigma, scale_cmds} = {2'd2, 24'h032130, 28'hA5D7D5E}; // Angle: 3.5343 rad
            5'd25: {quad, sigma, scale_cmds} = {2'd2, 24'h1E00E1, 28'hEBEBE5E}; // Angle: 3.6816 rad
            5'd26: {quad, sigma, scale_cmds} = {2'd2, 24'h1F2D32, 28'hB1EBE5E}; // Angle: 3.8288 rad
            5'd27: {quad, sigma, scale_cmds} = {2'd3, 24'hF03112, 28'hB1EBE5E}; // Angle: 3.9761 rad
            5'd28: {quad, sigma, scale_cmds} = {2'd3, 24'hF2DF1D, 28'hEBEBE5E}; // Angle: 4.1233 rad
            5'd29: {quad, sigma, scale_cmds} = {2'd3, 24'h0C132C, 28'hAD63DDE}; // Angle: 4.2706 rad
            5'd30: {quad, sigma, scale_cmds} = {2'd3, 24'h0EDFDF, 28'hE34FCDE}; // Angle: 4.4179 rad
            5'd31: {quad, sigma, scale_cmds} = {2'd3, 24'h0FFC21, 28'hCFC3BDE}; // Angle: 4.5651 rad
            default: {quad, sigma, scale_cmds} = 54'h0;
    endcase
end