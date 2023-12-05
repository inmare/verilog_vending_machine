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

    integer i;

    // binary to bcd converter
    reg [4*3-1:0] display_money_bcd;
    // // write double dabble algorithm using input as display_money_binary and output as display_money_bcd
    // reg [19:0] shift_reg; // Shift register

    // // Conversion process
    // always @(rst, display_money_binary) begin
    //     if (!rst) shift_reg = 0;
    //     else begin
    //         shift_reg = {12'd0, display_money_binary}; // Initialize shift register with binary input

    //         // Perform the Double Dabble algorithm
    //         for (i = 0; i < 7; i = i + 1) begin
    //             // Check for any 5 in the nibbles and add 3 if condition is met
    //             if (shift_reg[11:8] >= 5)
    //                 shift_reg[11:8] = shift_reg[11:8] + 3;
    //             if (shift_reg[15:12] >= 5)
    //                 shift_reg[15:12] = shift_reg[15:12] + 3;
    //             if (shift_reg[19:16] >= 5)
    //                 shift_reg[19:16] = shift_reg[19:16] + 3;

    //             shift_reg = shift_reg << 1; // Left shift by 1
    //         end

    //         display_money_bcd = shift_reg[19:8]; // Assign the upper 12 bits to the BCD output
    //     end
    // end

    parameter binary_w = 8;
    integer j;

    always @(negedge rst, posedge clk) begin
        if (!rst) display_money_bcd = 0;
        else begin
            // ���� ��Ű ����� double dabble �˰����� �̿��ؼ� ��ȯ��
            // 0���� �ʱ�ȭ
            for(i = 0; i <= binary_w+(binary_w-4)/3; i = i+1) display_money_bcd[i] = 0;
            // bcd�� binary input���� �ʱ�ȭ
            display_money_bcd[binary_w-1:0] = display_money_binary;
            // 4bit�� ��� 4�� ����
            for(i = 0; i <= binary_w-4; i = i+1) begin
                for(j = 0; j <= i/3; j = j+1) begin
                    // ���� 4��Ʈ�� ���� ���� 4�� �ʰ��Ѵٸ� 3�� ����
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

    // fnd array�� bcd ǥ��
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
