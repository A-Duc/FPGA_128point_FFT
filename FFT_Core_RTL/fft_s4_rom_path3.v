module fft_s4_rom_path3(
    input  wire [2:0]  iAddress,
    output reg  [49:0] oData
);

    always @(*) begin
        case (iAddress)
            3'd0: oData = {2'd0, 24'h000000, 24'h000028};
            3'd1: oData = {2'd0, 24'hF2DF1D, 24'hC34DA8};
            3'd2: oData = {2'd3, 24'h032130, 24'h000D28};
            3'd3: oData = {2'd3, 24'h0E31F3, 24'h000CE8};
            3'd4: oData = {2'd2, 24'h100000, 24'h8B4DA8};
            3'd5: oData = {2'd2, 24'h02DF1D, 24'h000CE8};
            3'd6: oData = {2'd2, 24'h0DEFD0, 24'h000D28};
            3'd7: oData = {2'd1, 24'h1E31F3, 24'hC34DA8};
            default: oData = 50'h0;
        endcase
    end

endmodule
