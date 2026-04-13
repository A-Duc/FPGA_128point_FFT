module fft_s4_rom_path2(
    input  wire [2:0]  iAddress,
    output reg  [53:0] oData
);

    always @(*) begin
        case (iAddress)
            3'd0: oData = {2'd0, 24'h000000, 28'h000005E}; // theta=-0.000000 rad, Kinv~=1.000000
            3'd1: oData = {2'd0, 24'h0E31F3, 28'hE34FCDE}; // theta=-0.196350 rad, Kinv~=0.969077
            3'd2: oData = {2'd0, 24'h0DEFD0, 28'hA5D7D5E}; // theta=-0.392699 rad, Kinv~=0.935870
            3'd3: oData = {2'd0, 24'hF2DF1D, 28'hEBEBE5E}; // theta=-0.589049 rad, Kinv~=0.685241
            3'd4: oData = {2'd0, 24'hF00000, 28'hB1EBE5E}; // theta=-0.785398 rad, Kinv~=0.707107
            3'd5: oData = {2'd3, 24'h1E31F3, 28'hEBEBE5E}; // theta=-0.981748 rad, Kinv~=0.685241
            3'd6: oData = {2'd3, 24'h032130, 28'hA5D7D5E}; // theta=-1.178097 rad, Kinv~=0.935870
            3'd7: oData = {2'd3, 24'h02DF1D, 28'hE34FCDE}; // theta=-1.374447 rad, Kinv~=0.969077
            default: oData = 54'h0;
        endcase
    end

endmodule
