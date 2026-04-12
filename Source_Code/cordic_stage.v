`timescale 1ns / 1ps

module cordic_stage #(
    parameter Width = 20,   
    parameter SHIFT = 0
)(
    input  wire signed [Width-1:0] x_in,
    input  wire signed [Width-1:0] y_in,
    input  wire signed [4:0]       sig_n,  
    output wire signed [Width-1:0] x_out,
    output wire signed [Width-1:0] y_out
);

    wire signed [Width-1:0] x_shifted = x_in >>> SHIFT;
    wire signed [Width-1:0] y_shifted = y_in >>> SHIFT;

    reg signed [Width-1:0] term_x; 
    reg signed [Width-1:0] term_y; 

    always @(*) begin
        case (sig_n)
            5'b01000: begin // +8
                term_x = y_shifted <<< 3;
                term_y = x_shifted <<< 3;
            end
            5'b00111: begin // +7
                term_x = (y_shifted <<< 3) - y_shifted;
                term_y = (x_shifted <<< 3) - x_shifted;
            end
            5'b00110: begin // +6
                term_x = (y_shifted <<< 2) + (y_shifted <<< 1);
                term_y = (x_shifted <<< 2) + (x_shifted <<< 1);
            end
            5'b00101: begin // +5
                term_x = (y_shifted <<< 2) + y_shifted;
                term_y = (x_shifted <<< 2) + x_shifted;
            end
            5'b00100: begin // +4
                term_x = y_shifted <<< 2;
                term_y = x_shifted <<< 2;
            end
            5'b00011: begin // +3
                term_x = (y_shifted <<< 1) + y_shifted;
                term_y = (x_shifted <<< 1) + x_shifted;
            end
            5'b00010: begin // +2
                term_x = y_shifted <<< 1;
                term_y = x_shifted <<< 1;
            end
            5'b00001: begin // +1
                term_x = y_shifted;
                term_y = x_shifted;
            end
            5'b00000: begin // 0
                term_x = 0;
                term_y = 0;
            end
            5'b11111: begin // -1
                term_x = -y_shifted;
                term_y = -x_shifted;
            end
            5'b11110: begin // -2
                term_x = -(y_shifted <<< 1);
                term_y = -(x_shifted <<< 1);
            end
            5'b11101: begin // -3
                term_x = -((y_shifted <<< 1) + y_shifted);
                term_y = -((x_shifted <<< 1) + x_shifted);
            end
            5'b11100: begin // -4
                term_x = -(y_shifted <<< 2);
                term_y = -(x_shifted <<< 2);
            end
            5'b11011: begin // -5
                term_x = -((y_shifted <<< 2) + y_shifted);
                term_y = -((x_shifted <<< 2) + x_shifted);
            end
            5'b11010: begin // -6
                term_x = -((y_shifted <<< 2) + (y_shifted <<< 1));
                term_y = -((x_shifted <<< 2) + (x_shifted <<< 1));
            end
            5'b11001: begin // -7
                term_x = -((y_shifted <<< 3) - y_shifted);
                term_y = -((x_shifted <<< 3) - x_shifted);
            end
            5'b11000: begin // -8
                term_x = -(y_shifted <<< 3);
                term_y = -(x_shifted <<< 3);
            end
            default: begin
                term_x = 0;
                term_y = 0;
            end
        endcase
    end

    assign x_out = x_in - term_x;
    assign y_out = y_in + term_y;

endmodule
