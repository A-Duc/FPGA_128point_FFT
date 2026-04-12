module fft_s6_rom_path3(
    input  wire        iAddress,
    output reg  [53:0] oData
);

    always @(*) begin
        case (iAddress)
            1'd0: oData = {2'd0, 24'h000000, 28'h000005E}; // theta=-0.000000 rad, Kinv~=1.000000
            1'd1: oData = {2'd3, 24'hF00000, 28'hB1EBE5E}; // theta=-2.356194 rad, Kinv~=0.707107
            default: oData = 54'h0;
        endcase
    end

endmodule
