module micro_rotation_stage #(
    parameter Width = 20,   
    parameter SHIFT = 0      // Số bit cần dịch phải 
)(
    input  wire signed [Width-1:0] x_in,
    input  wire signed [Width-1:0] y_in,
    input  wire signed [3:0]       sig_n,  
    output wire signed [Width-1:0] x_out,
    output wire signed [Width-1:0] y_out
);

    wire signed [Width-1:0] x_shifted = x_in >>> SHIFT;
    wire signed [Width-1:0] y_shifted = y_in >>> SHIFT;

    reg signed [Width-1:0] term_x; 
    reg signed [Width-1:0] term_y; 

    always @(*) begin
        case (sig_n)
            4'b0100: begin // sig_n = +4
                term_x = y_shifted <<< 2;
                term_y = x_shifted <<< 2;
            end
            4'b0011: begin // sig_n = +3
                term_x = (y_shifted <<< 1) + y_shifted;
                term_y = (x_shifted <<< 1) + x_shifted;
            end
            4'b0010: begin // sig_n = +2
                term_x = y_shifted <<< 1;
                term_y = x_shifted <<< 1;
            end
            4'b0001: begin // sig_n = +1
                term_x = y_shifted;
                term_y = x_shifted;
            end
            
            // TRƯỜNG HỢP SIGMA BẰNG 0
            4'b0000: begin // sig_n = 0
                term_x = 0;
                term_y = 0;
            end
            
            4'b1111: begin // sig_n = -1 //F
                term_x = -y_shifted;
                term_y = -x_shifted;
            end
            4'b1110: begin // sig_n = -2 //E
                term_x = -(y_shifted <<< 1);
                term_y = -(x_shifted <<< 1);
            end
            4'b1101: begin // sig_n = -3 //D
                term_x = -((y_shifted <<< 1) + y_shifted);
                term_y = -((x_shifted <<< 1) + x_shifted);
            end
            4'b1100: begin // sig_n = -4 //C
                term_x = -(y_shifted <<< 2);
                term_y = -(x_shifted <<< 2);
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