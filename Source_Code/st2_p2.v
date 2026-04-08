// Verilog ROM Table for Stage 2 - Path 2 (p=2)
always @(*) begin
    case (n3)
            5'd00: {quad, sigma, scale_cmds} = {2'd0, 24'h000000, 28'h000005E}; // Angle: 0.0000 rad
            5'd01: {quad, sigma, scale_cmds} = {2'd0, 24'h01E3DE, 28'hA1CFBDE}; // Angle: 0.0982 rad
            5'd02: {quad, sigma, scale_cmds} = {2'd0, 24'h02DF1D, 28'hE34FCDE}; // Angle: 0.1963 rad
            5'd03: {quad, sigma, scale_cmds} = {2'd0, 24'h023131, 28'hE34FCDE}; // Angle: 0.2945 rad
            5'd04: {quad, sigma, scale_cmds} = {2'd0, 24'h032130, 28'hA5D7D5E}; // Angle: 0.3927 rad
            5'd05: {quad, sigma, scale_cmds} = {2'd0, 24'h1EDFDF, 28'hEBEBE5E}; // Angle: 0.4909 rad
            5'd06: {quad, sigma, scale_cmds} = {2'd0, 24'h1E31F3, 28'hEBEBE5E}; // Angle: 0.5890 rad
            5'd07: {quad, sigma, scale_cmds} = {2'd0, 24'h1F2D32, 28'hB1EBE5E}; // Angle: 0.6872 rad
            5'd08: {quad, sigma, scale_cmds} = {2'd1, 24'hF00000, 28'hB1EBE5E}; // Angle: 0.7854 rad
            5'd09: {quad, sigma, scale_cmds} = {2'd1, 24'hF1E3DE, 28'hB1EBE5E}; // Angle: 0.8836 rad
            5'd10: {quad, sigma, scale_cmds} = {2'd1, 24'hF2DF1D, 28'hEBEBE5E}; // Angle: 0.9817 rad
            5'd11: {quad, sigma, scale_cmds} = {2'd1, 24'hF23131, 28'hEBEBE5E}; // Angle: 1.0799 rad
            5'd12: {quad, sigma, scale_cmds} = {2'd1, 24'h0DEFD0, 28'hA5D7D5E}; // Angle: 1.1781 rad
            5'd13: {quad, sigma, scale_cmds} = {2'd1, 24'h0EDFDF, 28'hE34FCDE}; // Angle: 1.2763 rad
            5'd14: {quad, sigma, scale_cmds} = {2'd1, 24'h0E31F3, 28'hE34FCDE}; // Angle: 1.3744 rad
            5'd15: {quad, sigma, scale_cmds} = {2'd1, 24'h0F2D32, 28'hA1CFBDE}; // Angle: 1.4726 rad
            5'd16: {quad, sigma, scale_cmds} = {2'd1, 24'h000000, 28'h000005E}; // Angle: 1.5708 rad
            5'd17: {quad, sigma, scale_cmds} = {2'd1, 24'h01E3DE, 28'hA1CFBDE}; // Angle: 1.6690 rad
            5'd18: {quad, sigma, scale_cmds} = {2'd1, 24'h02DF1D, 28'hE34FCDE}; // Angle: 1.7671 rad
            5'd19: {quad, sigma, scale_cmds} = {2'd1, 24'h023131, 28'hE34FCDE}; // Angle: 1.8653 rad
            5'd20: {quad, sigma, scale_cmds} = {2'd1, 24'h032130, 28'hA5D7D5E}; // Angle: 1.9635 rad
            5'd21: {quad, sigma, scale_cmds} = {2'd1, 24'h1EDFDF, 28'hEBEBE5E}; // Angle: 2.0617 rad
            5'd22: {quad, sigma, scale_cmds} = {2'd1, 24'h1E31F3, 28'hEBEBE5E}; // Angle: 2.1598 rad
            5'd23: {quad, sigma, scale_cmds} = {2'd1, 24'h1F2D32, 28'hB1EBE5E}; // Angle: 2.2580 rad
            5'd24: {quad, sigma, scale_cmds} = {2'd2, 24'hF00000, 28'hB1EBE5E}; // Angle: 2.3562 rad
            5'd25: {quad, sigma, scale_cmds} = {2'd2, 24'hF1E3DE, 28'hB1EBE5E}; // Angle: 2.4544 rad
            5'd26: {quad, sigma, scale_cmds} = {2'd2, 24'hF2DF1D, 28'hEBEBE5E}; // Angle: 2.5525 rad
            5'd27: {quad, sigma, scale_cmds} = {2'd2, 24'hF23131, 28'hEBEBE5E}; // Angle: 2.6507 rad
            5'd28: {quad, sigma, scale_cmds} = {2'd2, 24'h0DEFD0, 28'hA5D7D5E}; // Angle: 2.7489 rad
            5'd29: {quad, sigma, scale_cmds} = {2'd2, 24'h0EDFDF, 28'hE34FCDE}; // Angle: 2.8471 rad
            5'd30: {quad, sigma, scale_cmds} = {2'd2, 24'h0E31F3, 28'hE34FCDE}; // Angle: 2.9452 rad
            5'd31: {quad, sigma, scale_cmds} = {2'd2, 24'h0F2D32, 28'hA1CFBDE}; // Angle: 3.0434 rad
            default: {quad, sigma, scale_cmds} = 54'h0;
    endcase
end