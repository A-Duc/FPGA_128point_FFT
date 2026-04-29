module fft_s2_rom_path2(
    input  wire [4:0]  iAddress,
    output reg  [49:0] oData
);

    always @(*) begin
        case (iAddress)
            5'd0:  oData = {2'd0,24'h000000,24'h000028};
            5'd1:  oData = {2'd0,24'h00DF00,24'h000028};
            5'd2:  oData = {2'd0,24'h0F2D20,24'h000C68};
            5'd3:  oData = {2'd0,24'h0FFC10,24'h000C68};
            5'd4:  oData = {2'd0,24'h0E3100,24'h000CE8};
            5'd5:  oData = {2'd0,24'h0E0000,24'h000CE8};
            5'd6:  oData = {2'd0,24'h0D4100,24'h030D28};
            5'd7:  oData = {2'd0,24'h0D10F0,24'h000D28};
            5'd8:  oData = {2'd0,24'hF32120,24'h863967};
            5'd9:  oData = {2'd0,24'hF3F010,24'h823967};
            5'd10: oData = {2'd0,24'hF2314D,24'h024967};
            5'd11: oData = {2'd0,24'hF20000,24'h024967};
            5'd12: oData = {2'd0,24'hF2DF00,24'hC24967};
            5'd13: oData = {2'd0,24'hF114E0,24'h8A4967};
            5'd14: oData = {2'd0,24'hE34F30,24'hC32D27};
            5'd15: oData = {2'd0,24'hE31E10,24'hC32D27};
            5'd16: oData = {2'd3,24'h2D2300,24'hC32D27};
            5'd17: oData = {2'd3,24'h2DF2F0,24'hC32D27};
            5'd18: oData = {2'd3,24'h2DC1D0,24'hC32D27};
            5'd19: oData = {2'd3,24'h1FFC20,24'h8A4967};
            5'd20: oData = {2'd3,24'h1E3100,24'hC24967};
            5'd21: oData = {2'd3,24'h1E0000,24'h024967};
            5'd22: oData = {2'd3,24'h1EDFC3,24'h024967};
            5'd23: oData = {2'd3,24'h1D10F0,24'h823967};
            5'd24: oData = {2'd3,24'h1DEFE0,24'h863967};
            5'd25: oData = {2'd3,24'h03F010,24'h000D28};
            5'd26: oData = {2'd3,24'h03CF00,24'h030D28};
            5'd27: oData = {2'd3,24'h020000,24'h000CE8};
            5'd28: oData = {2'd3,24'h02DF00,24'h000CE8};
            5'd29: oData = {2'd3,24'h01140F,24'h000C68};
            5'd30: oData = {2'd3,24'h01E3E0,24'h000C68};
            5'd31: oData = {2'd3,24'h003100,24'h000028};
            default: oData = 50'h0;
        endcase
    end

endmodule