// Verilog ROM Table for Stage 2 - Path 2 (p=2)
always @(*) begin
    case (n3)
        5'd0: {quad, sigma, scale_cmds} = {2'd0, 30'h00000000, 28'h000005E}; // theta=-0.000000 rad
        5'd1: {quad, sigma, scale_cmds} = {2'd0, 30'h01E3EC83, 28'hDFCBBDE}; // theta=-0.098175 rad
        5'd2: {quad, sigma, scale_cmds} = {2'd0, 30'h01DE8FFF, 28'hA7D7C5E}; // theta=-0.196350 rad
        5'd3: {quad, sigma, scale_cmds} = {2'd0, 30'h01B1089F, 28'hAB63D5E}; // theta=-0.294524 rad
        5'd4: {quad, sigma, scale_cmds} = {2'd0, 30'h0192879F, 28'hAF67DDE}; // theta=-0.392699 rad
        5'd5: {quad, sigma, scale_cmds} = {2'd0, 30'h3E5F7B81, 28'hF1EBE5E}; // theta=-0.490874 rad
        5'd6: {quad, sigma, scale_cmds} = {2'd0, 30'h3E31F421, 28'hAFEBE5E}; // theta=-0.589049 rad
        5'd7: {quad, sigma, scale_cmds} = {2'd0, 30'h3E2C979D, 28'hB1EBE5E}; // theta=-0.687223 rad
        5'd8: {quad, sigma, scale_cmds} = {2'd0, 30'h3E000000, 28'hB1EBE5E}; // theta=-0.785398 rad
        5'd9: {quad, sigma, scale_cmds} = {2'd3, 30'h03E3EC83, 28'hB1EBE5E}; // theta=-0.883573 rad
        5'd10: {quad, sigma, scale_cmds} = {2'd3, 30'h03DE8FFF, 28'hAFEBE5E}; // theta=-0.981748 rad
        5'd11: {quad, sigma, scale_cmds} = {2'd3, 30'h03B1089F, 28'hF1EBE5E}; // theta=-1.079922 rad
        5'd12: {quad, sigma, scale_cmds} = {2'd3, 30'h007DFC81, 28'hAF67DDE}; // theta=-1.178097 rad
        5'd13: {quad, sigma, scale_cmds} = {2'd3, 30'h005F7B81, 28'hAB63D5E}; // theta=-1.276272 rad
        5'd14: {quad, sigma, scale_cmds} = {2'd3, 30'h0031F421, 28'hA7D7C5E}; // theta=-1.374447 rad
        5'd15: {quad, sigma, scale_cmds} = {2'd3, 30'h002C979D, 28'hDFCBBDE}; // theta=-1.472622 rad
        5'd16: {quad, sigma, scale_cmds} = {2'd3, 30'h00000000, 28'h000005E}; // theta=-1.570796 rad
        5'd17: {quad, sigma, scale_cmds} = {2'd3, 30'h01E3EC83, 28'hDFCBBDE}; // theta=-1.668971 rad
        5'd18: {quad, sigma, scale_cmds} = {2'd3, 30'h01DE8FFF, 28'hA7D7C5E}; // theta=-1.767146 rad
        5'd19: {quad, sigma, scale_cmds} = {2'd3, 30'h01B1089F, 28'hAB63D5E}; // theta=-1.865321 rad
        5'd20: {quad, sigma, scale_cmds} = {2'd3, 30'h0192879F, 28'hAF67DDE}; // theta=-1.963495 rad
        5'd21: {quad, sigma, scale_cmds} = {2'd3, 30'h3E5F7B81, 28'hF1EBE5E}; // theta=-2.061670 rad
        5'd22: {quad, sigma, scale_cmds} = {2'd3, 30'h3E31F421, 28'hAFEBE5E}; // theta=-2.159845 rad
        5'd23: {quad, sigma, scale_cmds} = {2'd3, 30'h3E2C979D, 28'hB1EBE5E}; // theta=-2.258020 rad
        5'd24: {quad, sigma, scale_cmds} = {2'd3, 30'h3E000000, 28'hB1EBE5E}; // theta=-2.356194 rad
        5'd25: {quad, sigma, scale_cmds} = {2'd2, 30'h03E3EC83, 28'hB1EBE5E}; // theta=-2.454369 rad
        5'd26: {quad, sigma, scale_cmds} = {2'd2, 30'h03DE8FFF, 28'hAFEBE5E}; // theta=-2.552544 rad
        5'd27: {quad, sigma, scale_cmds} = {2'd2, 30'h03B1089F, 28'hF1EBE5E}; // theta=-2.650719 rad
        5'd28: {quad, sigma, scale_cmds} = {2'd2, 30'h007DFC81, 28'hAF67DDE}; // theta=-2.748894 rad
        5'd29: {quad, sigma, scale_cmds} = {2'd2, 30'h005F7B81, 28'hAB63D5E}; // theta=-2.847068 rad
        5'd30: {quad, sigma, scale_cmds} = {2'd2, 30'h0031F421, 28'hA7D7C5E}; // theta=-2.945243 rad
        5'd31: {quad, sigma, scale_cmds} = {2'd2, 30'h002C979D, 28'hDFCBBDE}; // theta=-3.043418 rad
        default: {quad, sigma, scale_cmds} = 60'h0;
    endcase
end
