// Verilog ROM Table for Stage 2 - Path 3 (p=3)
always @(*) begin
    case (n3)
        5'd0: {quad, sigma, scale_cmds} = {2'd0, 30'h00000000, 28'h000005E}; // theta=-0.000000 rad
        5'd1: {quad, sigma, scale_cmds} = {2'd0, 30'h01ED0848, 28'hA1CBBDE}; // theta=-0.147262 rad
        5'd2: {quad, sigma, scale_cmds} = {2'd0, 30'h01B1089F, 28'hAB63D5E}; // theta=-0.294524 rad
        5'd3: {quad, sigma, scale_cmds} = {2'd0, 30'h01836B20, 28'hAD63DDE}; // theta=-0.441786 rad
        5'd4: {quad, sigma, scale_cmds} = {2'd0, 30'h3E31F421, 28'hAFEBE5E}; // theta=-0.589049 rad
        5'd5: {quad, sigma, scale_cmds} = {2'd0, 30'h3E1EE4C4, 28'hB1EBE5E}; // theta=-0.736311 rad
        5'd6: {quad, sigma, scale_cmds} = {2'd3, 30'h03E3EC83, 28'hB1EBE5E}; // theta=-0.883573 rad
        5'd7: {quad, sigma, scale_cmds} = {2'd3, 30'h03C0785F, 28'hEBEBE5E}; // theta=-1.030835 rad
        5'd8: {quad, sigma, scale_cmds} = {2'd3, 30'h007DFC81, 28'hAF67DDE}; // theta=-1.178097 rad
        5'd9: {quad, sigma, scale_cmds} = {2'd3, 30'h00400BC1, 28'hE757CDE}; // theta=-1.325359 rad
        5'd10: {quad, sigma, scale_cmds} = {2'd3, 30'h002C979D, 28'hDFCBBDE}; // theta=-1.472622 rad
        5'd11: {quad, sigma, scale_cmds} = {2'd3, 30'h01F19F5C, 28'hD9C3ADE}; // theta=-1.619884 rad
        5'd12: {quad, sigma, scale_cmds} = {2'd3, 30'h01DE8FFF, 28'hA7D7C5E}; // theta=-1.767146 rad
        5'd13: {quad, sigma, scale_cmds} = {2'd3, 30'h01A27859, 28'hE5D3D5E}; // theta=-1.914408 rad
        5'd14: {quad, sigma, scale_cmds} = {2'd3, 30'h3E5F7B81, 28'hF1EBE5E}; // theta=-2.061670 rad
        5'd15: {quad, sigma, scale_cmds} = {2'd3, 30'h3E237BD8, 28'hB1EBE5E}; // theta=-2.208932 rad
        5'd16: {quad, sigma, scale_cmds} = {2'd3, 30'h3E000000, 28'hB1EBE5E}; // theta=-2.356194 rad
        5'd17: {quad, sigma, scale_cmds} = {2'd2, 30'h03ED0848, 28'hB1EBE5E}; // theta=-2.503457 rad
        5'd18: {quad, sigma, scale_cmds} = {2'd2, 30'h03B1089F, 28'hF1EBE5E}; // theta=-2.650719 rad
        5'd19: {quad, sigma, scale_cmds} = {2'd2, 30'h006E0BC7, 28'hE5D3D5E}; // theta=-2.797981 rad
        5'd20: {quad, sigma, scale_cmds} = {2'd2, 30'h0031F421, 28'hA7D7C5E}; // theta=-2.945243 rad
        5'd21: {quad, sigma, scale_cmds} = {2'd2, 30'h001EE4C4, 28'hD9C3ADE}; // theta=-3.092505 rad
        5'd22: {quad, sigma, scale_cmds} = {2'd2, 30'h01E3EC83, 28'hDFCBBDE}; // theta=-3.239767 rad
        5'd23: {quad, sigma, scale_cmds} = {2'd2, 30'h01C0785F, 28'hE757CDE}; // theta=-3.387030 rad
        5'd24: {quad, sigma, scale_cmds} = {2'd2, 30'h0192879F, 28'hAF67DDE}; // theta=-3.534292 rad
        5'd25: {quad, sigma, scale_cmds} = {2'd2, 30'h3E400BC1, 28'hEBEBE5E}; // theta=-3.681554 rad
        5'd26: {quad, sigma, scale_cmds} = {2'd2, 30'h3E2C979D, 28'hB1EBE5E}; // theta=-3.828816 rad
        5'd27: {quad, sigma, scale_cmds} = {2'd1, 30'h03F19F5C, 28'hB1EBE5E}; // theta=-3.976078 rad
        5'd28: {quad, sigma, scale_cmds} = {2'd1, 30'h03DE8FFF, 28'hAFEBE5E}; // theta=-4.123340 rad
        5'd29: {quad, sigma, scale_cmds} = {2'd1, 30'h008D18E0, 28'hAD63DDE}; // theta=-4.270603 rad
        5'd30: {quad, sigma, scale_cmds} = {2'd1, 30'h005F7B81, 28'hAB63D5E}; // theta=-4.417865 rad
        5'd31: {quad, sigma, scale_cmds} = {2'd1, 30'h00237BD8, 28'hA1CBBDE}; // theta=-4.565127 rad
        default: {quad, sigma, scale_cmds} = 60'h0;
    endcase
end
