module commutator #(
    parameter BIT_WIDTH   = 16,
    parameter DELAY_DEPTH = 1
)(
    input  wire Clk,
    input  wire Reset,

    input  wire upper_mux0_sel,
    input  wire upper_mux1_sel,
    input  wire lower_mux0_sel,
    input  wire lower_mux1_sel,

    input  wire signed [BIT_WIDTH-1:0] iData0_r,
    input  wire signed [BIT_WIDTH-1:0] iData0_i,
    input  wire signed [BIT_WIDTH-1:0] iData1_r,
    input  wire signed [BIT_WIDTH-1:0] iData1_i,
    input  wire signed [BIT_WIDTH-1:0] iData2_r,
    input  wire signed [BIT_WIDTH-1:0] iData2_i,
    input  wire signed [BIT_WIDTH-1:0] iData3_r,
    input  wire signed [BIT_WIDTH-1:0] iData3_i,

    output wire signed [BIT_WIDTH-1:0] oData0_r,
    output wire signed [BIT_WIDTH-1:0] oData0_i,
    output wire signed [BIT_WIDTH-1:0] oData1_r,
    output wire signed [BIT_WIDTH-1:0] oData1_i,
    output wire signed [BIT_WIDTH-1:0] oData2_r,
    output wire signed [BIT_WIDTH-1:0] oData2_i,
    output wire signed [BIT_WIDTH-1:0] oData3_r,
    output wire signed [BIT_WIDTH-1:0] oData3_i
);


    wire signed [BIT_WIDTH-1:0] in_delay_path0_r;
    wire signed [BIT_WIDTH-1:0] in_delay_path0_i;

    wire signed [BIT_WIDTH-1:0] out_delay_path2a_r;
    wire signed [BIT_WIDTH-1:0] out_delay_path2a_i;

    wire signed [BIT_WIDTH-1:0] in_delay_path2b_r;
    wire signed [BIT_WIDTH-1:0] in_delay_path2b_i;

    wire signed [BIT_WIDTH-1:0] out_delay_path3_r;
    wire signed [BIT_WIDTH-1:0] out_delay_path3_i;


    delay_line #(
        .DELAY_DEPTH(DELAY_DEPTH),
        .BIT_WIDTH(BIT_WIDTH)
    ) delay_path0 (
        .Clk    (Clk),
        .Reset  (Reset),
        .iData_r(in_delay_path0_r),
        .iData_i(in_delay_path0_i),
        .oData_r(oData0_r),
        .oData_i(oData0_i)
    );

    delay_line #(
        .DELAY_DEPTH(DELAY_DEPTH),
        .BIT_WIDTH(BIT_WIDTH)
    ) delay_path2a (
        .Clk    (Clk),
        .Reset  (Reset),
        .iData_r(iData2_r),
        .iData_i(iData2_i),
        .oData_r(out_delay_path2a_r),
        .oData_i(out_delay_path2a_i)
    );

    delay_line #(
        .DELAY_DEPTH(DELAY_DEPTH),
        .BIT_WIDTH(BIT_WIDTH)
    ) delay_path2b (
        .Clk    (Clk),
        .Reset  (Reset),
        .iData_r(in_delay_path2b_r),
        .iData_i(in_delay_path2b_i),
        .oData_r(oData2_r),
        .oData_i(oData2_i)
    );

    delay_line #(
        .DELAY_DEPTH(DELAY_DEPTH),
        .BIT_WIDTH(BIT_WIDTH)
    ) delay_path3 (
        .Clk    (Clk),
        .Reset  (Reset),
        .iData_r(iData3_r),
        .iData_i(iData3_i),
        .oData_r(out_delay_path3_r),
        .oData_i(out_delay_path3_i)
    );


    assign {in_delay_path0_r, in_delay_path0_i} =
           (upper_mux0_sel) ? {out_delay_path2a_r, out_delay_path2a_i}
                            : {iData0_r,          iData0_i};

    assign {oData1_r, oData1_i} =
           (upper_mux1_sel) ? {iData0_r,          iData0_i}
                            : {out_delay_path2a_r, out_delay_path2a_i};



    assign {in_delay_path2b_r, in_delay_path2b_i} =
           (lower_mux0_sel) ? {out_delay_path3_r, out_delay_path3_i}
                            : {iData1_r,          iData1_i};

    assign {oData3_r, oData3_i} =
           (lower_mux1_sel) ? {out_delay_path3_r, out_delay_path3_i}
                            : {iData1_r,          iData1_i};

endmodule