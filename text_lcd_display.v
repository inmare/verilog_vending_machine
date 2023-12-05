`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/25 15:42:04
// Design Name: 
// Module Name: vending_machine_text_lcd
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


module text_lcd_display(
    input clk, rst,
    input [11:0] button_sw,
    input admin_mode,
    input [8*16-1:0] line1_text, line2_text,
    input [6:0] ddram_address,
    output lcd_e, 
    output reg lcd_rs, lcd_rw,
    output reg [7:0] lcd_data
    );
    genvar i;

    wire clk_100hz;
    gen_clk_100hz clk_gen(
        .clk(clk), .rst(rst),
        .clk_100hz(clk_100hz)
    );

    wire [11:0] button_oneshot_sw;
    generate
        for (i = 0; i < 12; i = i + 1) begin
            one_shot_en_sw button_oneshot(
                .clk(clk_100hz),
                .enable(button_sw[i]),
                .eout(button_oneshot_sw[i])
            );
        end
    endgenerate

    // text lcd의 상태를 저장하는 변수
    reg [3:0] text_lcd_state;
    parameter delay           = 0;
    parameter function_set    = 1;
    parameter entry_mode      = 2;
    parameter disp_onoff      = 3;
    parameter line1           = 4;
    parameter line2           = 5;
    parameter delay_t         = 6;
    parameter clear_disp      = 7;

    // 각 text lcd state용 cnt
    parameter delay_cnt         = 70;
    parameter function_set_cnt  = 30;
    parameter entry_mode_cnt    = 30;
    parameter disp_onoff_cnt    = 30;
    parameter line1_cnt         = 20;
    parameter line2_cnt         = 20;
    parameter delay_t_cnt       = 400;
    parameter clear_disp_cnt    = 200;

    integer text_lcd_cnt;

    // text_lcd_state 전환 always문
    always @(negedge rst, posedge clk_100hz) begin
        // rst = 0이면 text_lcd_state = delay = 0으로 초기화
        if (!rst) text_lcd_state <= delay;
        else begin
            case (text_lcd_state)
                delay :         if (text_lcd_cnt == delay_cnt)           text_lcd_state <= function_set;
                function_set :  if (text_lcd_cnt == function_set_cnt)    text_lcd_state <= disp_onoff;
                disp_onoff :    if (text_lcd_cnt == disp_onoff_cnt)      text_lcd_state <= entry_mode;
                entry_mode :    if (text_lcd_cnt == entry_mode_cnt)      text_lcd_state <= line1;
                line1 :         if (text_lcd_cnt == line1_cnt)           text_lcd_state <= line2;
                line2 :         if (text_lcd_cnt == line2_cnt)           text_lcd_state <= delay_t;
                delay_t : begin
                    if (text_lcd_cnt == delay_t_cnt) text_lcd_state <= delay_t;
                    else if (button_oneshot_sw != 0) text_lcd_state <= line1;
                end
                // clear disp는 따로 작성하지 않음
                default : text_lcd_state <= delay;
            endcase
        end
    end

    // text_lcd_cnt 전환 always문
    always @(negedge rst, posedge clk_100hz) begin
        if (!rst) text_lcd_cnt <= 0;
        else begin
            case (text_lcd_state)
                delay :         if (text_lcd_cnt == delay_cnt)           text_lcd_cnt <= 0; else text_lcd_cnt <= text_lcd_cnt + 1;
                function_set :  if (text_lcd_cnt == function_set_cnt)    text_lcd_cnt <= 0; else text_lcd_cnt <= text_lcd_cnt + 1;
                disp_onoff :    if (text_lcd_cnt == disp_onoff_cnt)      text_lcd_cnt <= 0; else text_lcd_cnt <= text_lcd_cnt + 1;
                entry_mode :    if (text_lcd_cnt == entry_mode_cnt)      text_lcd_cnt <= 0; else text_lcd_cnt <= text_lcd_cnt + 1;
                line1 :         if (text_lcd_cnt == line1_cnt)           text_lcd_cnt <= 0; else text_lcd_cnt <= text_lcd_cnt + 1;
                line2 :         if (text_lcd_cnt == line2_cnt)           text_lcd_cnt <= 0; else text_lcd_cnt <= text_lcd_cnt + 1;
                delay_t : begin
                    if (text_lcd_cnt == delay_t_cnt) text_lcd_cnt <= 0; 
                    else if (button_oneshot_sw != 0) text_lcd_cnt <= 0;
                    else text_lcd_cnt <= text_lcd_cnt + 1;
                end
                default: text_lcd_cnt <= 0;
            endcase
        end
    end

    always @(negedge rst, posedge clk_100hz) begin
        if (!rst) begin
            // dummy for default
            lcd_rs = 1;
            lcd_rw = 1;
            lcd_data = 8'b00000000;
        end else begin
            case (text_lcd_state)
                function_set : begin
                    // lcd 초기화 및 writing 준비
                    // 8bit, 2줄, 5x8 dot
                    lcd_rs = 0;
                    lcd_rw = 0;
                    lcd_data = 8'b00111000;
                end 
                disp_onoff : begin
                    // display on
                    // display on, cursor on, blink on
                    lcd_rs = 0;
                    lcd_rw = 0;
                    lcd_data = 8'b00001111;
                end
                entry_mode : begin
                    // entry mode set
                    // ddram 주소 증가, display shift off
                    lcd_rs = 0;
                    lcd_rw = 0;
                    lcd_data = 8'b00000110;
                    // lcd_data = 8'b00000111;
                end
                line1 : begin
                    lcd_rw = 0;
                    if (text_lcd_cnt == 0) lcd_rs = 0;
                    else lcd_rs = 1;
                    case (text_lcd_cnt)
                        // 1행 1열로 주소 설정
                        0: lcd_data = 8'b10000000;
                        // line1_text 출력
                        1 : lcd_data = line1_text[8*16-1:8*15];
                        2 : lcd_data = line1_text[8*15-1:8*14];
                        3 : lcd_data = line1_text[8*14-1:8*13];
                        4 : lcd_data = line1_text[8*13-1:8*12];
                        5 : lcd_data = line1_text[8*12-1:8*11];
                        6 : lcd_data = line1_text[8*11-1:8*10];
                        7 : lcd_data = line1_text[8*10-1:8*9];
                        8 : lcd_data = line1_text[8*9-1:8*8];
                        9 : lcd_data = line1_text[8*8-1:8*7];
                        10 : lcd_data = line1_text[8*7-1:8*6];
                        11 : lcd_data = line1_text[8*6-1:8*5];
                        12 : lcd_data = line1_text[8*5-1:8*4];
                        13 : lcd_data = line1_text[8*4-1:8*3];
                        14 : lcd_data = line1_text[8*3-1:8*2];
                        15 : lcd_data = line1_text[8*2-1:8*1];
                        16 : lcd_data = line1_text[8*1-1:8*0];
                        default : lcd_data = 8'h20; // space
                    endcase
                end
                line2 : begin
                    lcd_rw = 0;
                    if (text_lcd_cnt == 0) lcd_rs = 0;
                    else lcd_rs = 1;
                    case (text_lcd_cnt)
                        // 2행 1열로 주소 설정
                        0: lcd_data = 8'b11000000;
                        // line2_text 출력
                        1 : lcd_data = line2_text[8*16-1:8*15];
                        2 : lcd_data = line2_text[8*15-1:8*14];
                        3 : lcd_data = line2_text[8*14-1:8*13];
                        4 : lcd_data = line2_text[8*13-1:8*12];
                        5 : lcd_data = line2_text[8*12-1:8*11];
                        6 : lcd_data = line2_text[8*11-1:8*10];
                        7 : lcd_data = line2_text[8*10-1:8*9];
                        8 : lcd_data = line2_text[8*9-1:8*8];
                        9 : lcd_data = line2_text[8*8-1:8*7];
                        10 : lcd_data = line2_text[8*7-1:8*6];
                        11 : lcd_data = line2_text[8*6-1:8*5];
                        12 : lcd_data = line2_text[8*5-1:8*4];
                        13 : lcd_data = line2_text[8*4-1:8*3];
                        14 : lcd_data = line2_text[8*3-1:8*2];
                        15 : lcd_data = line2_text[8*2-1:8*1];
                        16 : lcd_data = line2_text[8*1-1:8*0];
                        default : lcd_data = 8'h20; // space
                    endcase
                end
                delay_t : begin
                    // ddram_address자리에 커서 표시
                    lcd_rs = 0;
                    lcd_rw = 0;
                    lcd_data = 8'b10000000 + ddram_address;
                end
                clear_disp : begin
                    // display clear
                    lcd_rs = 0;
                    lcd_rw = 0;
                    lcd_data = 8'b00000001;
                end
                default: begin
                    // dummy for default
                    lcd_rs = 1;
                    lcd_rw = 1;
                    lcd_data = 8'b00000000;
                end
            endcase
        end
    end
    // lcd_e에 100hz 신호 할당
    assign lcd_e = clk_100hz;
endmodule
