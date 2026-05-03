module fft_s6_rom_path3(
    input  wire        iAddress,
    output reg  [29:0] oData
);

    always @(*) begin
        case (iAddress)
            1'd0: oData = {2'd0, 24'h000000, 4'd0};
            1'd1: oData = {2'd2, 24'h100000, 4'd11};
            default: oData = 30'h0;
        endcase
    end

endmodule