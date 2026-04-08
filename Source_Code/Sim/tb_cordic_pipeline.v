`timescale 1ns / 1ps

module tb_cor_st2_p1;

    localparam TCLK = 10; 

    reg clk;
    reg [4:0] n3;
    reg signed [15:0] x_in;
    reg signed [15:0] y_in;

    wire [15:0] x_out;
    wire [15:0] y_out;

    cor_st2_p1 dut (
        .n3(n3),
        .clk(clk),
        .x_in(x_in),
        .y_in(y_in),
        .x_out(x_out),
        .y_out(y_out)
    );

    initial clk = 1'b0;
    always #(TCLK / 2) clk = ~clk;

    // Task in kết quả theo định dạng cột
    task display_result;
        begin
            $display("INPUT: n3=%2d, x=%6d, y=%6d  =>  OUTPUT: x=%6d, y=%6d", 
                     n3, $signed(x_in), $signed(y_in), $signed(x_out), $signed(y_out));
        end
    endtask

    task wait_pipeline;
        begin
            repeat (20) @(posedge clk);
        end
    endtask

    initial begin
        $display("----------------------------------------------------------------------");
        $display("   MO PHONG CORDIC PIPELINE - CHE DO QUAY VECTOR (Y_IN != 0)");
        $display("----------------------------------------------------------------------");
        
        n3 = 5'd0; x_in = 16'sd0; y_in = 16'sd0;
        @(posedge clk);

        // Test case 1: n3 = 0 (Góc 0 độ)
        n3 = 5'd0; x_in = 16'sh4000; y_in = 16'sh2000; // y_in = 8192
        wait_pipeline();
        display_result();

        // Test case 2: n3 = 10 (Góc ~28.1 độ)
        n3 = 5'd10; x_in = 16'sh4000; y_in = 16'sh2000; // y_in = 8192
        wait_pipeline();
        display_result();

        // Test case 3: n3 = 31 (Góc ~87.2 độ)
        n3 = 5'd31; x_in = 16'sh4000; y_in = 16'sh2000; // y_in = 8192
        wait_pipeline();
        display_result();

        // Bonus: Chạy một vòng lặp nhỏ từ 0 đến 5 để xem sự thay đổi liên tục
        $display("--- Quet nhanh n3 tu 0 den 5 ---");
        for (integer i = 0; i <= 5; i = i + 1) begin
            n3 = i; x_in = 16'sh4000; y_in = 16'sh2000; // y_in = 8192
            wait_pipeline();
            display_result();
        end

        $display("----------------------------------------------------------------------");
        $finish;
    end

endmodule