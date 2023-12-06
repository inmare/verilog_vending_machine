`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/20 13:03:38
// Design Name: 
// Module Name: vending_machine
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


module vending_machine(
    input clk, rst,
    input [11:0] button_sw,
    input admin_mode,
    // fnd array
    output [7:0] seg_com, seg_array,
    // piezo
    output piezo,
    // text lcd
    output lcd_e, lcd_rs, lcd_rw,
    output [7:0] lcd_data
    );
    genvar i;

    wire [11:0] button_sw_oneshot;
    generate
        for (i = 0; i < 12; i = i + 1) begin
            one_shot_en_sw button_sw_oneshot_inst(
                .clk(clk),
                .enable(button_sw[i]),
                .eout(button_sw_oneshot[i])
            );
        end
    endgenerate

    // fnd array 표시용 돈
    wire [7:0] display_money_binary;
    // piezo가 어떤 멜로디를 표시할지 정하는 변수
    wire [3:0] note_state;
    wire [2:0] note_played;
    // line1, line2에 출력할 문자열을 저장하는 변수
    wire [8*16-1:0] line1_text, line2_text;
    // 커서 주소를 저장하는 변수
    wire [6:0] ddram_address;

    main_logic main_logic(
        .clk(clk), .rst(rst),
        .button_sw_oneshot(button_sw_oneshot),
        .admin_mode(admin_mode),
        .display_money_binary(display_money_binary),
        .note_state(note_state), .note_played(note_played),
        .line1_text(line1_text), .line2_text(line2_text),
        .ddram_address(ddram_address)
    );

    // 돈을 fnd array에 표시
    money_to_fnd_array fnd_array(
        .clk(clk), .rst(rst),
        .display_money_binary(display_money_binary),
        .seg_com(seg_com), .seg_array(seg_array)
    );

    // 버튼 클릭시 piezo에 다른 음이 표현되도록 바꿈
    item_based_piezo item_piezo(
        .clk(clk), .rst(rst),
        .note_state(note_state), .note_played(note_played),
        .piezo(piezo)
    );

    text_lcd_display text_lcd(
        .clk(clk), .rst(rst),
        .button_sw(button_sw),
        .admin_mode(admin_mode),
        .line1_text(line1_text), .line2_text(line2_text),
        .ddram_address(ddram_address),
        .lcd_e(lcd_e), .lcd_rs(lcd_rs), .lcd_rw(lcd_rw),
        .lcd_data(lcd_data)
    );
endmodule
