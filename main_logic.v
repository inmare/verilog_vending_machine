`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/12/03 15:50:30
// Design Name: 
// Module Name: main_logic
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


module main_logic(
    input clk, rst,
    input [11:0] button_sw_oneshot,
    // 최종적으로 fnd array에 표시될 돈
    output reg [7:0] display_money_binary,
    // piezo가 어떤 멜로디를 표시할지 정하는 변수
    output reg [3:0] note_state,
    output reg [2:0] note_played,
    // led용 상품 개수를 알려주는 변수
    output reg [3:0] prod_count_current,
    // line1, line2에 출력할 문자열을 저장하는 변수
    output reg [8*16-1:0] line1_text, line2_text,
    // 커서 주소를 저장하는 변수
    output reg [6:0] ddram_address
    );
    // ----------------실험 때 바뀌는 변수들----------------
    // 실제 값은 2000000으로 설정해야 됨
    // parameter coin_btn_cnt_limit = 20;
    parameter coin_btn_cnt_limit = 2000000;
    
    // 실제 값은 1000000으로 설정해야 됨
    // parameter return_cnt_limit = 10;
    parameter return_cnt_limit = 1000000;

    // 실제 값은 각각 100000, 200000, 300000, 400000
    // parameter note_1_limit = 5;
    // parameter note_2_limit = 10;
    // parameter note_3_limit = 15;
    // parameter note_4_limit = 20;
    parameter note_1_limit = 100000;
    parameter note_2_limit = 200000;
    parameter note_3_limit = 300000;
    parameter note_4_limit = 400000;

    // 실제 값은 1000000으로 설정해야 됨
    // parameter warning_cnt_limit = 10;
    parameter warning_cnt_limit = 1000000;

    // --------------스위치를 버튼 변수에 할당---------------
    // 커서 이동 버튼
    wire move_up_sw, move_down_sw;
    assign move_up_sw = button_sw_oneshot[10];
    assign move_down_sw = button_sw_oneshot[4];

    // 선택 버튼
    wire select_toggle_sw;
    assign select_toggle_sw = button_sw_oneshot[7];

    // 동전 입력
    wire [2:0] coin_sw;
    assign coin_sw = button_sw_oneshot[2:0];

    // 구매 스위치
    wire buy_sw;
    assign buy_sw = button_sw_oneshot[9];

    // 반환 스위치
    wire return_sw;
    assign return_sw = button_sw_oneshot[3];

    // 상품 추가 스위치
    wire prod_add_sw;
    assign prod_add_sw = button_sw_oneshot[5];

    // 관리자 모드 스위치
    wire admin_mode_sw;
    assign admin_mode_sw = button_sw_oneshot[11];

    // ----------------parameter 변수들----------------
    // 커서 이동 제한
    parameter cursor_upper_limit = 0;
    parameter cursor_lower_limit = 3;

    // 각 상품 id
    parameter prod1_id = 1;
    parameter prod2_id = 2;
    parameter prod3_id = 3;
    parameter prod4_id = 4;

    // 각 상품 가격
    parameter prod1_price = 10;
    parameter prod2_price = 12;
    parameter prod3_price = 15;
    parameter prod4_price = 18;

    // 상품 제한
    parameter prod_limit = 9;

    // 각 상품 초기 개수
    parameter prod1_init_count = 9;
    parameter prod2_init_count = 1;
    parameter prod3_init_count = 0;
    parameter prod4_init_count = 4;

    // 노트 state
    parameter note_100w = 1;
    parameter note_500w = 2;
    parameter note_1000w = 3;
    parameter note_prod1 = 4;
    parameter note_prod2 = 5;
    parameter note_prod3 = 6;
    parameter note_prod4 = 7;

    // lcd에 보여줄 경고문 state
    parameter warn_none             = 0;
    parameter warn_not_enough_money = 1;
    parameter warn_buy_product      = 2;
    parameter warn_admin_mode       = 3;

    parameter [8*16-1:0] not_enough_money_line1 = {
        // "Not enough "
        8'h4e, 8'h6f, 8'h74, 8'h20, 8'h65, 8'h6e, 8'h6f, 8'h75, 8'h67, 8'h68, 8'h20, 
        // "money"
        8'h6d, 8'h6f, 8'h6e, 8'h65, 8'h79
    };
    parameter [8*16-1:0] not_enough_money_line2 = {
        // "for "
        8'h66, 8'h6f, 8'h72, 8'h20,
        // 공백
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20
    };

    parameter [8*16-1:0] buy_product_line1 = {
        // "Thank you for"
        8'h54, 8'h68, 8'h61, 8'h6e, 8'h6b, 8'h20, 8'h79, 8'h6f, 8'h75, 8'h20, 8'h66, 8'h6f, 8'h72,
        // 공백
        8'h20, 8'h20, 8'h20
    };
    parameter [8*16-1:0] buy_product_line2 = {
        // "buying "
        8'h62, 8'h75, 8'h79, 8'h69, 8'h6e, 8'h67, 8'h20,
        // 공백
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20
    };

    parameter [8*16-1:0] admin_mode_line1 = {
        // "You are on"
        8'h59, 8'h6f, 8'h75, 8'h20, 8'h61, 8'h72, 8'h65, 8'h20, 8'h6f, 8'h6e, 8'h20,
        // 공백
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20
    };
    parameter [8*16-1:0] admin_mode_line2 = {
        // "admin mode"
        8'h61, 8'h64, 8'h6d, 8'h69, 8'h6e, 8'h20, 8'h6d, 8'h6f, 8'h64, 8'h65,
        // 공백
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20
    };

    // 상품 번호 표시를 위한 변수
    parameter [8*2*4-1:0] prod_num = {
        // "1."
        8'h31, 8'h2e, 
        // "2."
        8'h32, 8'h2e, 
        // "3."
        8'h33, 8'h2e,
        // "4."
        8'h34, 8'h2e
    };

    // 상품명을 저장하는 변수. 최대 5글자, 3개의 상품명을 저장
    parameter [8*5*4-1:0] product = {
        // "Coke "
        8'h43, 8'h6f, 8'h6b, 8'h65, 8'h20,
        // "Water"
        8'h57, 8'h61, 8'h74, 8'h65, 8'h72,
        // "Juice"
        8'h4a, 8'h75, 8'h69, 8'h63, 8'h65,
        // "Cider"
        8'h43, 8'h69, 8'h64, 8'h65, 8'h72
        };

    // 가격을 글자로 바꿔서 저장하는 변수, 100으로 나눈 몫을 저장
    parameter [8*2*4-1:0] price_text = {
        8'h31, 8'h30, // "10"
        8'h31, 8'h32, // "12"
        8'h31, 8'h35, // "15"
        8'h31, 8'h38  // "18"
        };
    parameter [8*16-1:0] line1_init_text = {
        // "1.Coke "
        prod_num[8*2*4-1:8*2*3], product[8*5*4-1:8*5*3], 8'h20,
        // "10"
        price_text[8*2*4-1:8*2*3], 
        // "00W  ^"
        8'h30, 8'h30, 8'h57, 8'h20, 8'h20, 8'h5e
    };
    parameter [8*16-1:0] line2_init_text = {
        // "2.Water"
        prod_num[8*2*3-1:8*2*2], product[8*5*3-1:8*5*2], 8'h20,
        // "12"
        price_text[8*2*3-1:8*2*2], 
        // "00W  v"
        8'h30, 8'h30, 8'h57, 8'h20, 8'h20, 8'h76
    };
    
    // ----------------reg 변수들----------------
    // 현재 입력한 금액을 보여주기 위한 cnt
    integer coin_btn_cnt;
    // 금액 반환시 금액을 보여주기 위한 cnt
    integer return_cnt;
    // note_played 상태를 바꾸기 위한 cnt
    integer note_cnt;
    // 경고문 출력을 위한 cnt
    integer warning_cnt;

    // 현재 커서 위치
    reg [2:0] cursor_pos;
    // 선택, 미선택 여부
    reg selected;
    // 현재 선택한 상품
    reg [2:0] selected_item;

    // 현재 입력된 돈
    reg [7:0] inserted_money;
    // 계산 히스토리 저장 현재는 총 10개의 역사 저장 가능
    reg [7*9-1:0] total_money_history;
    // 계산 히스토리 비활성화 상태
    reg history_disabled;

    // 동전 입력 스위치가 눌러졌는지 알려주는 state
    reg coin_btn_state;
    // 반환 스위치가 눌려졌는지 알려주는 state
    reg return_state;
    // 경고문 출력 state
    reg [2:0] warning_state;
    // 경고문에 출력될 상품 id;
    reg [2:0] warning_prod_id;
    // 관리자 모드 state
    reg admin_mode_state;

    // 현재 lcd에 표시될 상품을 표시하는 변수
    reg [2:0] line1_prod, line2_prod;
    // 현재 상품 개수
    reg [3:0] prod1_count, prod2_count, prod3_count, prod4_count;

    // 물건 구매시 금액 변화용 always문
    always @(negedge rst, posedge clk) begin
        if (!rst) begin
            // 각종 값들 초기화
            selected_item <= 0; cursor_pos <= 0; selected <= 0;
            inserted_money <= 0; total_money_history <= 0;
            history_disabled <= 0; display_money_binary <= 0;
            prod_count_current <= prod1_init_count;
            prod1_count <= prod1_init_count;
            prod2_count <= prod2_init_count;
            prod3_count <= prod3_init_count;
            prod4_count <= prod4_init_count;
            coin_btn_state <= 0; return_state <= 0; admin_mode_state <= 0;
            warning_state <= 0; warning_prod_id <= 0;
            note_state <= 0; note_played <= 0;
            coin_btn_cnt <= 0; return_cnt <= 0; 
            note_cnt <= 0; warning_cnt <= 0;
            line1_text <= 0; line2_text <= 0; ddram_address <= 7'hd;
            // "1.Coke  1000W  ^"
            line1_text[8*16-1:8*9] <= line1_init_text;
            // "2.Water 1200W  v"
            line2_text[8*16-1:8*9] <= line2_init_text;
        end
        else begin
            if (move_up_sw || move_down_sw) begin
                // move up 버튼이 눌렀을 경우 커서 위치를 한 칸 위로 이동
                if (move_up_sw) begin
                    if (cursor_pos > cursor_upper_limit) begin
                        cursor_pos = cursor_pos - 1;
                        ddram_address = 7'hd;
                    end
                end
                // move down 버튼이 눌렸을 경우 커서 위치를 한 칸 아래로 이동
                else if (move_down_sw) begin
                    if (cursor_pos < cursor_lower_limit) begin
                        cursor_pos = cursor_pos + 1;
                        ddram_address = 7'h4d;
                    end
                end
                case (cursor_pos)
                    0 : prod_count_current = prod1_count;
                    1 : prod_count_current = prod2_count;
                    2 : prod_count_current = prod3_count;
                    3 : prod_count_current = prod4_count;
                    default : prod_count_current = 0;
                endcase
            end
            // 선택 버튼이 눌렸을 경우
            else if (select_toggle_sw) begin
                // 선택한 아이템 id를 cursor 위치에 + 1을 한 값으로 지정함
                if (selected_item != 0 && cursor_pos + 1 == selected_item) begin
                    selected_item = 0;
                    selected = 0;
                end
                else begin
                    case (cursor_pos)
                        0 : begin
                            if (prod1_count != 0) begin
                                selected_item = prod1_id;
                                note_state = note_prod1;
                                warning_prod_id = prod1_id;
                                selected = 1;
                            end 
                        end
                        1 : begin
                            if (prod2_count != 0) begin
                                selected_item = prod2_id;
                                note_state = note_prod2;
                                warning_prod_id = prod2_id;
                                selected = 1;
                            end 
                        end
                        2 : begin
                            if (prod3_count != 0) begin
                                selected_item = prod3_id;
                                note_state = note_prod3;
                                warning_prod_id = prod3_id;
                                selected = 1;
                            end 
                        end
                        3 : begin
                            if (prod4_count != 0) begin
                                selected_item = prod4_id;
                                note_state = note_prod4;
                                warning_prod_id = prod4_id;
                                selected = 1;
                            end 
                        end
                        default : selected_item = 0;
                    endcase
                end
            end
            // 동전 입력 스위치를 눌렀을 때
            else if (coin_sw != 0) begin
                // 버튼 스위치에 따라서 inserted_money에 금액을 저장
                case (coin_sw)
                    3'b100 : begin
                        inserted_money = 1;
                        note_state = note_100w;
                    end
                    3'b010 : begin
                        inserted_money = 5;
                        note_state = note_500w;
                    end
                    3'b001 : begin
                        inserted_money = 10;
                        note_state = note_1000w;
                    end
                    default : begin
                        inserted_money = 0;
                        note_state = 0;
                    end
                endcase
                // 총 입력 금액 역사를 한 칸씩 뒤로 밀고, 
                // 가장 최근 입력 금액을 추가한 값을 배열 제일 앞에 저장
                total_money_history[7*8-1:0] = total_money_history[7*9-1:7*1];
                total_money_history[7*9-1:7*8] = total_money_history[7*8-1:7*7] + inserted_money;
                // 표시되는 돈을 투입된 돈으로 설정
                display_money_binary = inserted_money;
                // 동전 입력 state 활성화
                coin_btn_state = 1;
            end
            // 구매 스위치를 눌렀을 때
            else if (buy_sw) begin
                // 현재 선택한 상품에 따라서
                case (selected_item)
                    prod1_id: begin
                        // 코카콜라의 개수가 0보다 크고 총 금액이 코카콜라의 가격보다 크면
                        if (prod1_count > 0 && total_money_history[7*9-1:7*8] > prod1_price) begin
                            // 코카콜라의 개수를 하나 줄이고
                            prod1_count = prod1_count - 1;
                            // 코카콜라의 가격만큼 총 금액을 줄인다
                            total_money_history[7*9-1:7*8] = total_money_history[7*9-1:7*8] - prod1_price;
                            warning_state = warn_buy_product;
                        end
                        else if (total_money_history[7*9-1:7*8] < prod1_price) 
                            warning_state = warn_not_enough_money;
                    end
                    prod2_id: begin
                        if (prod2_count > 0 && total_money_history[7*9-1:7*8] > prod2_price) begin
                            prod2_count = prod2_count - 1;
                            total_money_history[7*9-1:7*8] = total_money_history[7*9-1:7*8] - prod2_price;
                            warning_state = warn_buy_product;
                        end
                        else if (total_money_history[7*9-1:7*8] < prod2_price) 
                            warning_state = warn_not_enough_money;
                    end
                    prod3_id: begin
                        if (prod3_count > 0 && total_money_history[7*9-1:7*8] > prod3_price) begin
                            prod3_count = prod3_count - 1;
                            total_money_history[7*9-1:7*8] = total_money_history[7*9-1:7*8] - prod3_price;
                            warning_state = warn_buy_product;
                        end
                        else if (total_money_history[7*9-1:7*8] < prod3_price) 
                            warning_state = warn_not_enough_money;
                    end
                    prod4_id: begin
                        if (prod4_count > 0 && total_money_history[7*9-1:7*8] > prod4_price) begin
                            prod4_count = prod4_count - 1;
                            total_money_history[7*9-1:7*8] = total_money_history[7*9-1:7*8] - prod4_price;
                            warning_state = warn_buy_product;
                        end
                        else if (total_money_history[7*9-1:7*8] < prod4_price) 
                            warning_state = warn_not_enough_money;
                    end
                endcase
                if (selected_item != 0) begin
                    // 총 금액 역사를 가장 최근 역사를 제외하고 전부 초기화
                    total_money_history[7*8-1:7*0] = 0;
                    // 역사 초기화 상태 활성화
                    history_disabled = 1;
                    // 선택한 상품과 선택 여부를 초기화
                    selected_item = 0;
                    selected = 0;
                end
                // 표시되는 돈을 총 금액 역사의 가장 최근 값으로 설정
                display_money_binary = total_money_history[7*9-1:7*8];
            end
            else if (return_sw) begin
                // 표시되는 돈을 총 금액 역사의 가장 최근 값으로 설정
                display_money_binary = total_money_history[7*9-1:7*8];
                // return state 활성화
                return_state = 1;
            end
            else if (prod_add_sw) begin
                if (admin_mode_state) begin
                    // 관리자 모드일 경우에만 상품 추가 가능
                    case (cursor_pos)
                        0 : begin
                            if (prod1_count < prod_limit) prod1_count = prod1_count + 1;
                        end
                        1 : begin
                            if (prod2_count < prod_limit) prod2_count = prod2_count + 1;
                        end
                        2 : begin
                            if (prod3_count < prod_limit) prod3_count = prod3_count + 1;
                        end
                        3 : begin
                            if (prod4_count < prod_limit) prod4_count = prod4_count + 1;
                        end
                    endcase
                end
            end
            else if (admin_mode_sw) begin
                admin_mode_state = ~admin_mode_state;
                if (admin_mode_state) warning_state = warn_admin_mode;
            end

            // fnd array를 위한 if문 들

            // 동전 입력 버튼이 눌려졌을 때
            if (coin_btn_state) begin
                // 표시된 cnt값을 넘었을 때
                if (coin_btn_cnt >= coin_btn_cnt_limit) begin
                    coin_btn_cnt = 0;
                    coin_btn_state = 0;
                    // 표시되는 돈을 총 금액 역사의 가장 최근 값으로 되돌려 줌
                    display_money_binary = total_money_history[7*9-1:7*8];
                end 
                else coin_btn_cnt = coin_btn_cnt + 1;
            end
            // 반환 버튼이 눌러졌을 때
            else if (return_state) begin
                if (return_cnt >= return_cnt_limit) begin
                    return_cnt = 0;
                    // 구매 상태가 아닐 때
                    if (!history_disabled) begin
                        // 총 금액 역사를 한 단계씩 앞으로 되돌려 줌
                        total_money_history[7*9-1:7*1] = total_money_history[7*8-1:7*0];
                        total_money_history[7*1-1:7*0] = 8'd0;
                        display_money_binary = total_money_history[7*9-1:7*8];
                        if (total_money_history == 0) return_state = 0;                 
                    end
                    else begin
                        // 구매 상태일 경우 총 금액 역사 가장 최근 금액을 1씩 빼줌
                        // 100원씩 반환되는 모습 연출
                        if (total_money_history[7*9-1:7*8] != 0) begin
                            total_money_history[7*9-1:7*8] = total_money_history[7*9-1:7*8] - 1;
                            display_money_binary = total_money_history[7*9-1:7*8];
                        end
                        else begin
                            // 총 금액이 0원이 됐을 땐 return state 무효화
                            return_state = 0;
                            history_disabled = 0;
                        end
                    end
                end
                else return_cnt = return_cnt + 1;
            end

            // piezo를 위한 if문
            if (note_state != 0) begin
                if (note_cnt > note_4_limit) begin
                    note_cnt = 0;
                    note_state = 0;
                    note_played = 0;
                end
                else begin
                    if (note_cnt < note_1_limit) note_played = 1;
                    else if (note_cnt < note_2_limit) note_played = 2;
                    else if (note_cnt < note_3_limit) note_played = 3;
                    else if (note_cnt < note_4_limit) note_played = 4;
                    else note_played = 0;
                    note_cnt = note_cnt + 1;
                end
            end

            // lcd를 위한 if문
            if (warning_state != 0) begin
                if (warning_cnt > warning_cnt_limit) begin
                    warning_cnt = 0;
                    warning_state = 0;
                    warning_prod_id = 0;
                end
                else warning_cnt = warning_cnt + 1;
            end
            
            // lcd를 위한 case문
            case (warning_state)
                warn_none : begin
                    case (cursor_pos)
                        0 : begin
                            // prod 1, prod 2
                            line1_prod = prod1_id;
                            line2_prod = prod2_id;
                        end
                        1 : begin
                            if (ddram_address == 7'h4d) begin
                                // prod 1, prod 2
                                line1_prod = prod1_id;
                                line2_prod = prod2_id;
                            end
                            else if (ddram_address == 7'hd) begin
                                // prod 2, prod 3
                                line1_prod = prod2_id;
                                line2_prod = prod3_id;
                            end
                        end
                        2 : begin
                            if (ddram_address == 7'h4d) begin
                                // prod 2, prod 3
                                line1_prod = prod2_id;
                                line2_prod = prod3_id;
                            end
                            else if (ddram_address == 7'hd) begin
                                // prod 3, prod 4
                                line1_prod = prod3_id;
                                line2_prod = prod4_id;
                            end
                        end
                        3 : begin
                            line1_prod = prod3_id;
                            line2_prod = prod4_id;
                        end
                        default : begin
                            // prod 1, prod 2
                            line1_prod = prod1_id;
                            line2_prod = prod2_id;
                        end
                    endcase

                    case (line1_prod)
                        1 : begin
                            line1_text[8*16-1:8*14] = prod_num[8*2*4-1:8*2*3]; 
                            line1_text[8*14-1:8*9] = product[8*5*4-1:8*5*3];
                            line1_text[8*8-1:8*6] = price_text[8*2*4-1:8*2*3];
                            // 관리자 모드일 경우에는 남은 상품의 개수 보여주기,
                            // 아닐 경우에는 품절 여부만 보여주기
                            if (admin_mode_state) line1_text[8*2-1:8*1] = 8'h30 + prod1_count;
                            else begin
                                if (prod1_count == 0) line1_text[8*2-1:8*1] = 8'h58; // "X"
                                else line1_text[8*2-1:8*1] = 8'h20; // "space" 
                            end

                            if (line1_prod == selected_item) line1_text[8*3-1:8*2] = 8'h2a; // "*"
                            else line1_text[8*3-1:8*2] = 8'h20; // space
                        end
                        2 : begin
                            line1_text[8*16-1:8*14] = prod_num[8*2*3-1:8*2*2]; 
                            line1_text[8*14-1:8*9] = product[8*5*3-1:8*5*2];
                            line1_text[8*8-1:8*6] = price_text[8*2*3-1:8*2*2];
                            if (admin_mode_state) line1_text[8*2-1:8*1] = 8'h30 + prod2_count;
                            else begin
                                if (prod2_count == 0) line1_text[8*2-1:8*1] = 8'h58; // "X"
                                else line1_text[8*2-1:8*1] = 8'h20; // "space"
                            end

                            if (line1_prod == selected_item) line1_text[8*3-1:8*2] = 8'h2a; // "*"
                            else line1_text[8*3-1:8*2] = 8'h20; // space
                        end
                        3 : begin
                            line1_text[8*16-1:8*14] = prod_num[8*2*2-1:8*2*1];
                            line1_text[8*14-1:8*9] = product[8*5*2-1:8*5*1];
                            line1_text[8*8-1:8*6] = price_text[8*2*2-1:8*2*1];
                            if (admin_mode_state) line1_text[8*2-1:8*1] = 8'h30 + prod3_count;
                            else begin
                                if (prod3_count == 0) line1_text[8*2-1:8*1] = 8'h58; // "X"
                                else line1_text[8*2-1:8*1] = 8'h20; // "space"
                            end

                            if (line1_prod == selected_item) line1_text[8*3-1:8*2] = 8'h2a; // "*"
                            else line1_text[8*3-1:8*2] = 8'h20; // space
                        end
                        4 : begin
                            line1_text[8*16-1:8*14] = prod_num[8*2*1-1:8*2*0];
                            line1_text[8*14-1:8*9] = product[8*5*1-1:8*5*0];
                            line1_text[8*8-1:8*6] = price_text[8*2*1-1:8*2*0];
                            if (admin_mode_state) line1_text[8*2-1:8*1] = 8'h30 + prod4_count;
                            else begin
                                if (prod4_count == 0) line1_text[8*2-1:8*1] = 8'h58; // "X"
                                else line1_text[8*2-1:8*1] = 8'h20; // "space"
                            end

                            if (line1_prod == selected_item) line1_text[8*3-1:8*2] = 8'h2a; // "*"
                            else line1_text[8*3-1:8*2] = 8'h20; // space
                        end
                        default : begin
                            line1_text[8*16-1:8*14] = prod_num[8*2*3-1:8*2*2];
                            line1_text[8*14-1:8*9] = product[8*5*4-1:8*5*3];
                            line1_text[8*3-1:8*2] = 8'h20; // "space"
                            line1_text[8*2-1:8*1] = 8'h20; // "space"
                        end
                    endcase

                    case (line2_prod)
                        1 : begin
                            line2_text[8*16-1:8*14] = prod_num[8*2*4-1:8*2*3];
                            line2_text[8*14-1:8*9] = product[8*5*4-1:8*5*3];
                            line2_text[8*8-1:8*6] = price_text[8*2*4-1:8*2*3];
                            if (admin_mode_state) line2_text[8*2-1:8*1] = 8'h30 + prod1_count;
                            else begin
                                if (prod1_count == 0) line2_text[8*2-1:8*1] = 8'h58; // "X"
                                else line2_text[8*2-1:8*1] = 8'h20; // "space"
                            end
                        
                            if (line2_prod == selected_item) line2_text[8*3-1:8*2] = 8'h2a; // "*"
                            else line2_text[8*3-1:8*2] = 8'h20; // space
                        end
                        2 : begin
                            line2_text[8*16-1:8*14] = prod_num[8*2*3-1:8*2*2];
                            line2_text[8*14-1:8*9] = product[8*5*3-1:8*5*2];
                            line2_text[8*8-1:8*6] = price_text[8*2*3-1:8*2*2];
                            if (admin_mode_state) line2_text[8*2-1:8*1] = 8'h30 + prod2_count;
                            else begin
                                if (prod2_count == 0) line2_text[8*2-1:8*1] = 8'h58; // "X"
                                else line2_text[8*2-1:8*1] = 8'h20; // "space"
                            end

                            if (line2_prod == selected_item) line2_text[8*3-1:8*2] = 8'h2a; // "*"
                            else line2_text[8*3-1:8*2] = 8'h20; // space
                        end
                        3 : begin
                            line2_text[8*16-1:8*14] = prod_num[8*2*2-1:8*2*1];
                            line2_text[8*14-1:8*9] = product[8*5*2-1:8*5*1];
                            line2_text[8*8-1:8*6] = price_text[8*2*2-1:8*2*1];
                            if (admin_mode_state) line2_text[8*2-1:8*1] = 8'h30 + prod3_count;
                            else begin
                                if (prod3_count == 0) line2_text[8*2-1:8*1] = 8'h58; // "X"
                                else line2_text[8*2-1:8*1] = 8'h20; // "space"
                            end

                            if (line2_prod == selected_item) line2_text[8*3-1:8*2] = 8'h2a; // "*"
                            else line2_text[8*3-1:8*2] = 8'h20; // space
                        end
                        4 : begin
                            line2_text[8*16-1:8*14] = prod_num[8*2*1-1:8*2*0];
                            line2_text[8*14-1:8*9] = product[8*5*1-1:8*5*0];
                            line2_text[8*8-1:8*6] = price_text[8*2*1-1:8*2*0];
                            if (admin_mode_state) line2_text[8*2-1:8*1] = 8'h30 + prod4_count;
                            else begin
                                if (prod4_count == 0) line2_text[8*2-1:8*1] = 8'h58; // "X"
                                else line2_text[8*2-1:8*1] = 8'h20; // "space"
                            end

                            if (line2_prod == selected_item) line2_text[8*3-1:8*2] = 8'h2a; // "*"
                            else line2_text[8*3-1:8*2] = 8'h20; // space
                        end
                        default : begin
                            line2_text[8*16-1:8*9] = product[8*5*3-1:8*5*2];
                            line2_text[8*3-1:8*2] = 8'h20; // "space"
                            line2_text[8*2-1:8*1] = 8'h20; // "space"
                        end
                    endcase
                end
                warn_not_enough_money : begin
                    line1_text = not_enough_money_line1;
                    line2_text = not_enough_money_line2;
                    case (warning_prod_id)
                        prod1_id : line2_text[8*12-1:8*7] = product[8*5*4-1:8*5*3];
                        prod2_id : line2_text[8*12-1:8*7] = product[8*5*3-1:8*5*2];
                        prod3_id : line2_text[8*12-1:8*7] = product[8*5*2-1:8*5*1];
                        prod4_id : line2_text[8*12-1:8*7] = product[8*5*1-1:8*5*0];
                    endcase
                end
                warn_buy_product : begin
                    line1_text = buy_product_line1;
                    line2_text = buy_product_line2;
                    case (warning_prod_id)
                        prod1_id : line2_text[8*8-1:8*3] = product[8*5*4-1:8*5*3];
                        prod2_id : line2_text[8*8-1:8*3] = product[8*5*3-1:8*5*2];
                        prod3_id : line2_text[8*8-1:8*3] = product[8*5*2-1:8*5*1];
                        prod4_id : line2_text[8*8-1:8*3] = product[8*5*1-1:8*5*0];
                    endcase
                end
                warn_admin_mode : begin
                    line1_text = admin_mode_line1;
                    line2_text = admin_mode_line2;
                end
            endcase
        end
    end
endmodule
