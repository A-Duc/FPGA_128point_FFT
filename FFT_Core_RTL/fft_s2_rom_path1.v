module fft_s2_rom_path1(
    input  wire [4:0]  iAddress,
    output reg  [49:0] oData
);

    always @(*) begin
        case (iAddress)
            5'd0: oData = {2'd0, 24'h000000, 24'h000028};
            5'd1: oData = {2'd0, 24'h0F2D32, 24'h000C68};
            5'd2: oData = {2'd0, 24'h0E31F3, 24'h000CE8};
            5'd3: oData = {2'd0, 24'h0EDFDF, 24'h000CE8};
            5'd4: oData = {2'd0, 24'h0DEFD0, 24'h000D28};
            5'd5: oData = {2'd0, 24'hF23131, 24'hC34DA8};
            5'd6: oData = {2'd0, 24'hF2DF1D, 24'hC34DA8};
            5'd7: oData = {2'd0, 24'hF1E3DE, 24'h8B4DA8};
            5'd8: oData = {2'd3, 24'h100000, 24'h8B4DA8};
            5'd9: oData = {2'd3, 24'h1F2D32, 24'h8B4DA8};
            5'd10: oData = {2'd3, 24'h1E31F3, 24'hC34DA8};
            5'd11: oData = {2'd3, 24'h1EDFDF, 24'hC34DA8};
            5'd12: oData = {2'd3, 24'h032130, 24'h000D28};
            5'd13: oData = {2'd3, 24'h023131, 24'h000CE8};
            5'd14: oData = {2'd3, 24'h02DF1D, 24'h000CE8};
            5'd15: oData = {2'd3, 24'h01E3DE, 24'h000C68};
            5'd16: oData = {2'd3, 24'h000000, 24'h000028};
            5'd17: oData = {2'd3, 24'h0F2D32, 24'h000C68};
            5'd18: oData = {2'd3, 24'h0E31F3, 24'h000CE8};
            5'd19: oData = {2'd3, 24'h0EDFDF, 24'h000CE8};
            5'd20: oData = {2'd3, 24'h0DEFD0, 24'h000D28};
            5'd21: oData = {2'd3, 24'hF23131, 24'hC34DA8};
            5'd22: oData = {2'd3, 24'hF2DF1D, 24'hC34DA8};
            5'd23: oData = {2'd3, 24'hF1E3DE, 24'h8B4DA8};
            5'd24: oData = {2'd2, 24'h100000, 24'h8B4DA8};
            5'd25: oData = {2'd2, 24'h1F2D32, 24'h8B4DA8};
            5'd26: oData = {2'd2, 24'h1E31F3, 24'hC34DA8};
            5'd27: oData = {2'd2, 24'h1EDFDF, 24'hC34DA8};
            5'd28: oData = {2'd2, 24'h032130, 24'h000D28};
            5'd29: oData = {2'd2, 24'h023131, 24'h000CE8};
            5'd30: oData = {2'd2, 24'h02DF1D, 24'h000CE8};
            5'd31: oData = {2'd2, 24'h01E3DE, 24'h000C68};
            default: oData = 50'h0;
        endcase
    end

endmodule