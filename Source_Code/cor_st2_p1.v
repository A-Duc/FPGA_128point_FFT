module cor_st2_p1(
    input wire [4:0] n3,         
    input wire clk,
    input wire rst,
    input wire signed [15:0] x_in,
    input wire signed [15:0] y_in,
    output wire [15:0] x_out,    
    output wire [15:0] y_out    
);

    reg  [49:0] data_o;
    wire [1:0]  quad;
    wire [23:0] sigma;
    wire [23:0] scale_cmds;

    assign quad       = data_o[49:48];
    assign sigma      = data_o[47:24];
    assign scale_cmds = data_o[23:0];

   always @(*) begin
    case (n3)
       5'd0: data_o = {2'd0, 24'h000000, 24'h000028}; // th=-0.00000 Ki=1.0000 rc=1.0000 ke=0.0E+00(0.00L) ae=0.0E+00
        5'd1: data_o = {2'd0, 24'h00DFFE, 24'h000028}; // th=-0.04909 Ki=0.9989 rc=1.0000 ke=1.1E-03(0.28L) ae=1.2E-05
        5'd2: data_o = {2'd0, 24'h0F2D32, 24'h000C68}; // th=-0.09817 Ki=0.9918 rc=0.9922 ke=4.1E-04(0.11L) ae=6.2E-06
        5'd3: data_o = {2'd0, 24'h0FFC21, 24'h000C68}; // th=-0.14726 Ki=0.9921 rc=0.9922 ke=6.1E-05(0.02L) ae=1.0E-05
        5'd4: data_o = {2'd0, 24'h0E31F3, 24'h000CE8}; // th=-0.19635 Ki=0.9691 rc=0.9688 ke=3.3E-04(0.08L) ae=1.2E-05
        5'd5: data_o = {2'd0, 24'h0E00E1, 24'h000CE8}; // th=-0.24544 Ki=0.9701 rc=0.9688 ke=1.4E-03(0.36L) ae=5.0E-07
        5'd6: data_o = {2'd0, 24'h0EDFDF, 24'h000CE8}; // th=-0.29452 Ki=0.9691 rc=0.9688 ke=3.3E-04(0.08L) ae=1.1E-05
        5'd7: data_o = {2'd0, 24'h0D10E1, 24'h000D28}; // th=-0.34361 Ki=0.9362 rc=0.9375 ke=1.3E-03(0.33L) ae=7.0E-06
        5'd8: data_o = {2'd0, 24'h0DEFD0, 24'h000D28}; // th=-0.39270 Ki=0.9359 rc=0.9375 ke=1.6E-03(0.42L) ae=3.0E-06
        5'd9: data_o = {2'd0, 24'h0C132C, 24'h822D68}; // th=-0.44179 Ki=0.8943 rc=0.8945 ke=2.3E-04(0.06L) ae=1.2E-05
        5'd10: data_o = {2'd0, 24'hF23131, 24'hC34DA8}; // th=-0.49087 Ki=0.6852 rc=0.6836 ke=1.6E-03(0.42L) ae=1.1E-05
        5'd11: data_o = {2'd0, 24'hF2002F, 24'h034DA8}; // th=-0.53996 Ki=0.6860 rc=0.6875 ke=1.5E-03(0.39L) ae=5.0E-07
        5'd12: data_o = {2'd0, 24'hF2DF1D, 24'hC34DA8}; // th=-0.58905 Ki=0.6852 rc=0.6836 ke=1.6E-03(0.42L) ae=1.2E-05
        5'd13: data_o = {2'd0, 24'hF114EF, 24'h8B4DA8}; // th=-0.63814 Ki=0.7015 rc=0.7031 ke=1.6E-03(0.41L) ae=1.0E-05
        5'd14: data_o = {2'd0, 24'hF1E3DE, 24'h8B4DA8}; // th=-0.68722 Ki=0.7013 rc=0.7031 ke=1.8E-03(0.47L) ae=6.2E-06
        5'd15: data_o = {2'd0, 24'hF03112, 24'h8B4DA8}; // th=-0.73631 Ki=0.7063 rc=0.7031 ke=3.2E-03(0.82L) ae=1.2E-05
        5'd16: data_o = {2'd3, 24'h100000, 24'h8B4DA8}; // th=-0.78540 Ki=0.7071 rc=0.7031 ke=4.0E-03(1.02L) ae=0.0E+00
        5'd17: data_o = {2'd3, 24'h10DFFE, 24'h8B4DA8}; // th=-0.83449 Ki=0.7063 rc=0.7031 ke=3.2E-03(0.82L) ae=1.2E-05
        5'd18: data_o = {2'd3, 24'h1F2D32, 24'h8B4DA8}; // th=-0.88357 Ki=0.7013 rc=0.7031 ke=1.8E-03(0.47L) ae=6.2E-06
        5'd19: data_o = {2'd3, 24'h1FFC21, 24'h8B4DA8}; // th=-0.93266 Ki=0.7015 rc=0.7031 ke=1.6E-03(0.41L) ae=1.0E-05
        5'd20: data_o = {2'd3, 24'h1E31F3, 24'hC34DA8}; // th=-0.98175 Ki=0.6852 rc=0.6836 ke=1.6E-03(0.42L) ae=1.2E-05
        5'd21: data_o = {2'd3, 24'h1E00E1, 24'h034DA8}; // th=-1.03084 Ki=0.6860 rc=0.6875 ke=1.5E-03(0.39L) ae=5.0E-07
        5'd22: data_o = {2'd3, 24'h1EDFDF, 24'hC34DA8}; // th=-1.07992 Ki=0.6852 rc=0.6836 ke=1.6E-03(0.42L) ae=1.1E-05
        5'd23: data_o = {2'd3, 24'h04FDE4, 24'h822D68}; // th=-1.12901 Ki=0.8943 rc=0.8945 ke=2.3E-04(0.06L) ae=1.2E-05
        5'd24: data_o = {2'd3, 24'h032130, 24'h000D28}; // th=-1.17810 Ki=0.9359 rc=0.9375 ke=1.6E-03(0.42L) ae=3.0E-06
        5'd25: data_o = {2'd3, 24'h03F02F, 24'h000D28}; // th=-1.22718 Ki=0.9362 rc=0.9375 ke=1.3E-03(0.33L) ae=7.0E-06
        5'd26: data_o = {2'd3, 24'h023131, 24'h000CE8}; // th=-1.27627 Ki=0.9691 rc=0.9688 ke=3.3E-04(0.08L) ae=1.1E-05
        5'd27: data_o = {2'd3, 24'h02002F, 24'h000CE8}; // th=-1.32536 Ki=0.9701 rc=0.9688 ke=1.4E-03(0.36L) ae=5.0E-07
        5'd28: data_o = {2'd3, 24'h02DF1D, 24'h000CE8}; // th=-1.37445 Ki=0.9691 rc=0.9688 ke=3.3E-04(0.08L) ae=1.2E-05
        5'd29: data_o = {2'd3, 24'h0114EF, 24'h000C68}; // th=-1.42353 Ki=0.9921 rc=0.9922 ke=6.1E-05(0.02L) ae=1.0E-05
        5'd30: data_o = {2'd3, 24'h01E3DE, 24'h000C68}; // th=-1.47262 Ki=0.9918 rc=0.9922 ke=4.1E-04(0.11L) ae=6.2E-06
        5'd31: data_o = {2'd3, 24'h003112, 24'h000028}; // th=-1.52171 Ki=0.9989 rc=1.0000 ke=1.1E-03(0.28L) ae=1.2E-05
        default: data_o = 50'h0;
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
