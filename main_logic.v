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
    // ���������� fnd array�� ǥ�õ� ��
    output reg [7:0] display_money_binary,
    // piezo�� � ��ε� ǥ������ ���ϴ� ����
    output reg [3:0] note_state,
    output reg [2:0] note_played,
    // led�� ��ǰ ������ �˷��ִ� ����
    output reg [3:0] prod_count_current,
    // line1, line2�� ����� ���ڿ��� �����ϴ� ����
    output reg [8*16-1:0] line1_text, line2_text,
    // Ŀ�� �ּҸ� �����ϴ� ����
    output reg [6:0] ddram_address
    );
    // ----------------���� �� �ٲ�� ������----------------
    // ���� ���� 2000000���� �����ؾ� ��
    // parameter coin_btn_cnt_limit = 20;
    parameter coin_btn_cnt_limit = 2000000;
    
    // ���� ���� 1000000���� �����ؾ� ��
    // parameter return_cnt_limit = 10;
    parameter return_cnt_limit = 1000000;

    // ���� ���� ���� 100000, 200000, 300000, 400000
    // parameter note_1_limit = 5;
    // parameter note_2_limit = 10;
    // parameter note_3_limit = 15;
    // parameter note_4_limit = 20;
    parameter note_1_limit = 100000;
    parameter note_2_limit = 200000;
    parameter note_3_limit = 300000;
    parameter note_4_limit = 400000;

    // ���� ���� 1000000���� �����ؾ� ��
    // parameter warning_cnt_limit = 10;
    parameter warning_cnt_limit = 1000000;

    // --------------����ġ�� ��ư ������ �Ҵ�---------------
    // Ŀ�� �̵� ��ư
    wire move_up_sw, move_down_sw;
    assign move_up_sw = button_sw_oneshot[10];
    assign move_down_sw = button_sw_oneshot[4];

    // ���� ��ư
    wire select_toggle_sw;
    assign select_toggle_sw = button_sw_oneshot[7];

    // ���� �Է�
    wire [2:0] coin_sw;
    assign coin_sw = button_sw_oneshot[2:0];

    // ���� ����ġ
    wire buy_sw;
    assign buy_sw = button_sw_oneshot[9];

    // ��ȯ ����ġ
    wire return_sw;
    assign return_sw = button_sw_oneshot[3];

    // ��ǰ �߰� ����ġ
    wire prod_add_sw;
    assign prod_add_sw = button_sw_oneshot[5];

    // ������ ��� ����ġ
    wire admin_mode_sw;
    assign admin_mode_sw = button_sw_oneshot[11];

    // ----------------parameter ������----------------
    // Ŀ�� �̵� ����
    parameter cursor_upper_limit = 0;
    parameter cursor_lower_limit = 3;

    // �� ��ǰ id
    parameter prod1_id = 1;
    parameter prod2_id = 2;
    parameter prod3_id = 3;
    parameter prod4_id = 4;

    // �� ��ǰ ����
    parameter prod1_price = 10;
    parameter prod2_price = 12;
    parameter prod3_price = 15;
    parameter prod4_price = 18;

    // ��ǰ ����
    parameter prod_limit = 9;

    // �� ��ǰ �ʱ� ����
    parameter prod1_init_count = 9;
    parameter prod2_init_count = 1;
    parameter prod3_init_count = 0;
    parameter prod4_init_count = 4;

    // ��Ʈ state
    parameter note_100w = 1;
    parameter note_500w = 2;
    parameter note_1000w = 3;
    parameter note_prod1 = 4;
    parameter note_prod2 = 5;
    parameter note_prod3 = 6;
    parameter note_prod4 = 7;

    // lcd�� ������ ��� state
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
        // ����
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20
    };

    parameter [8*16-1:0] buy_product_line1 = {
        // "Thank you for"
        8'h54, 8'h68, 8'h61, 8'h6e, 8'h6b, 8'h20, 8'h79, 8'h6f, 8'h75, 8'h20, 8'h66, 8'h6f, 8'h72,
        // ����
        8'h20, 8'h20, 8'h20
    };
    parameter [8*16-1:0] buy_product_line2 = {
        // "buying "
        8'h62, 8'h75, 8'h79, 8'h69, 8'h6e, 8'h67, 8'h20,
        // ����
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20
    };

    parameter [8*16-1:0] admin_mode_line1 = {
        // "You are on"
        8'h59, 8'h6f, 8'h75, 8'h20, 8'h61, 8'h72, 8'h65, 8'h20, 8'h6f, 8'h6e, 8'h20,
        // ����
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20
    };
    parameter [8*16-1:0] admin_mode_line2 = {
        // "admin mode"
        8'h61, 8'h64, 8'h6d, 8'h69, 8'h6e, 8'h20, 8'h6d, 8'h6f, 8'h64, 8'h65,
        // ����
        8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20
    };

    // ��ǰ ��ȣ ǥ�ø� ���� ����
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

    // ��ǰ���� �����ϴ� ����. �ִ� 5����, 3���� ��ǰ���� ����
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

    // ������ ���ڷ� �ٲ㼭 �����ϴ� ����, 100���� ���� ���� ����
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
    
    // ----------------reg ������----------------
    // ���� �Է��� �ݾ��� �����ֱ� ���� cnt
    integer coin_btn_cnt;
    // �ݾ� ��ȯ�� �ݾ��� �����ֱ� ���� cnt
    integer return_cnt;
    // note_played ���¸� �ٲٱ� ���� cnt
    integer note_cnt;
    // ��� ����� ���� cnt
    integer warning_cnt;

    // ���� Ŀ�� ��ġ
    reg [2:0] cursor_pos;
    // ����, �̼��� ����
    reg selected;
    // ���� ������ ��ǰ
    reg [2:0] selected_item;

    // ���� �Էµ� ��
    reg [7:0] inserted_money;
    // ��� �����丮 ���� ����� �� 10���� ���� ���� ����
    reg [7*9-1:0] total_money_history;
    // ��� �����丮 ��Ȱ��ȭ ����
    reg history_disabled;

    // ���� �Է� ����ġ�� ���������� �˷��ִ� state
    reg coin_btn_state;
    // ��ȯ ����ġ�� ���������� �˷��ִ� state
    reg return_state;
    // ��� ��� state
    reg [2:0] warning_state;
    // ����� ��µ� ��ǰ id;
    reg [2:0] warning_prod_id;
    // ������ ��� state
    reg admin_mode_state;

    // ���� lcd�� ǥ�õ� ��ǰ�� ǥ���ϴ� ����
    reg [2:0] line1_prod, line2_prod;
    // ���� ��ǰ ����
    reg [3:0] prod1_count, prod2_count, prod3_count, prod4_count;

    // ���� ���Ž� �ݾ� ��ȭ�� always��
    always @(negedge rst, posedge clk) begin
        if (!rst) begin
            // ���� ���� �ʱ�ȭ
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
                // move up ��ư�� ������ ��� Ŀ�� ��ġ�� �� ĭ ���� �̵�
                if (move_up_sw) begin
                    if (cursor_pos > cursor_upper_limit) begin
                        cursor_pos = cursor_pos - 1;
                        ddram_address = 7'hd;
                    end
                end
                // move down ��ư�� ������ ��� Ŀ�� ��ġ�� �� ĭ �Ʒ��� �̵�
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
            // ���� ��ư�� ������ ���
            else if (select_toggle_sw) begin
                // ������ ������ id�� cursor ��ġ�� + 1�� �� ������ ������
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
            // ���� �Է� ����ġ�� ������ ��
            else if (coin_sw != 0) begin
                // ��ư ����ġ�� ���� inserted_money�� �ݾ��� ����
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
                // �� �Է� �ݾ� ���縦 �� ĭ�� �ڷ� �а�, 
                // ���� �ֱ� �Է� �ݾ��� �߰��� ���� �迭 ���� �տ� ����
                total_money_history[7*8-1:0] = total_money_history[7*9-1:7*1];
                total_money_history[7*9-1:7*8] = total_money_history[7*8-1:7*7] + inserted_money;
                // ǥ�õǴ� ���� ���Ե� ������ ����
                display_money_binary = inserted_money;
                // ���� �Է� state Ȱ��ȭ
                coin_btn_state = 1;
            end
            // ���� ����ġ�� ������ ��
            else if (buy_sw) begin
                // ���� ������ ��ǰ�� ����
                case (selected_item)
                    prod1_id: begin
                        // ��ī�ݶ��� ������ 0���� ũ�� �� �ݾ��� ��ī�ݶ��� ���ݺ��� ũ��
                        if (prod1_count > 0 && total_money_history[7*9-1:7*8] > prod1_price) begin
                            // ��ī�ݶ��� ������ �ϳ� ���̰�
                            prod1_count = prod1_count - 1;
                            // ��ī�ݶ��� ���ݸ�ŭ �� �ݾ��� ���δ�
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
                    // �� �ݾ� ���縦 ���� �ֱ� ���縦 �����ϰ� ���� �ʱ�ȭ
                    total_money_history[7*8-1:7*0] = 0;
                    // ���� �ʱ�ȭ ���� Ȱ��ȭ
                    history_disabled = 1;
                    // ������ ��ǰ�� ���� ���θ� �ʱ�ȭ
                    selected_item = 0;
                    selected = 0;
                end
                // ǥ�õǴ� ���� �� �ݾ� ������ ���� �ֱ� ������ ����
                display_money_binary = total_money_history[7*9-1:7*8];
            end
            else if (return_sw) begin
                // ǥ�õǴ� ���� �� �ݾ� ������ ���� �ֱ� ������ ����
                display_money_binary = total_money_history[7*9-1:7*8];
                // return state Ȱ��ȭ
                return_state = 1;
            end
            else if (prod_add_sw) begin
                if (admin_mode_state) begin
                    // ������ ����� ��쿡�� ��ǰ �߰� ����
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

            // fnd array�� ���� if�� ��

            // ���� �Է� ��ư�� �������� ��
            if (coin_btn_state) begin
                // ǥ�õ� cnt���� �Ѿ��� ��
                if (coin_btn_cnt >= coin_btn_cnt_limit) begin
                    coin_btn_cnt = 0;
                    coin_btn_state = 0;
                    // ǥ�õǴ� ���� �� �ݾ� ������ ���� �ֱ� ������ �ǵ��� ��
                    display_money_binary = total_money_history[7*9-1:7*8];
                end 
                else coin_btn_cnt = coin_btn_cnt + 1;
            end
            // ��ȯ ��ư�� �������� ��
            else if (return_state) begin
                if (return_cnt >= return_cnt_limit) begin
                    return_cnt = 0;
                    // ���� ���°� �ƴ� ��
                    if (!history_disabled) begin
                        // �� �ݾ� ���縦 �� �ܰ辿 ������ �ǵ��� ��
                        total_money_history[7*9-1:7*1] = total_money_history[7*8-1:7*0];
                        total_money_history[7*1-1:7*0] = 8'd0;
                        display_money_binary = total_money_history[7*9-1:7*8];
                        if (total_money_history == 0) return_state = 0;                 
                    end
                    else begin
                        // ���� ������ ��� �� �ݾ� ���� ���� �ֱ� �ݾ��� 1�� ����
                        // 100���� ��ȯ�Ǵ� ��� ����
                        if (total_money_history[7*9-1:7*8] != 0) begin
                            total_money_history[7*9-1:7*8] = total_money_history[7*9-1:7*8] - 1;
                            display_money_binary = total_money_history[7*9-1:7*8];
                        end
                        else begin
                            // �� �ݾ��� 0���� ���� �� return state ��ȿȭ
                            return_state = 0;
                            history_disabled = 0;
                        end
                    end
                end
                else return_cnt = return_cnt + 1;
            end

            // piezo�� ���� if��
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

            // lcd�� ���� if��
            if (warning_state != 0) begin
                if (warning_cnt > warning_cnt_limit) begin
                    warning_cnt = 0;
                    warning_state = 0;
                    warning_prod_id = 0;
                end
                else warning_cnt = warning_cnt + 1;
            end
            
            // lcd�� ���� case��
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
                            // ������ ����� ��쿡�� ���� ��ǰ�� ���� �����ֱ�,
                            // �ƴ� ��쿡�� ǰ�� ���θ� �����ֱ�
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
