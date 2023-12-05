`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/03 20:17:23
// Design Name: 
// Module Name: item_based_piezo
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


module item_based_piezo(
    input clk, rst,
    input [2:0] note_state,
    input [31:0] note_cnt,
    output reg piezo
    );
    // generate문용 변수
    genvar i;
    // 실제 값은 각각 100000, 200000, 300000, 400000
    // parameter note_1_limit = 5;
    // parameter note_2_limit = 10;
    // parameter note_3_limit = 15;
    // parameter note_4_limit = 20;
    parameter note_1_limit = 100000;
    parameter note_2_limit = 200000;
    parameter note_3_limit = 300000;
    parameter note_4_limit = 400000;

    // piezo용 계이름 주파수
    reg [11:0] piezo_limit;
    parameter xx = 12'd0;
    parameter do = 12'd3830;
    parameter re = 12'd3400;
    parameter mi = 12'd3038;
    parameter fa = 12'd2864;
    parameter so = 12'd2550;
    parameter la = 12'd2272;
    parameter ti = 12'd2028;
    parameter high_do = 12'd1912;

    parameter note_100w = 1;
    parameter note_500w = 2;
    parameter note_1000w = 3;
    parameter note_prod1 = 4;
    parameter note_prod2 = 5;
    parameter note_prod3 = 6;

    parameter [12*4-1:0] note_100w_lut = { do, mi, so, so };
    parameter [12*4-1:0] note_500w_lut = { re, fa, la, la };
    parameter [12*4-1:0] note_1000w_lut = { mi, so, ti, ti };
    parameter [12*4-1:0] note_prod1_lut = { do, xx, do, xx };
    parameter [12*4-1:0] note_prod2_lut = { so, xx, so, xx };
    parameter [12*4-1:0] note_prod3_lut = { ti, xx, ti, xx };

    // 노트를 설정하는 always문
    always @(negedge rst, posedge clk) begin
        if (!rst) begin
            piezo_limit = xx;
        end
        else begin
            // 노트 카운터를 1씩 증가하고 특정 값이 넘으면 노트 연주 상태를 비활성화 하고 카운터를 초기화
            if (note_cnt < note_1_limit) begin
                case (note_state)
                    note_100w : piezo_limit = note_100w_lut[12*4-1:12*3];
                    note_500w : piezo_limit = note_500w_lut[12*4-1:12*3];
                    note_1000w : piezo_limit = note_1000w_lut[12*4-1:12*3];
                    note_prod1 : piezo_limit = note_prod1_lut[12*4-1:12*3];
                    note_prod2 : piezo_limit = note_prod2_lut[12*4-1:12*3];
                    note_prod3 : piezo_limit = note_prod3_lut[12*4-1:12*3];
                    default : piezo_limit = xx;
                endcase
            end
            else if (note_cnt < note_2_limit) begin
                case (note_state)
                    note_100w : piezo_limit = note_100w_lut[12*3-1:12*2];
                    note_500w : piezo_limit = note_500w_lut[12*3-1:12*2];
                    note_1000w : piezo_limit = note_1000w_lut[12*3-1:12*2];
                    note_prod1 : piezo_limit = note_prod1_lut[12*3-1:12*2];
                    note_prod2 : piezo_limit = note_prod2_lut[12*3-1:12*2];
                    note_prod3 : piezo_limit = note_prod3_lut[12*3-1:12*2];
                    default : piezo_limit = xx;
                endcase
            end
            else if (note_cnt < note_3_limit) begin
                case (note_state)
                    note_100w : piezo_limit = note_100w_lut[12*2-1:12*1];
                    note_500w : piezo_limit = note_500w_lut[12*2-1:12*1];
                    note_1000w : piezo_limit = note_1000w_lut[12*2-1:12*1];
                    note_prod1 : piezo_limit = note_prod1_lut[12*2-1:12*1];
                    note_prod2 : piezo_limit = note_prod2_lut[12*2-1:12*1];
                    note_prod3 : piezo_limit = note_prod3_lut[12*2-1:12*1];
                    default : piezo_limit = xx;
                endcase
            end
            else if (note_cnt < note_4_limit) begin
                case (note_state)
                    note_100w : piezo_limit = note_100w_lut[12*1-1:12*0];
                    note_500w : piezo_limit = note_500w_lut[12*1-1:12*0];
                    note_1000w : piezo_limit = note_1000w_lut[12*1-1:12*0];
                    note_prod1 : piezo_limit = note_prod1_lut[12*1-1:12*0];
                    note_prod2 : piezo_limit = note_prod2_lut[12*1-1:12*0];
                    note_prod3 : piezo_limit = note_prod3_lut[12*1-1:12*0];
                    default : piezo_limit = xx;
                endcase
            end
            else begin
                piezo_limit = xx;
            end
        end
    end

    // piezo용 카운터
    integer piezo_cnt;
    always @(negedge rst, posedge clk) begin
        if (!rst) begin
            piezo <= 0;
            piezo_cnt <= 0;
        end 
        else if (piezo_cnt >= piezo_limit/2) begin
            piezo <= ~piezo;
            piezo_cnt <= 0;
        end
        else piezo_cnt <= piezo_cnt + 1;
    end
endmodule
