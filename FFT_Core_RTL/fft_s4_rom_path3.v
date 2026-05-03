module fft_s4_rom_path3(
    input  wire [2:0]  iAddress,
    output reg  [29:0] oData
);

    always @(*) begin
        case (iAddress)
            3'd0: oData = {2'd0, 24'h000000, 4'd0};
            3'd1: oData = {2'd0, 24'hF2DF00, 4'd6};
            3'd2: oData = {2'd3, 24'h032F00, 4'd7};
            3'd3: oData = {2'd3, 24'h0E3000, 4'd4};
            3'd4: oData = {2'd2, 24'h100000, 4'd11};
            3'd5: oData = {2'd2, 24'h02D000, 4'd4};
            3'd6: oData = {2'd2, 24'h0DE001, 4'd7};
            3'd7: oData = {2'd1, 24'h1E3001, 4'd6};
            default: oData = 30'h0;
        endcase
    end

endmodule