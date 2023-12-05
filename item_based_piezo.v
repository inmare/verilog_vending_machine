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
    input [2:0] selected_item,
    input [2:0] money_btn,
    output reg piezo
    );
    // generate문용 변수
    genvar i;
    // 시간이 얼마나 지났는지 카운트해서 연주하는 음이 달라지게 함
    integer note_cnt;
    // 실제 값은 각각 100000, 200000, 400000
    // parameter note_1_limit = 5;
    // parameter note_2_limit = 10;
    // parameter note_3_limit = 20;
    parameter note_1_limit = 100000;
    parameter note_2_limit = 200000;
    parameter note_3_limit = 300000;
    parameter note_4_limit = 400000;

    // 선택한 아이템에 대해서 oneshot을 만듦
    wire [2:0] selected_item_oneshot;
    generate
        for (i = 0; i < 3; i = i + 1) begin
            one_shot_en_sw item_oneshot(
                .clk(clk),
                .enable(selected_item[i]),
                .eout(selected_item_oneshot[i])
            );
        end
    endgenerate

    // 선택한 금액에 대해서 oneshot을 만듦
    wire [2:0] money_btn_oneshot;
    generate
        for (i = 0; i < 3; i = i + 1) begin
            one_shot_en_sw money_oneshot(
                .clk(clk),
                .enable(money_btn[i]),
                .eout(money_btn_oneshot[i])
            );
        end
    endgenerate

    // piezo용 계이름 주파수
    reg [11:0] piezo_limit;
    parameter do = 12'd3830;
    parameter re = 12'd3400;
    parameter mi = 12'd3038;
    parameter fa = 12'd2864;
    parameter so = 12'd2550;
    parameter la = 12'd2272;
    parameter ti = 12'd2028;
    parameter high_do = 12'd1912;

    parameter note_select = 3'd1;
    parameter note_100 = 3'd2;
    parameter note_500 = 3'd3;
    parameter note_1000 = 3'd4;

    integer note_play;

    // 노트를 설정하는 always문
    always @(negedge rst, posedge clk) begin
        if (!rst) begin
            note_cnt = 0;
            piezo_limit = 0;
            note_play = 0;
        end
        else begin
            // 선택한 아이템의 oneshot이 바뀌면 노트를 연주 상태로 바꿈
            if (selected_item_oneshot != 0) note_play = note_select;
            if (money_btn_oneshot != 0) begin
                case (money_btn_oneshot)
                    3'b100 : note_play = note_100;
                    3'b010 : note_play = note_500;
                    3'b001 : note_play = note_1000;
                    default : note_play = 0;
                endcase
            end

            // 노트 카운터를 1씩 증가하고 특정 값이 넘으면 노트 연주 상태를 비활성화 하고 카운터를 초기화
            if (note_play == note_select) begin
                if (note_cnt < note_1_limit) begin
                    case (selected_item)
                        3'd1 : piezo_limit = do;
                        3'd2 : piezo_limit = so;
                        3'd3 : piezo_limit = ti;
                        default : piezo_limit = 0;
                    endcase
                    note_cnt = note_cnt + 1;
                end
                else if (note_cnt < note_2_limit && note_cnt >= note_1_limit) begin
                    piezo_limit = 0;
                    note_cnt <= note_cnt + 1;
                end
                else if (note_cnt < note_3_limit && note_cnt >= note_2_limit) begin
                    case (selected_item)
                        3'd1 : piezo_limit = do;
                        3'd2 : piezo_limit = so;
                        3'd3 : piezo_limit = ti;
                        default : piezo_limit = 0;
                    endcase
                    note_cnt = note_cnt + 1;
                end
                else if (note_cnt < note_4_limit && note_cnt >= note_3_limit) begin
                    piezo_limit = 0;
                    note_cnt = note_cnt + 1;
                end
                else begin
                    note_cnt = 0;
                    piezo_limit = 0;
                    note_play = 0;
                end
            end
            else if (note_play >= 2) begin
                if (note_cnt < note_1_limit) begin
                    case (note_play)
                        2 : piezo_limit = do;
                        3 : piezo_limit = re;
                        4 : piezo_limit = mi;
                        default : piezo_limit = 0;
                    endcase
                    note_cnt = note_cnt + 1;
                end
                else if (note_cnt < note_2_limit && note_cnt >= note_1_limit) begin
                    case (note_play)
                        2 : piezo_limit = mi;
                        3 : piezo_limit = fa;
                        4 : piezo_limit = so;
                        default : piezo_limit = 0;
                    endcase
                    note_cnt <= note_cnt + 1;
                end
                else if (note_cnt < note_3_limit && note_cnt >= note_2_limit) begin
                    case (note_play)
                        2 : piezo_limit = so;
                        3 : piezo_limit = la;
                        4 : piezo_limit = ti;
                        default : piezo_limit = 0;
                    endcase
                    note_cnt = note_cnt + 1;
                end
                else if (note_cnt < note_4_limit && note_cnt >= note_3_limit) begin
                    case (note_play)
                        2 : piezo_limit = so;
                        3 : piezo_limit = la;
                        4 : piezo_limit = ti;
                        default : piezo_limit = 0;
                    endcase
                    note_cnt = note_cnt + 1;
                end
                else begin
                    note_cnt = 0;
                    piezo_limit = 0;
                    note_play = 0;
                end
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
