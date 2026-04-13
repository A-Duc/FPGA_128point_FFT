module fft_s4_rom_path1(
    input  wire [2:0]  iAddress,
    output reg  [53:0] oData
);

    always @(*) begin
        case (iAddress)
            3'd0: oData = {2'd0, 24'h000000, 28'h000005E}; // theta=-0.000000 rad, Kinv~=1.000000
            3'd1: oData = {2'd0, 24'h0DEFD0, 28'hA5D7D5E}; // theta=-0.392699 rad, Kinv~=0.935870
            3'd2: oData = {2'd0, 24'hF00000, 28'hB1EBE5E}; // theta=-0.785398 rad, Kinv~=0.707107
            3'd3: oData = {2'd3, 24'h032130, 28'hA5D7D5E}; // theta=-1.178097 rad, Kinv~=0.935870
            3'd4: oData = {2'd3, 24'h000000, 28'h000005E}; // theta=-1.570796 rad, Kinv~=1.000000
            3'd5: oData = {2'd3, 24'h0DEFD0, 28'hA5D7D5E}; // theta=-1.963495 rad, Kinv~=0.935870
            3'd6: oData = {2'd3, 24'hF00000, 28'hB1EBE5E}; // theta=-2.356194 rad, Kinv~=0.707107
            3'd7: oData = {2'd2, 24'h032130, 28'hA5D7D5E}; // theta=-2.748894 rad, Kinv~=0.935870
            default: oData = 54'h0;
        endcase
    end

endmodule