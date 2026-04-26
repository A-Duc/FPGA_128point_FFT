module fft128_avalon_mm_wrapper(
    input  wire        Clk,
    input  wire        Reset_n,

    input  wire [8:0]  Address,
    input  wire [31:0] WriteData,
    input  wire        ChipSelect_n,
    input  wire        Write_n,
    input  wire        Read_n,

    output wire        WaitRequest_n,
    output reg  [31:0] ReadData
);  
    // Registers
    reg  [3:0] ctrl_reg; 
    reg  [3:0] stat_reg;
    reg  [2:0] state_r;
    reg  [4:0] feed_slot_r;
    reg        feed_valid_r;
    reg  [4:0] capture_cnt_r;
    reg        ram_rd_data_ready_r;

    // Config address
    localparam REG_CTRL_ADDR = 2'b00;
    localparam REG_STAT_ADDR = 2'b01;

    // State of FSM
    localparam IDLE      = 3'd0;
    localparam FEEDING   = 3'd1;
    localparam WAITING   = 3'd2;
    localparam CAPTURING = 3'd3;
    localparam COMPLETE  = 3'd4;

    // Bus control signals
    wire master_rd_req;
    wire master_wr_req;
    wire ram_rd_req;

    // Address decode signals
    wire i_buffer_access;
    wire o_buffer_access;
    wire cfg_regs_access;
    wire ctrl_access;
    wire stat_access;

    // FSM event signals
    wire start_evt;
    wire clear_evt;
    wire feed_last_evt;
    wire first_out_evt;
    wire capture_done_evt;
    wire capturing_w;

    // Control signals
    wire write_allow;
    wire ctrl_wr_en;
    wire irq_en;

    // Input buffer signals
    wire i_buffer0_A_en;
    wire i_buffer1_A_en;
    wire i_buffer2_A_en;
    wire i_buffer3_A_en;

    wire i_buffer0_B_en;
    wire i_buffer1_B_en;
    wire i_buffer2_B_en;
    wire i_buffer3_B_en;

    wire i_buffer0_A_we;
    wire i_buffer1_A_we;
    wire i_buffer2_A_we;
    wire i_buffer3_A_we;

    wire [31:0] i_buffer0_A_rdata;
    wire [31:0] i_buffer1_A_rdata;
    wire [31:0] i_buffer2_A_rdata;
    wire [31:0] i_buffer3_A_rdata;

    wire [31:0] i_buffer0_B_rdata;
    wire [31:0] i_buffer1_B_rdata;
    wire [31:0] i_buffer2_B_rdata;
    wire [31:0] i_buffer3_B_rdata;

    wire [4:0] i_buffer0_B_addr;
    wire [4:0] i_buffer1_B_addr;
    wire [4:0] i_buffer2_B_addr;
    wire [4:0] i_buffer3_B_addr;

    // FFT core output signals
    wire signed [15:0] fft_out0_r;
    wire signed [15:0] fft_out0_i;
    wire signed [15:0] fft_out1_r;
    wire signed [15:0] fft_out1_i;
    wire signed [15:0] fft_out2_r;
    wire signed [15:0] fft_out2_i;
    wire signed [15:0] fft_out3_r;
    wire signed [15:0] fft_out3_i;
    wire [4:0]         fft_out_slot;
    wire               fft_out_valid;

    // Output buffer signals
    wire o_buffer0_A_en;
    wire o_buffer1_A_en;
    wire o_buffer2_A_en;
    wire o_buffer3_A_en;

    wire o_buffer0_B_en;
    wire o_buffer1_B_en;
    wire o_buffer2_B_en;
    wire o_buffer3_B_en;

    wire o_buffer0_B_we;
    wire o_buffer1_B_we;
    wire o_buffer2_B_we;
    wire o_buffer3_B_we;

    wire [4:0] o_buffer_A_addr;
    wire [4:0] o_buffer_B_addr;

    wire [31:0] o_buffer0_A_rdata;
    wire [31:0] o_buffer1_A_rdata;
    wire [31:0] o_buffer2_A_rdata;
    wire [31:0] o_buffer3_A_rdata;

    wire [31:0] o_buffer0_B_rdata;
    wire [31:0] o_buffer1_B_rdata;
    wire [31:0] o_buffer2_B_rdata;
    wire [31:0] o_buffer3_B_rdata;

    wire [31:0] o_buffer0_B_wdata;
    wire [31:0] o_buffer1_B_wdata;
    wire [31:0] o_buffer2_B_wdata;
    wire [31:0] o_buffer3_B_wdata;

    assign master_rd_req = ~Read_n  & ~ChipSelect_n;
    assign master_wr_req = ~Write_n & ~ChipSelect_n;  

    assign i_buffer_access = (Address[8:7] == 2'b00);
    assign o_buffer_access = (Address[8:7] == 2'b01);
    assign cfg_regs_access = (Address[8:7] == 2'b10);

    assign ram_rd_req = master_rd_req & (i_buffer_access | o_buffer_access);

    assign WaitRequest_n = ~(ram_rd_req & ~ram_rd_data_ready_r);

    assign start_evt        = ctrl_reg[0];
    assign clear_evt        = ctrl_reg[1];
    assign irq_en           = ctrl_reg[2];
    assign feed_last_evt    = feed_valid_r & (feed_slot_r == 5'd31);
    assign first_out_evt    = fft_out_valid & (state_r == WAITING);
    assign capturing_w      = ((state_r == WAITING) | (state_r == CAPTURING)) & fft_out_valid;
    assign capture_done_evt = (state_r == CAPTURING) & fft_out_valid & (capture_cnt_r == 5'd31);

    assign write_allow = (state_r == IDLE) | (state_r == COMPLETE);

    assign ctrl_access = (Address[1:0] == REG_CTRL_ADDR);
    assign stat_access = (Address[1:0] == REG_STAT_ADDR);
    assign ctrl_wr_en  = write_allow & master_wr_req & cfg_regs_access & ctrl_access;

    always @(posedge Clk or negedge Reset_n) begin
        if (!Reset_n) begin
            ctrl_reg <= 4'd0;
        end else begin
            ctrl_reg[1:0] <= 2'b00;
            if (ctrl_wr_en) begin
                ctrl_reg[3:0] <= WriteData[3:0];
            end
        end
    end

    always @(posedge Clk or negedge Reset_n) begin
        if (!Reset_n) begin
            state_r       <= IDLE;
            feed_slot_r   <= 5'd0;
            feed_valid_r  <= 1'b0;
            capture_cnt_r <= 5'd0;
            stat_reg      <= 4'd0;
        end else begin
            case (state_r)
                IDLE: begin
                    stat_reg <= 4'b0000;

                    if (start_evt) begin
                        state_r       <= FEEDING;
                        feed_slot_r   <= 5'd0;
                        feed_valid_r  <= 1'b0;
                        capture_cnt_r <= 5'd0;
                        stat_reg      <= 4'b0001;
                    end
                end

                FEEDING: begin
                    stat_reg <= 4'b0001;

                    if (!feed_valid_r) begin
                        feed_slot_r  <= 5'd0;
                        feed_valid_r <= 1'b1;
                    end else if (!feed_last_evt) begin
                        feed_slot_r  <= feed_slot_r + 5'd1;
                        feed_valid_r <= 1'b1;
                    end else begin
                        state_r      <= WAITING;
                        feed_slot_r  <= 5'd0;
                        feed_valid_r <= 1'b0;
                    end
                end

                WAITING: begin
                    stat_reg <= 4'b0001;

                    if (first_out_evt) begin
                        state_r       <= CAPTURING;
                        capture_cnt_r <= 5'd1;
                    end
                end

                CAPTURING: begin
                    stat_reg <= 4'b0001;

                    if (capture_done_evt) begin
                        state_r  <= COMPLETE;
                        stat_reg <= 4'b0010;
                    end else if (fft_out_valid) begin
                        capture_cnt_r <= capture_cnt_r + 5'd1;
                    end
                end

                COMPLETE: begin
                    stat_reg <= 4'b0010;

                    if (clear_evt) begin
                        state_r       <= IDLE;
                        feed_slot_r   <= 5'd0;
                        feed_valid_r  <= 1'b0;
                        capture_cnt_r <= 5'd0;
                        stat_reg      <= 4'b0000;
                    end
                end

                default: begin
                    state_r       <= IDLE;
                    feed_slot_r   <= 5'd0;
                    feed_valid_r  <= 1'b0;
                    capture_cnt_r <= 5'd0;
                    stat_reg      <= 4'b0000;
                end
            endcase
        end
    end

    always @(posedge Clk or negedge Reset_n) begin
        if (!Reset_n) begin
            ram_rd_data_ready_r <= 1'b0;
        end else begin
            if (ram_rd_req & ~ram_rd_data_ready_r) begin
                ram_rd_data_ready_r <= 1'b1;
            end else begin
                ram_rd_data_ready_r <= 1'b0;
            end
        end
    end

    always @(*) begin
        ReadData = 32'd0;

        if (~ChipSelect_n & ~Read_n) begin
            if (cfg_regs_access) begin
                case (Address[1:0])
                    REG_CTRL_ADDR: ReadData = {28'd0, ctrl_reg};
                    REG_STAT_ADDR: ReadData = {28'd0, stat_reg};
                    default:       ReadData = 32'd0;
                endcase
            end else if (o_buffer_access) begin
                case (Address[6:5])
                    2'b00:   ReadData = o_buffer0_A_rdata;
                    2'b01:   ReadData = o_buffer1_A_rdata;
                    2'b10:   ReadData = o_buffer2_A_rdata;
                    2'b11:   ReadData = o_buffer3_A_rdata;
                    default: ReadData = 32'd0;
                endcase
            end else if (i_buffer_access) begin
                case (Address[6:5])
                    2'b00:   ReadData = i_buffer0_A_rdata;
                    2'b01:   ReadData = i_buffer1_A_rdata;
                    2'b10:   ReadData = i_buffer2_A_rdata;
                    2'b11:   ReadData = i_buffer3_A_rdata;
                    default: ReadData = 32'd0;
                endcase
            end else begin
                ReadData = 32'd0;
            end
        end
    end

    // Input buffer control
    assign i_buffer0_A_en = ~ChipSelect_n & i_buffer_access & (Address[6:5] == 2'b00);
    assign i_buffer1_A_en = ~ChipSelect_n & i_buffer_access & (Address[6:5] == 2'b01);
    assign i_buffer2_A_en = ~ChipSelect_n & i_buffer_access & (Address[6:5] == 2'b10);
    assign i_buffer3_A_en = ~ChipSelect_n & i_buffer_access & (Address[6:5] == 2'b11);

    assign i_buffer0_A_we = ~Write_n & write_allow;
    assign i_buffer1_A_we = ~Write_n & write_allow;
    assign i_buffer2_A_we = ~Write_n & write_allow;
    assign i_buffer3_A_we = ~Write_n & write_allow;

    assign i_buffer0_B_en = (state_r == FEEDING);
    assign i_buffer1_B_en = (state_r == FEEDING);
    assign i_buffer2_B_en = (state_r == FEEDING);
    assign i_buffer3_B_en = (state_r == FEEDING);

    assign i_buffer0_B_addr = feed_valid_r ? (feed_slot_r + 5'd1) : feed_slot_r;
    assign i_buffer1_B_addr = feed_valid_r ? (feed_slot_r + 5'd1) : feed_slot_r;
    assign i_buffer2_B_addr = feed_valid_r ? (feed_slot_r + 5'd1) : feed_slot_r;
    assign i_buffer3_B_addr = feed_valid_r ? (feed_slot_r + 5'd1) : feed_slot_r;

    // Output buffer control
    assign o_buffer0_A_en = ~ChipSelect_n & o_buffer_access & (Address[6:5] == 2'b00);
    assign o_buffer1_A_en = ~ChipSelect_n & o_buffer_access & (Address[6:5] == 2'b01);
    assign o_buffer2_A_en = ~ChipSelect_n & o_buffer_access & (Address[6:5] == 2'b10);
    assign o_buffer3_A_en = ~ChipSelect_n & o_buffer_access & (Address[6:5] == 2'b11);

    assign o_buffer_A_addr = Address[4:0];

    assign o_buffer0_B_en = capturing_w;
    assign o_buffer1_B_en = capturing_w;
    assign o_buffer2_B_en = capturing_w;
    assign o_buffer3_B_en = capturing_w;

    assign o_buffer0_B_we = capturing_w;
    assign o_buffer1_B_we = capturing_w;
    assign o_buffer2_B_we = capturing_w;
    assign o_buffer3_B_we = capturing_w;

    assign o_buffer_B_addr = {fft_out_slot[0], fft_out_slot[1], fft_out_slot[2], fft_out_slot[3], fft_out_slot[4]};

    assign o_buffer0_B_wdata = {fft_out0_r, fft_out0_i};
    assign o_buffer1_B_wdata = {fft_out2_r, fft_out2_i};
    assign o_buffer2_B_wdata = {fft_out1_r, fft_out1_i};
    assign o_buffer3_B_wdata = {fft_out3_r, fft_out3_i};

    // Input buffer
    dual_port_ram i_buffer0(    
        .Clk(Clk),

        .A_en(i_buffer0_A_en),
        .A_we(i_buffer0_A_we),
        .A_addr(Address[4:0]),
        .A_wdata(WriteData),
        .A_rdata(i_buffer0_A_rdata),

        .B_en(i_buffer0_B_en),
        .B_we(1'b0),
        .B_addr(i_buffer0_B_addr),
        .B_wdata(32'd0),
        .B_rdata(i_buffer0_B_rdata)
    );

    dual_port_ram i_buffer1(    
        .Clk(Clk),

        .A_en(i_buffer1_A_en),
        .A_we(i_buffer1_A_we),
        .A_addr(Address[4:0]),
        .A_wdata(WriteData),
        .A_rdata(i_buffer1_A_rdata),

        .B_en(i_buffer1_B_en),
        .B_we(1'b0),
        .B_addr(i_buffer1_B_addr),
        .B_wdata(32'd0),
        .B_rdata(i_buffer1_B_rdata)
    );

    dual_port_ram i_buffer2(    
        .Clk(Clk),

        .A_en(i_buffer2_A_en),
        .A_we(i_buffer2_A_we),
        .A_addr(Address[4:0]),
        .A_wdata(WriteData),
        .A_rdata(i_buffer2_A_rdata),

        .B_en(i_buffer2_B_en),
        .B_we(1'b0),
        .B_addr(i_buffer2_B_addr),
        .B_wdata(32'd0),
        .B_rdata(i_buffer2_B_rdata)
    );

    dual_port_ram i_buffer3(    
        .Clk(Clk),

        .A_en(i_buffer3_A_en),
        .A_we(i_buffer3_A_we),
        .A_addr(Address[4:0]),
        .A_wdata(WriteData),
        .A_rdata(i_buffer3_A_rdata),

        .B_en(i_buffer3_B_en),
        .B_we(1'b0),
        .B_addr(i_buffer3_B_addr),
        .B_wdata(32'd0),
        .B_rdata(i_buffer3_B_rdata)
    );

    // Main pipeline
    fft128_4parallel_feedforward fft_core(
        .Clk(Clk),
        .Reset(~Reset_n),
        .Pipeline_en(feed_valid_r),
        .iData_slot(feed_slot_r),

        .iData0_r(i_buffer0_B_rdata[31:16]),
        .iData0_i(i_buffer0_B_rdata[15:0]),
        .iData1_r(i_buffer1_B_rdata[31:16]),
        .iData1_i(i_buffer1_B_rdata[15:0]),
        .iData2_r(i_buffer2_B_rdata[31:16]),
        .iData2_i(i_buffer2_B_rdata[15:0]),
        .iData3_r(i_buffer3_B_rdata[31:16]),
        .iData3_i(i_buffer3_B_rdata[15:0]),

        .oData0_r(fft_out0_r),
        .oData0_i(fft_out0_i),
        .oData1_r(fft_out1_r),
        .oData1_i(fft_out1_i),
        .oData2_r(fft_out2_r),
        .oData2_i(fft_out2_i),
        .oData3_r(fft_out3_r),
        .oData3_i(fft_out3_i),

        .oData_slot(fft_out_slot),
        .oData_valid(fft_out_valid)
    );

    // Output buffer
    dual_port_ram o_buffer0(    
        .Clk(Clk),

        .A_en(o_buffer0_A_en),
        .A_we(1'b0),
        .A_addr(o_buffer_A_addr),
        .A_wdata(32'd0),
        .A_rdata(o_buffer0_A_rdata),

        .B_en(o_buffer0_B_en),
        .B_we(o_buffer0_B_we),
        .B_addr(o_buffer_B_addr),
        .B_wdata(o_buffer0_B_wdata),
        .B_rdata(o_buffer0_B_rdata)
    );

    dual_port_ram o_buffer1(    
        .Clk(Clk),

        .A_en(o_buffer1_A_en),
        .A_we(1'b0),
        .A_addr(o_buffer_A_addr),
        .A_wdata(32'd0),
        .A_rdata(o_buffer1_A_rdata),

        .B_en(o_buffer1_B_en),
        .B_we(o_buffer1_B_we),
        .B_addr(o_buffer_B_addr),
        .B_wdata(o_buffer1_B_wdata),
        .B_rdata(o_buffer1_B_rdata)
    );

    dual_port_ram o_buffer2(    
        .Clk(Clk),

        .A_en(o_buffer2_A_en),
        .A_we(1'b0),
        .A_addr(o_buffer_A_addr),
        .A_wdata(32'd0),
        .A_rdata(o_buffer2_A_rdata),

        .B_en(o_buffer2_B_en),
        .B_we(o_buffer2_B_we),
        .B_addr(o_buffer_B_addr),
        .B_wdata(o_buffer2_B_wdata),
        .B_rdata(o_buffer2_B_rdata)
    );

    dual_port_ram o_buffer3(    
        .Clk(Clk),

        .A_en(o_buffer3_A_en),
        .A_we(1'b0),
        .A_addr(o_buffer_A_addr),
        .A_wdata(32'd0),
        .A_rdata(o_buffer3_A_rdata),

        .B_en(o_buffer3_B_en),
        .B_we(o_buffer3_B_we),
        .B_addr(o_buffer_B_addr),
        .B_wdata(o_buffer3_B_wdata),
        .B_rdata(o_buffer3_B_rdata)
    );

endmodule