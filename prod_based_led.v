`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/06 09:43:49
// Design Name: 
// Module Name: prod_based_led
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module prod_based_led(
    input clk, rst,
    input [3:0] prod_count_current,
    output [3:0] cled_r, cled_g, cled_b
    );

    reg led_r, led_g, led_b;

    always @(negedge rst, posedge clk) begin
        if (!rst) begin
            led_r <= 0;
            led_g <= 0;
            led_b <= 0;
        end 
        else begin
            if (prod_count_current < 1) begin
                led_r <= 0;
                led_g <= 0;
                led_b <= 0;
            end
            else if (prod_count_current < 4) begin
                led_r <= 1;
                led_g <= 0;
                led_b <= 0;
            end
            else if (prod_count_current < 7) begin
                led_r <= 0;
                led_g <= 1;
                led_b <= 0;
            end
            else if (prod_count_current < 9) begin
                led_r <= 0;
                led_g <= 0;
                led_b <= 1;
            end
            else begin
                led_r <= 1;
                led_g <= 1;
                led_b <= 1;
            end
        end
    end

    assign cled_r = {led_r, led_r, led_r, led_r};
    assign cled_g = {led_g, led_g, led_g, led_g};
    assign cled_b = {led_b, led_b, led_b, led_b};
endmodule
