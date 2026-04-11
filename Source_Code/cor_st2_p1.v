module cor_st2_p1(
    input wire [4:0] n3,         
    input wire clk,
    input wire rst,
    input wire signed [15:0] x_in,
    input wire signed [15:0] y_in,
    output wire [15:0] x_out,    
    output wire [15:0] y_out    
);

    reg [1:0]  quad;
    reg [23:0] sigma;
    reg [27:0] scale_cmds;

   always @(*) begin
    case (n3)
         5'd0: {quad, sigma, scale_cmds} = {2'd0, 24'h000000, 28'h000005E}; // theta=-0.000000 rad, KinvΓëê1.000000
        5'd1: {quad, sigma, scale_cmds} = {2'd0, 24'h00DFFE, 28'hCFC7A5E}; // theta=-0.049087 rad, KinvΓëê0.998901
        5'd2: {quad, sigma, scale_cmds} = {2'd0, 24'h0F2D32, 28'hA1CFBDE}; // theta=-0.098175 rad, KinvΓëê0.991776
        5'd3: {quad, sigma, scale_cmds} = {2'd0, 24'h0FFC21, 28'hCFC3BDE}; // theta=-0.147262 rad, KinvΓëê0.992126
        5'd4: {quad, sigma, scale_cmds} = {2'd0, 24'h0E31F3, 28'hE34FCDE}; // theta=-0.196350 rad, KinvΓëê0.969077
        5'd5: {quad, sigma, scale_cmds} = {2'd0, 24'h0E00E1, 28'hE757CDE}; // theta=-0.245437 rad, KinvΓëê0.970142
        5'd6: {quad, sigma, scale_cmds} = {2'd0, 24'h0EDFDF, 28'hE34FCDE}; // theta=-0.294524 rad, KinvΓëê0.969076
        5'd7: {quad, sigma, scale_cmds} = {2'd0, 24'h0D10E1, 28'hE5D3D5E}; // theta=-0.343612 rad, KinvΓëê0.936215
        5'd8: {quad, sigma, scale_cmds} = {2'd0, 24'h0DEFD0, 28'hA5D7D5E}; // theta=-0.392699 rad, KinvΓëê0.935870
        5'd9: {quad, sigma, scale_cmds} = {2'd0, 24'h0C132C, 28'hAD63DDE}; // theta=-0.441786 rad, KinvΓëê0.894303
        5'd10: {quad, sigma, scale_cmds} = {2'd0, 24'hF23131, 28'hEBEBE5E}; // theta=-0.490874 rad
        5'd11: {quad, sigma, scale_cmds} = {2'd0, 24'hF2002F, 28'hEBEBE5E}; // theta=-0.539961 rad, KinvΓëê0.685994
        5'd12: {quad, sigma, scale_cmds} = {2'd0, 24'hF2DF1D, 28'hEBEBE5E}; // theta=-0.589049 rad, KinvΓëê0.685241
        5'd13: {quad, sigma, scale_cmds} = {2'd0, 24'hF114EF, 28'hB1EBE5E}; // theta=-0.638136 rad, KinvΓëê0.701539
        5'd14: {quad, sigma, scale_cmds} = {2'd0, 24'hF1E3DE, 28'hB1EBE5E}; // theta=-0.687223 rad, KinvΓëê0.701292
        5'd15: {quad, sigma, scale_cmds} = {2'd0, 24'hF03112, 28'hB1EBE5E}; // theta=-0.736311 rad, KinvΓëê0.706330
        5'd16: {quad, sigma, scale_cmds} = {2'd0, 24'hF00000, 28'hB1EBE5E}; // theta=-0.785398 rad, KinvΓëê0.707107
        5'd17: {quad, sigma, scale_cmds} = {2'd3, 24'h10DFFE, 28'hB1EBE5E}; // theta=-0.834486 rad, KinvΓëê0.706330
        5'd18: {quad, sigma, scale_cmds} = {2'd3, 24'h1F2D32, 28'hB1EBE5E}; // theta=-0.883573 rad, KinvΓëê0.701292
        5'd19: {quad, sigma, scale_cmds} = {2'd3, 24'h1FFC21, 28'hB1EBE5E}; // theta=-0.932660 rad, KinvΓëê0.701539
        5'd20: {quad, sigma, scale_cmds} = {2'd3, 24'h1E31F3, 28'hEBEBE5E}; // theta=-0.981748 rad, KinvΓëê0.685241
        5'd21: {quad, sigma, scale_cmds} = {2'd3, 24'h1E00E1, 28'hEBEBE5E}; // theta=-1.030835 rad, KinvΓëê0.685994
        5'd22: {quad, sigma, scale_cmds} = {2'd3, 24'h1EDFDF, 28'hEBEBE5E}; // theta=-1.079922 rad, KinvΓëê0.685240
        5'd23: {quad, sigma, scale_cmds} = {2'd3, 24'h04FDE4, 28'hAD63DDE}; // theta=-1.129010 rad, KinvΓëê0.894303
        5'd24: {quad, sigma, scale_cmds} = {2'd3, 24'h032130, 28'hA5D7D5E}; // theta=-1.178097 rad, KinvΓëê0.935870
        5'd25: {quad, sigma, scale_cmds} = {2'd3, 24'h03F02F, 28'hE5D3D5E}; // theta=-1.227185 rad, KinvΓëê0.936215
        5'd26: {quad, sigma, scale_cmds} = {2'd3, 24'h023131, 28'hE34FCDE}; // theta=-1.276272 rad, KinvΓëê0.969076
        5'd27: {quad, sigma, scale_cmds} = {2'd3, 24'h02002F, 28'hE757CDE}; // theta=-1.325359 rad, KinvΓëê0.970142
        5'd28: {quad, sigma, scale_cmds} = {2'd3, 24'h02DF1D, 28'hE34FCDE}; // theta=-1.374447 rad, KinvΓëê0.969077
        5'd29: {quad, sigma, scale_cmds} = {2'd3, 24'h0114EF, 28'hCFC3BDE}; // theta=-1.423534 rad, KinvΓëê0.992126
        5'd30: {quad, sigma, scale_cmds} = {2'd3, 24'h01E3DE, 28'hA1CFBDE}; // theta=-1.472622 rad, KinvΓëê0.991776
        5'd31: {quad, sigma, scale_cmds} = {2'd3, 24'h003112, 28'hCFC7A5E}; // theta=-1.521709 rad, KinvΓëê0.998901
        default: {quad, sigma, scale_cmds} = 54'h0;
    endcase
end

    cordic_pipeline u_pipeline (
        .clk(clk),
        .rst(rst),
        .x_in(x_in),
        .y_in(y_in),
        .quad(quad),
        .sigma(sigma),
        .scale_cmds(scale_cmds),
        .x_out(x_out),
        .y_out(y_out)
    );

endmodule