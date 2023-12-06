`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/03 18:45:17
// Design Name: 
// Module Name: money_to_fnd_array
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


module money_to_fnd_array(
    input clk, rst,
    input [7:0] display_money_binary,
    output reg [7:0] seg_com, seg_array
    );

    // binary to bcd converter
    reg [4*3-1:0] display_money_bcd;

    parameter binary_w = 8;
    integer i, j;

    always @(negedge rst, posedge clk) begin
        if (!rst) display_money_bcd = 0;
        else begin
            // 영문 위키 백과의 double dabble 알고리즘을 이용해서 변환함
            // 0으로 초기화
            for(i = 0; i <= binary_w+(binary_w-4)/3; i = i+1) display_money_bcd[i] = 0;
            // bcd를 binary input으로 초기화
            display_money_bcd[binary_w-1:0] = display_money_binary;
            // 4bit씩 묶어서 4를 더함
            for(i = 0; i <= binary_w-4; i = i+1) begin
                for(j = 0; j <= i/3; j = j+1) begin
                    // 만약 4비트씩 묶은 값이 4를 초과한다면 3을 더함
                    if (display_money_bcd[binary_w-i+4*j -: 4] > 4)
                    display_money_bcd[binary_w-i+4*j -: 4] = display_money_bcd[binary_w-i+4*j -: 4] + 4'd3;
                end
            end
        end
    end

    parameter d0 = 8'b1111_1100;
    parameter d1 = 8'b0110_0000;
    parameter d2 = 8'b1101_1010;
    parameter d3 = 8'b1111_0010;
    parameter d4 = 8'b0110_0110;
    parameter d5 = 8'b1011_0110;
    parameter d6 = 8'b1011_1110;
    parameter d7 = 8'b1110_0000;
    parameter d8 = 8'b1111_1110;
    parameter d9 = 8'b1111_0110;

    // fnd array에 bcd 표시
    parameter com0 = 8'b1111_1110;
    parameter com1 = 8'b1111_1101;
    parameter com2 = 8'b1111_1011;
    parameter com3 = 8'b1111_0111;

    reg [2:0] fnd_array_cnt;

    always @(negedge rst, posedge clk) begin
        if (!rst) fnd_array_cnt <= 0;
        else begin
            if (fnd_array_cnt == 3) fnd_array_cnt <= 0;
            else fnd_array_cnt <= fnd_array_cnt + 1;
        end
    end

    always @(negedge rst, posedge clk) begin
        if (!rst) begin
            seg_com <= com0;
            seg_array <= d0;
        end
        else begin
            case (fnd_array_cnt)
                0 : begin
                    seg_com <= com0;
                    seg_array <= d0;
                end
                1 : begin
                    seg_com <= com1;
                    seg_array <= d0;
                end
                2 : begin
                    seg_com <= com2;
                    case (display_money_bcd[4*1-1:4*0])
                        4'd0 : seg_array <= d0;
                        4'd1 : seg_array <= d1;
                        4'd2 : seg_array <= d2;
                        4'd3 : seg_array <= d3;
                        4'd4 : seg_array <= d4;
                        4'd5 : seg_array <= d5;
                        4'd6 : seg_array <= d6;
                        4'd7 : seg_array <= d7;
                        4'd8 : seg_array <= d8;
                        4'd9 : seg_array <= d9;
                        default : seg_array <= d0;
                    endcase
                end
                3 : begin
                    seg_com <= com3;
                    case (display_money_bcd[4*2-1:4*1])
                        4'd0 : seg_array <= d0;
                        4'd1 : seg_array <= d1;
                        4'd2 : seg_array <= d2;
                        4'd3 : seg_array <= d3;
                        4'd4 : seg_array <= d4;
                        4'd5 : seg_array <= d5;
                        4'd6 : seg_array <= d6;
                        4'd7 : seg_array <= d7;
                        4'd8 : seg_array <= d8;
                        4'd9 : seg_array <= d9;
                        default : seg_array <= d0;
                    endcase
                end
            endcase
        end
    end
endmodule
