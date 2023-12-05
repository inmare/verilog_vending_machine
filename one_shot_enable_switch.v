`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/11/09 11:49:03
// Design Name: 
// Module Name: enable_switch
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


module one_shot_en_sw(
    input clk, enable,
    output reg eout
    );

    reg enable_prev;
    
    always @(posedge clk) begin
        if (enable && !enable_prev) eout <= 1;
        else eout <= 0;

        enable_prev <= enable;
    end
endmodule
