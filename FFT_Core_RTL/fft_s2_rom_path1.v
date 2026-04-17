module fft_s2_rom_path1(
    input  wire [4:0]  iAddress,
    output reg  [49:0] oData
);

    always @(*) begin
        case (iAddress)
            5'd0:  oData = {2'd0, 24'h000000, 24'h000028};
            5'd1:  oData = {2'd0, 24'h0F2E00, 24'h000028};
            5'd2:  oData = {2'd0, 24'h0E3000, 24'h020CE8};
            5'd3:  oData = {2'd0, 24'h0ED000, 24'h000CE8};
            5'd4:  oData = {2'd0, 24'h0DE001, 24'h030D28};
            5'd5:  oData = {2'd0, 24'hF23001, 24'h024967};
            5'd6:  oData = {2'd0, 24'hF2DF00, 24'h024967};
            5'd7:  oData = {2'd0, 24'hE34DF0, 24'hC32D27};
            5'd8:  oData = {2'd3, 24'h100000, 24'hC739A7};
            5'd9:  oData = {2'd3, 24'h2DC004, 24'hC32D27};
            5'd10: oData = {2'd3, 24'h1E3001, 24'h024967};
            5'd11: oData = {2'd3, 24'h1EDF00, 24'h024967};
            5'd12: oData = {2'd3, 24'h032F00, 24'h030D28};
            5'd13: oData = {2'd3, 24'h023000, 24'h000CE8};
            5'd14: oData = {2'd3, 24'h02D000, 24'h020CE8};
            5'd15: oData = {2'd3, 24'h01E002, 24'h000028};
            5'd16: oData = {2'd3, 24'h000000, 24'h000028};
            5'd17: oData = {2'd3, 24'h0F2E00, 24'h000028};
            5'd18: oData = {2'd3, 24'h0E3000, 24'h020CE8};
            5'd19: oData = {2'd3, 24'h0ED000, 24'h000CE8};
            5'd20: oData = {2'd3, 24'h0DE001, 24'h030D28};
            5'd21: oData = {2'd3, 24'hF23001, 24'h024967};
            5'd22: oData = {2'd3, 24'hF2DF00, 24'h024967};
            5'd23: oData = {2'd3, 24'hE34DF0, 24'hC32D27};
            5'd24: oData = {2'd2, 24'h100000, 24'hC739A7};
            5'd25: oData = {2'd2, 24'h2DC004, 24'hC32D27};
            5'd26: oData = {2'd2, 24'h1E3001, 24'h024967};
            5'd27: oData = {2'd2, 24'h1EDF00, 24'h024967};
            5'd28: oData = {2'd2, 24'h032F00, 24'h030D28};
            5'd29: oData = {2'd2, 24'h023000, 24'h000CE8};
            5'd30: oData = {2'd2, 24'h02D000, 24'h020CE8};
            5'd31: oData = {2'd2, 24'h01E002, 24'h000028};
            default: oData = 50'h0;
        endcase
    end

endmodule