`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/25 12:41:14
// Design Name: 
// Module Name: gen_clk_100hz
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


module gen_clk_100hz(
    input clk, rst,
    output reg clk_100hz
    );
    // 1Mhz clk�� 100hz�� �����
    // �ѹ��� 100hz�� ����⿡�� cnt�� ���� bit�� �ʹ� �������� 1khz�� ����� 100hz�� ����

    // 1khz clk
    // �����δ� 5000�� �����
    // parameter clk_1khz_limit = 2;
    // parameter clk_1khz_limit = 5000;
    parameter clk_1khz_limit = 1000;
    integer cnt_1khz;

    // 100hz clk
    // �����δ� 500�� �����
    parameter clk_100hz_limit = 2;
    integer cnt_100hz;

    reg clk_1khz;

    always @(negedge rst, posedge clk) begin
        if (!rst) begin
            cnt_1khz <= 0;
            clk_1khz = 0;
        end 
        else if (cnt_1khz < clk_1khz_limit) begin
            cnt_1khz <= cnt_1khz + 1;
        end 
        else begin
            cnt_1khz <= 0;
            clk_1khz <= ~clk_1khz;
        end
    end

    always @(negedge rst, posedge clk_1khz) begin
        if (!rst) begin
            cnt_100hz <= 0;
            clk_100hz <= 0;
        end 
        else if (cnt_100hz < clk_100hz_limit) begin
            cnt_100hz <= cnt_100hz + 1;
        end 
        else begin
            cnt_100hz <= 0;
            clk_100hz <= ~clk_100hz;
        end
    end
endmodule
