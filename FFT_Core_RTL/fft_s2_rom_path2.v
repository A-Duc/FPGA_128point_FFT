module fft_s2_rom_path2(
    input  wire [4:0]  iAddress,
    output reg  [29:0] oData
);

    always @(*) begin
        case (iAddress)
            5'd0:  oData = {2'd0, 24'h000000, 4'd0};
            5'd1:  oData = {2'd0, 24'h00D000, 4'd0};
            5'd2:  oData = {2'd0, 24'h0F2E00, 4'd0};
            5'd3:  oData = {2'd0, 24'h0FF000, 4'd2};
            5'd4:  oData = {2'd0, 24'h0E3000, 4'd4};
            5'd5:  oData = {2'd0, 24'h0E0000, 4'd3};
            5'd6:  oData = {2'd0, 24'h0ED000, 4'd3};
            5'd7:  oData = {2'd0, 24'h0D1F00, 4'd5};
            5'd8:  oData = {2'd0, 24'h0DE001, 4'd7};
            5'd9:  oData = {2'd0, 24'hF3F001, 4'd8};
            5'd10: oData = {2'd0, 24'hF23001, 4'd6};
            5'd11: oData = {2'd0, 24'hF20000, 4'd6};
            5'd12: oData = {2'd0, 24'hF2DF00, 4'd6};
            5'd13: oData = {2'd0, 24'hE404FE, 4'd9};
            5'd14: oData = {2'd0, 24'hE34DF0, 4'd10};
            5'd15: oData = {2'd0, 24'hD43100, 4'd1};
            5'd16: oData = {2'd3, 24'h100000, 4'd11};
            5'd17: oData = {2'd3, 24'h3CDF00, 4'd1};
            5'd18: oData = {2'd3, 24'h2DC004, 4'd10};
            5'd19: oData = {2'd3, 24'h2C0C12, 4'd9};
            5'd20: oData = {2'd3, 24'h1E3001, 4'd6};
            5'd21: oData = {2'd3, 24'h1E0000, 4'd6};
            5'd22: oData = {2'd3, 24'h1EDF00, 4'd6};
            5'd23: oData = {2'd3, 24'h1D1F00, 4'd8};
            5'd24: oData = {2'd3, 24'h032F00, 4'd7};
            5'd25: oData = {2'd3, 24'h03F001, 4'd5};
            5'd26: oData = {2'd3, 24'h023000, 4'd3};
            5'd27: oData = {2'd3, 24'h020000, 4'd3};
            5'd28: oData = {2'd3, 24'h02D000, 4'd4};
            5'd29: oData = {2'd3, 24'h011000, 4'd2};
            5'd30: oData = {2'd3, 24'h01E002, 4'd0};
            5'd31: oData = {2'd3, 24'h003000, 4'd0};
            default: oData = 30'h0;
        endcase
    end

endmodule