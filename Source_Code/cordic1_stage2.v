module cordic1_stage2(
    input  wire clk,
    input  wire [4:0]  n3,
    input  wire [15:0] x_in,
    input  wire [15:0] y_in,
    output reg  [15:0] x_out,
    output reg  [15:0] y_out
);

    // Khai báo đầy đủ 90-bit tín hiệu điều khiển từ ROM
    reg [1:0]  quad;
    reg [23:0] sigma;
    reg [31:0] kinv_pos;
    reg [31:0] kinv_neg;

    // Bảng ROM tĩnh cho Path 1 (p = 1)
    // Verilog ROM Table for Stage 2 - Path 1 (p=1)
always @(*) begin
    case (n3)
            5'd00: {quad, sigma, scale_cmds} = {2'd0, 24'h000000, 28'h000005E}; // Angle: 0.0000 rad
            5'd01: {quad, sigma, scale_cmds} = {2'd0, 24'h003112, 28'hCFC7A5E}; // Angle: 0.0491 rad
            5'd02: {quad, sigma, scale_cmds} = {2'd0, 24'h01E3DE, 28'hA1CFBDE}; // Angle: 0.0982 rad
            5'd03: {quad, sigma, scale_cmds} = {2'd0, 24'h0114EF, 28'hCFC3BDE}; // Angle: 0.1473 rad
            5'd04: {quad, sigma, scale_cmds} = {2'd0, 24'h02DF1D, 28'hE34FCDE}; // Angle: 0.1963 rad
            5'd05: {quad, sigma, scale_cmds} = {2'd0, 24'h02002F, 28'hE757CDE}; // Angle: 0.2454 rad
            5'd06: {quad, sigma, scale_cmds} = {2'd0, 24'h023131, 28'hE34FCDE}; // Angle: 0.2945 rad
            5'd07: {quad, sigma, scale_cmds} = {2'd0, 24'h03F02F, 28'hE5D3D5E}; // Angle: 0.3436 rad
            5'd08: {quad, sigma, scale_cmds} = {2'd0, 24'h032130, 28'hA5D7D5E}; // Angle: 0.3927 rad
            5'd09: {quad, sigma, scale_cmds} = {2'd0, 24'h04FDE4, 28'hAD63DDE}; // Angle: 0.4418 rad
            5'd10: {quad, sigma, scale_cmds} = {2'd0, 24'h1EDFDF, 28'hEBEBE5E}; // Angle: 0.4909 rad
            5'd11: {quad, sigma, scale_cmds} = {2'd0, 24'h1E00E1, 28'hEBEBE5E}; // Angle: 0.5400 rad
            5'd12: {quad, sigma, scale_cmds} = {2'd0, 24'h1E31F3, 28'hEBEBE5E}; // Angle: 0.5890 rad
            5'd13: {quad, sigma, scale_cmds} = {2'd0, 24'h1FFC21, 28'hB1EBE5E}; // Angle: 0.6381 rad
            5'd14: {quad, sigma, scale_cmds} = {2'd0, 24'h1F2D32, 28'hB1EBE5E}; // Angle: 0.6872 rad
            5'd15: {quad, sigma, scale_cmds} = {2'd0, 24'h10DFFE, 28'hB1EBE5E}; // Angle: 0.7363 rad
            5'd16: {quad, sigma, scale_cmds} = {2'd0, 24'h100000, 28'hB1EBE5E}; // Angle: 0.7854 rad
            5'd17: {quad, sigma, scale_cmds} = {2'd0, 24'h103112, 28'hB1EBE5E}; // Angle: 0.8345 rad
            5'd18: {quad, sigma, scale_cmds} = {2'd0, 24'h11E3DE, 28'hB1EBE5E}; // Angle: 0.8836 rad
            5'd19: {quad, sigma, scale_cmds} = {2'd0, 24'h1114EF, 28'hB1EBE5E}; // Angle: 0.9327 rad
            5'd20: {quad, sigma, scale_cmds} = {2'd0, 24'h12DF1D, 28'hEBEBE5E}; // Angle: 0.9817 rad
            5'd21: {quad, sigma, scale_cmds} = {2'd0, 24'h2F31DF, 28'hEB5FD5D}; // Angle: 1.0308 rad
            5'd22: {quad, sigma, scale_cmds} = {2'd0, 24'h20E204, 28'hAB5FD5D}; // Angle: 1.0799 rad
            5'd23: {quad, sigma, scale_cmds} = {2'd0, 24'h20132C, 28'hAB5FD5D}; // Angle: 1.1290 rad
            5'd24: {quad, sigma, scale_cmds} = {2'd0, 24'h21DDD1, 28'hEB5FD5D}; // Angle: 1.1781 rad
            5'd25: {quad, sigma, scale_cmds} = {2'd0, 24'h30FDE4, 28'hE55AD5C}; // Angle: 1.2272 rad
            5'd26: {quad, sigma, scale_cmds} = {2'd0, 24'h302E0C, 28'hE75AD5C}; // Angle: 1.2763 rad
            5'd27: {quad, sigma, scale_cmds} = {2'd0, 24'h4000E1, 28'hE34FBDC}; // Angle: 1.3254 rad
            5'd28: {quad, sigma, scale_cmds} = {2'd0, 24'h4031F3, 28'hDF47BDC}; // Angle: 1.3744 rad
            5'd29: {quad, sigma, scale_cmds} = {2'd0, 24'h41E23F, 28'hA5D7BDC}; // Angle: 1.4235 rad
            5'd30: {quad, sigma, scale_cmds} = {2'd0, 24'h411340, 28'hA7D7BDC}; // Angle: 1.4726 rad
            5'd31: {quad, sigma, scale_cmds} = {2'd0, 24'h42DFFE, 28'hE553C5C}; // Angle: 1.5217 rad
            default: {quad, sigma, scale_cmds} = 54'h0;
    endcase
end



    // =========================================================
    // TODO: Instantiate khối xử lý logic CORDIC vật lý ở đây.
    // Đưa x_in, y_in cùng với {quad, sigma, kinv_pos, kinv_neg} 
    // vào datapath để nó tính ra x_out, y_out.
    // =========================================================

endmodule