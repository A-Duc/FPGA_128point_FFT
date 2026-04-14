module dual_port_ram#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input  wire                    Clk,

    input  wire                    A_en,
    input  wire                    A_we,
    input  wire [ADDR_WIDTH-1:0]   A_addr,
    input  wire [DATA_WIDTH-1:0]   A_wdata,
    output reg  [DATA_WIDTH-1:0]   A_rdata,

    input  wire                    B_en,
    input  wire                    B_we,
    input  wire [ADDR_WIDTH-1:0]   B_addr,
    input  wire [DATA_WIDTH-1:0]   B_wdata,
    output reg  [DATA_WIDTH-1:0]   B_rdata
);

    // (* ramstyle = "M10K" *) reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    // (* ramstyle = "MLAB" *) reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge Clk) begin

        if (A_en) begin
            if (A_we) begin
                mem[A_addr] <= A_wdata;
            end
            A_rdata <= mem[A_addr];
        end

        if (B_en) begin
            if (B_we) begin
                mem[B_addr] <= B_wdata;
            end
            B_rdata <= mem[B_addr];
        end
    end

endmodule