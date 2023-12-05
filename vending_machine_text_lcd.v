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


module vending_machine_text_lcd(
    input clk, rst,
    input [1:0] move_sw,
    input [1:0] select_sw,
    input lcd_enable,
    output lcd_e, 
    output reg lcd_rs, lcd_rw,
    output reg [7:0] lcd_data
    );
    // 상품명을 저장하는 변수
    // 최대 5글자, 3개의 상품명을 저장
    parameter [8*7*3-1:0] product = {
        // "1.Coke "
        8'h31, 8'h2e, 8'h43, 8'h6f, 8'h6b, 8'h65, 8'h20,
        // "2.Water"
        8'h32, 8'h2e, 8'h57, 8'h61, 8'h74, 8'h65, 8'h72,
        // "3.Juice"
        8'h33, 8'h2e, 8'h4a, 8'h75, 8'h69, 8'h63, 8'h65
        };

    // 가격을 글자로 바꿔서 저장하는 변수
    // 100원 단위로 물건이 증가하기 때문에 100으로 나눈 몫을 저장
    // 따라서 2글자만 있으면 됨
    parameter [8*2*3-1:0] price_text = {
        8'h31, 8'h30, // "10"
        8'h31, 8'h32, // "12"
        8'h31, 8'h35  // "15"
        };

    wire clk_100hz;
    gen_clk_100hz clk_gen(
        .clk(clk), .rst(rst),
        .clk_100hz(clk_100hz)
    );

    // 이동과 선택에 대한 oneshot swtich
    wire [1:0] move_oneshot_sw, select_oneshot_sw;

    gen_one_shot_sw oneshot_sw(
        .clk_100hz(clk_100hz),
        .lcd_enable(lcd_enable),
        .move_sw(move_sw), .select_sw(select_sw),
        .move(move_oneshot_sw), .select(select_oneshot_sw)
    );

    // line1, line2에 출력할 문자열을 저장하는 변수
    reg [8*16-1:0] line1_text;
    reg [8*16-1:0] line2_text;
    // 커서 주소를 저장하는 변수
    reg [6:0] ddram_address;

    // 현재 선택한 상품을 저장하는 변수
    reg [1:0] product_id;
    // 현재 선택한 상품이 선택되었는지 저장하는 변수
    reg selected;

    always @(negedge rst, posedge clk_100hz) begin
        if (!rst) begin
            product_id = 0; // 첫번째 상품
            selected = 0; // 선택 안됨
            ddram_address = 7'hd; // 커서 주소 초기화
            // "1.Coke 1000W  ▲"
            line1_text[8*16-1:8*9] = product[8*7*3-1:8*7*2]; // "1.Coke "
            line1_text[8*9-1:8*8] = 8'h20; // space
            line1_text[8*8-1:8*6] = price_text[8*2*3-1:8*2*2]; // "10"
            line1_text[8*6-1:8*0] = {8'h30, 8'h30, 8'h57, 8'h20, 8'h20, 8'h5e}; // "00W  ^"
            // "2.Water 1200W  ▼"
            line2_text[8*16-1:8*9] = product[8*7*2-1:8*7*1]; // "2.Water"
            line2_text[8*9-1:8*8] = 8'h20; // space
            line2_text[8*8-1:8*6] = price_text[8*2*2-1:8*2*1]; // "12"
            line2_text[8*6-1:8*0] = {8'h30, 8'h30, 8'h57, 8'h20, 8'h20, 8'h56}; // "00W  v"
        end
        else begin
            // move[1] : move up, move[0] : move down
            // product_id, ddram_address 설정
            if (move_oneshot_sw[1]) begin
                if (product_id > 0) product_id = product_id - 1;
            end
            else if (move_oneshot_sw[0]) begin
                if (product_id < 2) product_id = product_id + 1;
            end
            // line1_text, line2_text 설정
            case (product_id)
                0 : begin
                    line1_text[8*16-1:8*9] = product[8*7*3-1:8*7*2]; // "1.Coke "
                    line2_text[8*16-1:8*9] = product[8*7*2-1:8*7*1]; // "2.Water"
                    line1_text[8*8-1:8*6] = price_text[8*2*3-1:8*2*2]; // "10"
                    line2_text[8*8-1:8*6] = price_text[8*2*2-1:8*2*1]; // "12"
                end
                1 : begin
                    if (ddram_address == 7'hd) begin
                        line1_text[8*16-1:8*9] = product[8*7*3-1:8*7*2]; // "1.Coke "
                        line2_text[8*16-1:8*9] = product[8*7*2-1:8*7*1]; // "2.Water"
                        line1_text[8*8-1:8*6] = price_text[8*2*3-1:8*2*2]; // "10"
                        line2_text[8*8-1:8*6] = price_text[8*2*2-1:8*2*1]; // "12"
                    end
                    else if (ddram_address == 7'h4d) begin
                        line1_text[8*16-1:8*9] = product[8*7*2-1:8*7*1]; // "2.Water"
                        line2_text[8*16-1:8*9] = product[8*7*1-1:8*7*0]; // "3.Juice"
                        line1_text[8*8-1:8*6] = price_text[8*2*2-1:8*2*1]; // "12"
                        line2_text[8*8-1:8*6] = price_text[8*2*1-1:8*2*0]; // "15"
                    end
                end
                2 : begin
                    line1_text[8*16-1:8*9] = product[8*7*2-1:8*7*1]; // "2.Water"
                    line2_text[8*16-1:8*9] = product[8*7*1-1:8*7*0]; // "3.Juice"
                    line1_text[8*8-1:8*6] = price_text[8*2*2-1:8*2*1]; // "12"
                    line2_text[8*8-1:8*6] = price_text[8*2*1-1:8*2*0]; // "15"
                end
            endcase

            if(move_oneshot_sw[1]) ddram_address = 7'hd;
            else if (move_oneshot_sw[0]) ddram_address = 7'h4d;

            // select[1] : select, select[0] : deselect
            if (select_oneshot_sw[1]) begin
                if (ddram_address == 7'hd) line1_text[8*2-1:8*1] = 8'h56; // v
                else if (ddram_address == 7'h4d) line2_text[8*2-1:8*1] = 8'h56; // v
                selected = 1;
            end
            else if (select_oneshot_sw[0]) begin
                if (ddram_address == 7'hd) line1_text[8*2-1:8*1] = 8'h20; // space
                else if (ddram_address == 7'h4d) line2_text[8*2-1:8*1] = 8'h20; // space
                selected = 0;
            end
        end
    end

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
    integer cnt;
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
                    else if (move_oneshot_sw != 0) text_lcd_state <= line1;
                    else if (select_oneshot_sw != 0) text_lcd_state <= line1;
                end
                // clear disp는 따로 작성하지 않음
                default : text_lcd_state <= delay;
            endcase
        end
    end

    // text_lcd_cnt 전환 always문
    always @(negedge rst, posedge clk_100hz) begin
        if (!rst) cnt <= 0;
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
                    else if (move_oneshot_sw != 0) text_lcd_cnt <= 0;
                    else if (select_oneshot_sw != 0) text_lcd_cnt <= 0;
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
            lcd_data = 0;
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
                end
                line1 : begin
                    lcd_rw = 0;
                    if (text_lcd_cnt == 0) lcd_rs = 0;
                    else lcd_rs = 1;
                    case (text_lcd_cnt)
                        // 1행 1열로 주소 설정
                        0: lcd_data = 8'b10000000;
                        // line1_text 출력
                        1 : lcd_data <= line1_text[8*16-1:8*15];
                        2 : lcd_data <= line1_text[8*15-1:8*14];
                        3 : lcd_data <= line1_text[8*14-1:8*13];
                        4 : lcd_data <= line1_text[8*13-1:8*12];
                        5 : lcd_data <= line1_text[8*12-1:8*11];
                        6 : lcd_data <= line1_text[8*11-1:8*10];
                        7 : lcd_data <= line1_text[8*10-1:8*9];
                        8 : lcd_data <= line1_text[8*9-1:8*8];
                        9 : lcd_data <= line1_text[8*8-1:8*7];
                        10 : lcd_data <= line1_text[8*7-1:8*6];
                        11 : lcd_data <= line1_text[8*6-1:8*5];
                        12 : lcd_data <= line1_text[8*5-1:8*4];
                        13 : lcd_data <= line1_text[8*4-1:8*3];
                        14 : lcd_data <= line1_text[8*3-1:8*2];
                        15 : lcd_data <= line1_text[8*2-1:8*1];
                        16 : lcd_data <= line1_text[8*1-1:8*0];
                        default : lcd_data <= 8'h20; // space
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
                        1 : lcd_data <= line2_text[8*16-1:8*15];
                        2 : lcd_data <= line2_text[8*15-1:8*14];
                        3 : lcd_data <= line2_text[8*14-1:8*13];
                        4 : lcd_data <= line2_text[8*13-1:8*12];
                        5 : lcd_data <= line2_text[8*12-1:8*11];
                        6 : lcd_data <= line2_text[8*11-1:8*10];
                        7 : lcd_data <= line2_text[8*10-1:8*9];
                        8 : lcd_data <= line2_text[8*9-1:8*8];
                        9 : lcd_data <= line2_text[8*8-1:8*7];
                        10 : lcd_data <= line2_text[8*7-1:8*6];
                        11 : lcd_data <= line2_text[8*6-1:8*5];
                        12 : lcd_data <= line2_text[8*5-1:8*4];
                        13 : lcd_data <= line2_text[8*4-1:8*3];
                        14 : lcd_data <= line2_text[8*3-1:8*2];
                        15 : lcd_data <= line2_text[8*2-1:8*1];
                        16 : lcd_data <= line2_text[8*1-1:8*0];
                        default : lcd_data <= 8'h20; // space
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
