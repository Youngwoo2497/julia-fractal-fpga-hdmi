`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/03 22:21:43
// Design Name: 
// Module Name: julia
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


// input���� ��������� zx, zy�� �ް�, julia ����� �����Ѵ�.
// z�� ũ�Ⱑ 2�� �ʰ��ϰų� �ݺ� Ƚ���� 256ȸ�� �ʰ��ϸ� ready ��ȣ�� Ȱ��ȭ�Ѵ�.
module julia_set(
    input wire clk,
    input wire rst,
    input wire c_change,
    input wire signed [31:0] x_com,
    input wire signed [31:0] y_com,
    
    output reg ready,
    output reg [8:0] fin_iter   // ���� iteration Ƚ��, 0~255
    );
    
    reg wait_state_ = 1'b0;
    
    reg [8:0] cur_iter;           // ���� iteration Ƚ��
    reg signed [31:0] zx, zy;     // ���� zx, xy ��꿡 ����
    reg signed [31:0] cx, cy;     // c_state�� ���� ������ c ���
    wire signed [31:0] mul_zx_2, mul_zy_2, mul_zxzy, mul_2_zxzy;
    
    localparam c1_x = 32'hffff_999a; localparam c1_y = 32'h0000_999a; // -0.4, 0.6
    localparam c2_x = 32'hffff_3333; localparam c2_y = 32'h0000_27f0; // -0.8, 0.156
    localparam c3_x = 32'hffff_45ea; localparam c3_y = 32'h0000_305c; // -0.7269, 0.1889
    
    initial begin
        ready <= 0; 
        fin_iter <= 0; cur_iter <= 0;
        zx <= x_com; zy <= y_com;
        cx <= c1_x; cy <= c1_y;
    end
    
    mul mul_inst1 (
        .a(zx),
        .b(zx),
        .val(mul_zx_2)
    );
    mul mul_inst2 (
        .a(zy),
        .b(zy),
        .val(mul_zy_2)
    );
    mul mul_inst3 (
        .a(zx),
        .b(zy),
        .val(mul_zxzy)
    );
    mul mul_inst4 (
        .a(32'h0002_0000),  // 2
        .b(mul_zxzy),
        .val(mul_2_zxzy)
    );    
    
    // c_change �� Ȱ��ȭ�Ǹ� reset�� ���ϰ� ��� �ʱ⺯���� ����� �ʱ�ȭ�Ѵ�.
    localparam C1 = 2'b00; localparam C2 = 2'b01; localparam C3 = 2'b10;
    reg [1:0] c_state = C1;
    
    always @(posedge c_change) begin
        case (c_state)
            C1: begin c_state <= C2; cx <= c2_x; cy <= c2_y; end
            C2: begin c_state <= C3; cx <= c3_x; cy <= c3_y; end
            C3: begin c_state <= C1; cx <= c1_x; cy <= c1_y; end
            default: begin c_state <= C1; cx <= c1_x; cy <= c1_y; end
        endcase
    end
    
    // �� clk����,
    // reset �� Ȱ��ȭ�Ǹ� ��� �ʱ⺯���� ����� �ʱ�ȭ�Ѵ�.
    // ready �� Ȱ��ȭ�Ǹ� reset�� ���ϰ� ��� �ʱ⺯���� ����� �ʱ�ȭ�Ѵ�.
    // �̿��� ���, iteration ����� �����ϰ�, ���� itertaion�� ready�� output���� ��ȯ�Ѵ�.
    always @(posedge clk or posedge rst) begin
        // [1] if, reset activated, initialize all signals
        if (rst) begin
            ready <= 0; 
            fin_iter <= 0; cur_iter <= 0;
            zx <= x_com; zy <= y_com;
        end
        
        // [2] if, reset activated, initialize all signals
        else if (ready) begin
            case (wait_state_)
                1'b0: begin wait_state_ <= 1'b1; end
                1'b1: begin 
                    wait_state_ <= 1'b0; 
                    ready <= 0;
                    fin_iter <= 0; cur_iter <= 0;
                    zx <= x_com; zy <= y_com;
                end
            endcase
        end
        
        // [3] else, calculate julia set
        else if ((cur_iter > 255) || (mul_zx_2 + mul_zy_2 > 32'h0004_0000)) begin
           ready <= 1;
           fin_iter <= cur_iter;
        end
        else begin
            zx <= mul_zx_2 - mul_zy_2 + cx;
            zy <= mul_2_zxzy + cy;
            cur_iter <= cur_iter + 1;
        end
    end
    
endmodule
