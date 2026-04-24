module fft128_avalon_mm_wrapper(
    input  wire        Clk,
    input  wire        Reset_n,

    input  wire [8:0]  Address,
    input  wire [31:0] WriteData,
    input  wire        ChipSelect_n,
    input  wire        Write_n,
    input  wire        Read_n,

    output reg  [31:0] ReadData
);  
    reg  [3:0] ctrl_reg; 
    reg  [3:0] stat_reg;
    localparam REG_CTRL_ADDR = 2'b00;
    localparam REG_STAT_ADDR = 2'b01;
    
    reg  [2:0] state_r;
    reg  [2:0] next_state_w;
    localparam IDLE      = 3'd0;
    localparam FEEDING   = 3'd1;
    localparam WAITING   = 3'd2;
    localparam CAPTURING = 3'd3;
    localparam COMPLETE  = 3'd4;

    wire master_rd_req;
    wire master_wr_req;  

    wire i_buffer_access;
    wire o_buffer_access;
    wire cfg_regs_access;

    wire start_evt;
    wire soft_reset_evt;
    wire feed_last_evt;
    wire first_out_evt;
    wire capture_done_evt;
    wire out_gap_err_evt;
    wire clear_evt;

    wire ctrl_wr_allow;
    wire ctrl_wr_hit;

    assign master_rd_req = ~Read_n  & ~ChipSelect_n;
    assign master_wr_req = ~Write_n & ~ChipSelect_n;  

    assign i_buffer_access = (Address[8:7] == 2'b00);
    assign o_buffer_access = (Address[8:7] == 2'b01);
    assign cfg_regs_access = (Address[8:7] == 2'b10);

    assign start_evt        = ctrl_reg[0];
    assign soft_reset_evt   = ctrl_reg[1];
    assign clear_evt        = ctrl_reg[2];
    assign feed_last_evt    = 1'b0;
    assign first_out_evt    = 1'b0;
    assign capture_done_evt = 1'b0;
    assign out_gap_err_evt  = 1'b0;

    assign ctrl_wr_allow = (state_r == IDLE) || (state_r == COMPLETE);
    assign ctrl_wr_hit   = master_wr_req && cfg_regs_access && (Address[1:0] == REG_CTRL_ADDR);

    always @(posedge Clk or negedge Reset_n) begin
        if (!Reset_n) begin
            ctrl_reg <= 4'd0;
        end else begin
            ctrl_reg[2:0] <= 3'b000;
            if (ctrl_wr_hit && ctrl_wr_allow) begin
                ctrl_reg[2:0] <= WriteData[2:0];
                ctrl_reg[3]   <= WriteData[3];
            end
        end
    end

    always @(*) begin
        next_state_w = state_r;
        case (state_r)
            IDLE: begin
                if (soft_reset_evt)
                    next_state_w = IDLE;
                else if (start_evt)
                    next_state_w = FEEDING;
            end

            FEEDING: begin
                if (soft_reset_evt)
                    next_state_w = IDLE;
                else if (feed_last_evt)
                    next_state_w = WAITING;
            end

            WAITING: begin
                if (soft_reset_evt)
                    next_state_w = IDLE;
                else if (first_out_evt)
                    next_state_w = CAPTURING;
            end

            CAPTURING: begin
                if (soft_reset_evt)
                    next_state_w = IDLE;
                else if (out_gap_err_evt)
                    next_state_w = COMPLETE;
                else if (capture_done_evt)
                    next_state_w = COMPLETE;
            end

            COMPLETE: begin
                if (soft_reset_evt)
                    next_state_w = IDLE;
                else if (clear_evt)
                    next_state_w = IDLE;
            end

            default: begin
                next_state_w = IDLE;
            end
        endcase
    end

    always @(posedge Clk or negedge Reset_n) begin
        if (!Reset_n)
            state_r <= IDLE;
        else
            state_r <= next_state_w;
    end

endmodule