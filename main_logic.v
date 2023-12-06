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
    input admin_mode,
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
    // generate���� ����
    genvar i;

    // ----------------���� �� �ٲ�� ������----------------
    // ���� ���� 2000000���� �����ؾ� ��
    // parameter coin_btn_cnt_limit = 20;
    parameter coin_btn_cnt_limit = 2000000;
    
    // ���� ���� 1000000���� �����ؾ� ��
    // parameter return_cnt_limit = 10;
    parameter return_cnt_limit = 1000000;

    // note_played���¸� �ٲ� ����
    // ���� ���� ���� 100000, 200000, 300000, 400000
    // parameter note_1_limit = 5;
    // parameter note_2_limit = 10;
    // parameter note_3_limit = 15;
    // parameter note_4_limit = 20;
    parameter note_1_limit = 100000;
    parameter note_2_limit = 200000;
    parameter note_3_limit = 300000;
    parameter note_4_limit = 400000;

    // --------------����ġ�� ��ư ������ �Ҵ�---------------
    // Ŀ�� �̵� ��ư
    wire move_up_sw, move_down_sw;
    assign move_up_sw = button_sw_oneshot[10];
    assign move_down_sw = button_sw_oneshot[4];

    // ���� ��ư
    wire select_toggle_sw;
    assign select_toggle_sw = button_sw_oneshot[7];

    // ���� �Է�, ��ǰ �߰� ����ġ
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

    // ----------------parameter ������----------------
    // �� ��ǰ id
    parameter prod1_id = 1;
    parameter prod2_id = 2;
    parameter prod3_id = 3;

    // �� ��ǰ ����
    parameter prod1_price = 10;
    parameter prod2_price = 12;
    parameter prod3_price = 15;

    // ��ǰ ����
    parameter prod_limit = 9;

    // �� ��ǰ �ʱ� ����
    parameter prod1_init_count = 5;
    parameter prod2_init_count = 1;
    parameter prod3_init_count = 0;

    // ��Ʈ state
    parameter note_100w = 1;
    parameter note_500w = 2;
    parameter note_1000w = 3;
    parameter note_prod1 = 4;
    parameter note_prod2 = 5;
    parameter note_prod3 = 6;

    parameter [8*2*3-1:0] prod_num = {
        // "1."
        8'h31, 8'h2e, 
        // "2."
        8'h32, 8'h2e, 
        // "3."
        8'h33, 8'h2e
    };

    // ��ǰ���� �����ϴ� ����. �ִ� 5����, 3���� ��ǰ���� ����
    parameter [8*7*3-1:0] product = {
        // "Coke "
        8'h43, 8'h6f, 8'h6b, 8'h65, 8'h20,
        // "Water"
        8'h57, 8'h61, 8'h74, 8'h65, 8'h72,
        // "Juice"
        8'h4a, 8'h75, 8'h69, 8'h63, 8'h65
        };

    // ������ ���ڷ� �ٲ㼭 �����ϴ� ����
    // 100�� ������ ������ �����ϱ� ������ 100���� ���� ���� ����
    // ���� 2���ڸ� ������ ��
    parameter [8*2*3-1:0] price_text = {
        8'h31, 8'h30, // "10"
        8'h31, 8'h32, // "12"
        8'h31, 8'h35  // "15"
        };
    
    // ----------------reg ������----------------
    // ���� �Է��� �ݾ��� �����ֱ� ���� cnt
    integer coin_btn_cnt;
    // �ݾ� ��ȯ�� �ݾ��� �����ֱ� ���� cnt
    integer return_cnt;
    // note_played ���¸� �ٲٱ� ���� cnt
    integer note_cnt;

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

    // ���� lcd�� ǥ�õ� ��ǰ�� ǥ���ϴ� ����
    reg [2:0] line1_prod, line2_prod;
    // ���� ��ǰ ����
    reg [3:0] prod1_count, prod2_count, prod3_count;

    // ���� ���Ž� �ݾ� ��ȭ�� always��
    always @(negedge rst, posedge clk) begin
        if (!rst) begin
            // ���� ���� �ʱ�ȭ
            selected_item <= 0; cursor_pos <= 0; selected <= 0;
            inserted_money <= 0; total_money_history <= 0;
            history_disabled <= 0; display_money_binary <= 0;
            prod_count_current <= 0;
            prod1_count <= prod1_init_count;
            prod2_count <= prod2_init_count;
            prod3_count <= prod3_init_count;
            coin_btn_state <= 0; return_state <= 0; 
            note_state <= 0; note_played <= 0;
            coin_btn_cnt <= 0; return_cnt <= 0; note_cnt <= 0;
            line1_text <= 0; line2_text <= 0; ddram_address <= 7'hd;
            // "1.Coke  1000W  ^"
            line1_text[8*16-1:8*9] <= product[8*7*3-1:8*7*2]; // "1.Coke "
            line1_text[8*9-1:8*8] <= 8'h20; // space
            line1_text[8*8-1:8*6] <= price_text[8*2*3-1:8*2*2]; // "10"
            line1_text[8*6-1:8*0] <= {8'h30, 8'h30, 8'h57, 8'h20, 8'h20, 8'h5e}; // "00W  ^"
            // "2.Water 1200W  v"
            line2_text[8*16-1:8*9] <= product[8*7*2-1:8*7*1]; // "2.Water"
            line2_text[8*9-1:8*8] <= 8'h20; // space
            line2_text[8*8-1:8*6] <= price_text[8*2*2-1:8*2*1]; // "12"
            line2_text[8*6-1:8*0] <= {8'h30, 8'h30, 8'h57, 8'h20, 8'h20, 8'h76}; // "00W  v"
        end
        else begin
            if (move_up_sw || move_down_sw) begin
                // move up ��ư�� ������ ��� Ŀ�� ��ġ�� �� ĭ ���� �̵�
                if (move_up_sw) begin
                    if (cursor_pos > 0) begin
                        cursor_pos = cursor_pos - 1;
                        ddram_address = 7'hd;
                    end
                end
                // move down ��ư�� ������ ��� Ŀ�� ��ġ�� �� ĭ �Ʒ��� �̵�
                else if (move_down_sw) begin
                    if (cursor_pos < 2) begin
                        cursor_pos = cursor_pos + 1;
                        ddram_address = 7'h4d;
                    end
                end
                case (cursor_pos)
                    0 : prod_count_current = prod1_count;
                    1 : prod_count_current = prod2_count;
                    2 : prod_count_current = prod3_count;
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
                                selected = 1;
                            end 
                        end
                        1 : begin
                            if (prod2_count != 0) begin
                                selected_item = prod2_id;
                                note_state = note_prod2;
                                selected = 1;
                            end 
                        end
                        2 : begin
                            if (prod3_count != 0) begin
                                selected_item = prod3_id;
                                note_state = note_prod3;
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
                            // �� �ݾ� ���縦 ���� �ֱ� ���縦 �����ϰ� ���� �ʱ�ȭ
                            total_money_history[7*8-1:7*0] = 0;
                            // ���� �ʱ�ȭ ���� Ȱ��ȭ
                            history_disabled = 1;
                            // ������ ��ǰ�� ���� ���θ� �ʱ�ȭ
                            selected_item = 0;
                            selected = 0;
                        end
                    end
                    prod2_id: begin
                        if (prod2_count > 0 && total_money_history[7*9-1:7*8] > prod2_price) begin
                            prod2_count = prod2_count - 1;
                            total_money_history[7*9-1:7*8] = total_money_history[7*9-1:7*8] - prod2_price;
                            total_money_history[7*8-1:7*0] = 0;
                            history_disabled = 1;
                            selected_item = 0;
                            selected = 0;
                        end
                    end
                    prod3_id: begin
                        if (prod3_count > 0 && total_money_history[7*9-1:7*8] > prod3_price) begin
                            prod3_count = prod3_count - 1;
                            total_money_history[7*9-1:7*8] = total_money_history[7*9-1:7*8] - prod3_price;
                            total_money_history[7*8-1:7*0] = 0;
                            history_disabled = 1;
                            selected_item = 0;
                            selected = 0;
                        end
                    end
                endcase
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
                if (admin_mode) begin
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
                    endcase
                end
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
            
            // lcd�� ���� case��
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
                    // prod 2, prod 3
                    line1_prod = prod2_id;
                    line2_prod = prod3_id;
                end
                default : begin
                    // prod 1, prod 2
                    line1_prod = prod1_id;
                    line2_prod = prod2_id;
                end
            endcase

            case (line1_prod)
                1 : begin
                    line1_text[8*16-1:8*14] = prod_num[8*2*3-1:8*2*2]; 
                    line1_text[8*14-1:8*9] = product[8*7*3-1:8*7*2];
                    line1_text[8*8-1:8*6] = price_text[8*2*3-1:8*2*2];
                    // ������ ����� ��쿡�� ���� ��ǰ�� ���� �����ֱ�,
                    // �ƴ� ��쿡�� ǰ�� ���θ� �����ֱ�
                    if (admin_mode) line1_text[8*2-1:8*1] = 8'h30 + prod1_count;
                    else begin
                        if (prod1_count == 0) line1_text[8*2-1:8*1] = 8'h58; // "X"
                        else line1_text[8*2-1:8*1] = 8'h20; // "space" 
                    end

                    if (line1_prod == selected_item) line1_text[8*3-1:8*2] = 8'h2a; // "*"
                    else line1_text[8*3-1:8*2] = 8'h20; // space
                end
                2 : begin
                    line1_text[8*16-1:8*14] = prod_num[8*2*2-1:8*2*1]; 
                    line1_text[8*14-1:8*9] = product[8*7*2-1:8*7*1];
                    line1_text[8*8-1:8*6] = price_text[8*2*2-1:8*2*1];
                    if (admin_mode) line1_text[8*2-1:8*1] = 8'h30 + prod2_count;
                    else begin
                        if (prod2_count == 0) line1_text[8*2-1:8*1] = 8'h58; // "X"
                        else line1_text[8*2-1:8*1] = 8'h20; // "space"
                    end

                    if (line1_prod == selected_item) line1_text[8*3-1:8*2] = 8'h2a; // "*"
                    else line1_text[8*3-1:8*2] = 8'h20; // space
                end
                3 : begin
                    line1_text[8*16-1:8*14] = prod_num[8*2*1-1:8*2*0];
                    line1_text[8*14-1:8*9] = product[8*7*1-1:8*7*0];
                    line1_text[8*8-1:8*6] = price_text[8*2*1-1:8*2*0];
                    if (admin_mode) line1_text[8*2-1:8*1] = 8'h30 + prod3_count;
                    else begin
                        if (prod3_count == 0) line1_text[8*2-1:8*1] = 8'h58; // "X"
                        else line1_text[8*2-1:8*1] = 8'h20; // "space"
                    end

                    if (line1_prod == selected_item) line1_text[8*3-1:8*2] = 8'h2a; // "*"
                    else line1_text[8*3-1:8*2] = 8'h20; // space
                end
                default : begin
                    line1_text[8*16-1:8*14] = prod_num[8*2*2-1:8*2*1];
                    line1_text[8*14-1:8*9] = product[8*7*3-1:8*7*2];
                    line1_text[8*3-1:8*2] = 8'h20; // "space"
                    line1_text[8*2-1:8*1] = 8'h20; // "space"
                end
            endcase

            case (line2_prod)
                1 : begin
                    line2_text[8*16-1:8*14] = prod_num[8*2*3-1:8*2*2];
                    line2_text[8*14-1:8*9] = product[8*7*3-1:8*7*2];
                    line2_text[8*8-1:8*6] = price_text[8*2*3-1:8*2*2];
                    if (admin_mode) line2_text[8*2-1:8*1] = 8'h30 + prod1_count;
                    else begin
                        if (prod1_count == 0) line2_text[8*2-1:8*1] = 8'h58; // "X"
                        else line2_text[8*2-1:8*1] = 8'h20; // "space"
                    end
                
                    if (line2_prod == selected_item) line2_text[8*3-1:8*2] = 8'h2a; // "*"
                    else line2_text[8*3-1:8*2] = 8'h20; // space
                end
                2 : begin
                    line2_text[8*16-1:8*14] = prod_num[8*2*2-1:8*2*1];
                    line2_text[8*14-1:8*9] = product[8*7*2-1:8*7*1];
                    line2_text[8*8-1:8*6] = price_text[8*2*2-1:8*2*1];
                    if (admin_mode) line2_text[8*2-1:8*1] = 8'h30 + prod2_count;
                    else begin
                        if (prod2_count == 0) line2_text[8*2-1:8*1] = 8'h58; // "X"
                        else line2_text[8*2-1:8*1] = 8'h20; // "space"
                    end

                    if (line2_prod == selected_item) line2_text[8*3-1:8*2] = 8'h2a; // "*"
                    else line2_text[8*3-1:8*2] = 8'h20; // space
                end
                3 : begin
                    line2_text[8*16-1:8*14] = prod_num[8*2*1-1:8*2*0];
                    line2_text[8*14-1:8*9] = product[8*7*1-1:8*7*0];
                    line2_text[8*8-1:8*6] = price_text[8*2*1-1:8*2*0];
                    if (admin_mode) line2_text[8*2-1:8*1] = 8'h30 + prod3_count;
                    else begin
                        if (prod3_count == 0) line2_text[8*2-1:8*1] = 8'h58; // "X"
                        else line2_text[8*2-1:8*1] = 8'h20; // "space"
                    end

                    if (line2_prod == selected_item) line2_text[8*3-1:8*2] = 8'h2a; // "*"
                    else line2_text[8*3-1:8*2] = 8'h20; // space
                end
                default : begin
                    line2_text[8*16-1:8*9] = product[8*7*2-1:8*7*1];
                    line2_text[8*3-1:8*2] = 8'h20; // "space"
                    line2_text[8*2-1:8*1] = 8'h20; // "space"
                end
            endcase
        end
    end
endmodule
