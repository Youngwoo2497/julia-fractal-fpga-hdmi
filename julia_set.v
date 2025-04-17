`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/03 22:13:07
// Design Name: 
// Module Name: julia_set
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


module BRAM_julia#(
    H_RES = 1280,
    V_RES = 720
    )(
    input wire clk,
    input wire rst,
    input wire [15:0] sx,
    input wire [15:0] sy,
    input wire [2:0] btn,
    
    output wire [7:0] o_red,
    output wire [7:0] o_green,
    output wire [7:0] o_blue
    );
    
    // FSM chapter ����, button edge�� �����ϱ� ���� reg, wire
    wire [2:0] push;        // assign���� btn�� ����
    reg [2:0] push_reg;     // clk ������ btn�� ����
    wire [2:0] push_button; // btn�� edge�� ����
    
    assign push = ~btn;
    assign push_button[0] = push[0] & ~push_reg[0];
    assign push_button[1] = push[1] & ~push_reg[1];
    assign push_button[2] = push[2] & ~push_reg[2];
    
    wire ready;             // julia set calculate �Ϸ�, ��ǥ�� �̵��ص� ��
    wire [8:0] iter;   // iteration Ƚ�� (0~256)
    
    reg signed [19:0] x_lcd = 0;
    reg signed [19:0] y_lcd = 0;        // LCD�� ��ǥ (0,0)~(1279,719), read address �� ����
    reg signed [31:0] x_com;
    wire signed [31:0] y_com;         // ��������� ��ǥ (-4.00, -2.25)~(+4.00, +2.25), julia set �� input���� ����
    reg signed [31:0] y_com_reverse;
    
    
    ///////////////////////////////////////////////////////////////////////////
    // [1] Julia set insatnce module import
    // input : clk, rst, c_change(btn[0]), x_com, y_com
    // output: ready, fin_iter(iter)
    // LCD ��ǥ���� ȯ���� ��������� ��ǥ(�ļ�)�� �Է��ϸ�,
    // �ش� ��ǥ���� julia set ��� �� iteration Ƚ���� ��ȯ�Ѵ�.
    // ready ��ȣ�� ��ȯ�Ͽ� BRAM write timing��, LCD ��ǥ ���� timing�� �����Ѵ�.
    ///////////////////////////////////////////////////////////////////////////
    
    julia_set julia_inst (
        .clk(clk),
        .rst(rst),
        .c_change(push_button[0]),
        .x_com(x_com),
        .y_com(y_com),
        
        .ready(ready),
        .fin_iter(iter)
    );
    
    ///////////////////////////////////////////////////////////////////////////
    // [2] BRAM instance module import
    // write: clk, ena, wea, addra(20bit), dina(4bit), douta(4bit)
    // read: clk, enb, web, addrb(20bit), dinb(4bit), doutb(4bit)
    // julia ��⿡�� ��ȯ�� ready ��ȣ�� ���� write�� �����Ѵ�.
    // read timing�� ��� �����ϵ��� �����Ѵ�.
    // data�� address ������ ���ؼ��� �ļ�.
    ///////////////////////////////////////////////////////////////////////////
    
    reg signed [19:0] addr_write;
    reg [3:0] data_write; wire [3:0] data_read;
    wire [19:0] addr_read;
    
    blk_mem_gen_0 inst_0(
        .clka(clk),
        .ena(ready),
        .wea(1'b1),
        .addra(addr_write),
        .dina(data_write),
        .douta(),
        
        .clkb(clk),
        .enb(1'b1),
        .web(1'b0),
        .addrb(addr_read),
        .dinb(4'd0),
        .doutb(data_read)
    );
    
    ///////////////////////////////////////////////////////////////////////////
    // [3] zoom state, write data ���� (����: clk)
    // [3-1] 4���� state�� ���� (FSM ����) ��������� �Ǽ�, ��� ���� ���� ([5]�� �̾���)
    // [3-2] iteration Ƚ���� ���� write�� data(8bit)�� 16�ܰ�(4bit)�� ����
    ///////////////////////////////////////////////////////////////////////////
    reg [31:0] real_min, real_max; reg [31:0] imag_min, imag_max;
    
    // Z1 state �� ��� : �⺻ ������ �Ǽ�(-4.00~4.00), ���(-2.25~2.25) ����
    localparam real_min_1 = 32'hfffc_0000; localparam real_max_1 = 32'h0004_0000;   // -4.00~4.00
    localparam imag_min_1 = 32'hfffd_c000; localparam imag_max_1 = 32'h0002_4000;     // -2.25~2.25
    // Z2 state �� ��� : x2 ���� �Ǽ�(-2.00~2.00), ���(-1.125~1.125) ����
    localparam real_min_2 = 32'hfffe_0000; localparam real_max_2 = 32'h0002_0000;   // -2.00~2.00
    localparam imag_min_2 = 32'hfffe_e000; localparam imag_max_2 = 32'h0001_2000;     // -1.125~1.125
    // Z3 state �� ��� : x4 ���� �Ǽ�(-1.00~1.00), ���(-0.5625~0.5625) ����
    localparam real_min_3 = 32'hffff_0000; localparam real_max_3 = 32'h0001_0000;   // -1.00~1.00
    localparam imag_min_3 = 32'hffff_7000; localparam imag_max_3 = 32'h0000_9000;     // -0.5625~0.5625
    // Z4 state �� ��� : x8 ���� �Ǽ�(-0.5~0.5), ���(-0.28125~0.28125) ����
    localparam real_min_4 = 32'hffff_8000; localparam real_max_4 = 32'h0000_8000;   // -0.5~0.5
    localparam imag_min_4 = 32'hffff_b800; localparam imag_max_4 = 32'h0000_4800;     // -0.28125~0.28125
    
    // gray scale�� ��� : 8bit�� data 16�ܰ踦 ����
    localparam GRAY_0 = 8'd0; localparam GRAY_1 = 8'd17;  localparam GRAY_2 = 8'd34;  localparam GRAY_3 = 8'd51;
    localparam GRAY_4 = 8'd68; localparam GRAY_5 = 8'd85;  localparam GRAY_6 = 8'd102;  localparam GRAY_7 = 8'd119;
    localparam GRAY_8 = 8'd136; localparam GRAY_9 = 8'd153;  localparam GRAY_10 = 8'd170;  localparam GRAY_11 = 8'd187;
    localparam GRAY_12 = 8'd204; localparam GRAY_13 = 8'd221;  localparam GRAY_14 = 8'd238;  localparam GRAY_15 = 8'd255;

    
    // btn[2], btn[3] �Է¿� ���� �����Ǵ� �Ǽ�, ��� ������ �����ϴ� state
    localparam Z1 = 2'b00; localparam Z2 = 2'b01; localparam Z3 = 2'b10; localparam Z4 = 2'b11;
    reg [1:0] zoom_state = Z1;  // �⺻ state�� Z1
    
    reg wait_state = 1'b0;  // clk signal Ÿ�̹��� ���߱� ����, waiting�ϴ� state
    
    always @(posedge clk) begin
        push_reg <= push;   // clk ������ btn�� ������, button edge �νĿ� ����
        
        // �Է� button �� ���� zoom state �� �����ϴ� FSM
        if (push_button == 3'b010) begin    //zoom in
            case (zoom_state)
                Z1: zoom_state <= Z2;
                Z2: zoom_state <= Z3;
                Z3: zoom_state <= Z4;
                Z4: zoom_state <= Z4;
                default: zoom_state <= zoom_state;
            endcase
        end
        if (push_button == 3'b100) begin    //zoom out
            case (zoom_state)
                Z1: zoom_state <= Z1;
                Z2: zoom_state <= Z1;
                Z3: zoom_state <= Z2;
                Z4: zoom_state <= Z3;
                default: zoom_state <= zoom_state;
            endcase
        end
        
        // julia set�� ���, iteration Ƚ���� ���� data_write�� ����
        if (iter < 16) begin data_write <= 4'd0; end
        else if (iter < 32) begin data_write <= 4'd1; end
        else if (iter < 48) begin data_write <= 4'd2; end
        else if (iter < 64) begin data_write <= 4'd3; end
        else if (iter < 80) begin data_write <= 4'd4; end
        else if (iter < 96) begin data_write <= 4'd5; end
        else if (iter < 112) begin data_write <= 4'd6; end
        else if (iter < 128) begin data_write <= 4'd7; end
        else if (iter < 144) begin data_write <= 4'd8; end
        else if (iter < 160) begin data_write <= 4'd9; end
        else if (iter < 176) begin data_write <= 4'd10; end
        else if (iter < 192) begin data_write <= 4'd11; end
        else if (iter < 208) begin data_write <= 4'd12; end
        else if (iter < 224) begin data_write <= 4'd13; end
        else if (iter < 240) begin data_write <= 4'd14; end
        else if (iter < 257) begin data_write <= 4'd15; end

        // data write�� ����Ǵ� ���� wait_state�� ������ �� clk �����
        if (ready) wait_state <= 1'b1;
        if (wait_state) begin
            wait_state <= 1'b0; x_lcd <= x_lcd + 20'b1;
            if (x_lcd == 20'd1280) begin x_lcd <= 20'b0; y_lcd <= y_lcd + 20'd1; end
            if (y_lcd == 20'd720) begin x_lcd <= 20'd0; y_lcd <= 20'd0; end
        end
    end
    
    ///////////////////////////////////////////////////////////////////////////
    // [4] BRAM address ���� (����: * (always))
    // write address : LCD ��ǥ�� �ش��ϴ� x_lcd, y_lcd�� ���
    // y_lcd�� ���, ���Ϲ����� ��Ű�� ���� y_com_reverse�� mul ����� �̿��� -1��ŭ ����
    // (LCD ��ǥ�� ready ��ȣ�� Ȱ��ȭ�� ������ 1�� �����Ѵ�. �� �ļ�)
    // read address : input���� �޴� sx, sy�� ���
    ///////////////////////////////////////////////////////////////////////////
    wire [19:0] px, py;
    
    always @(*)
    begin
        x_com = real_min + ((x_lcd * (real_max - real_min)) / (H_RES - 1));
        y_com_reverse = imag_min + ((y_lcd * (imag_max - imag_min)) / (V_RES - 1));
        addr_write = x_lcd + y_lcd * 20'd1280;
    end
    
    // y_com = y_com_reverse * (-1)
    mul mul_inst_reverse (
        .a(32'hffff0000),  // -1
        .b(y_com_reverse),
        .val(y_com)
    );
    
    assign px = {4'b000, sx}; assign py = {4'b000, sy};
    assign addr_read = px + py * 20'd1280;
    
    ///////////////////////////////////////////////////////////////////////////
    // [5] zoom state, RGB value output ���� (����: * (always))
    // zoom state: [3]���� ������ zoom_state�� ���� �ǽð����� �Ǽ�, ��� ������ �����Ѵ�.
    // RGB value: [3]���� ������ data�� ����, read data�� �̿� �ش��ϸ� 
    //              gray scale�� �ǽð����� output���� �����Ѵ�.
    ///////////////////////////////////////////////////////////////////////////
     reg [7:0] temp_gray;
    
    always @(*) begin
        case(zoom_state)
            Z1: begin 
                real_min <= real_min_1; real_max <= real_max_1;
                imag_min <= imag_min_1; imag_max <= imag_max_1;
                end
            Z2: begin 
                real_min <= real_min_2; real_max <= real_max_2;
                imag_min <= imag_min_2; imag_max <= imag_max_2;
                end
            Z3: begin 
                real_min <= real_min_3; real_max <= real_max_3;
                imag_min <= imag_min_3; imag_max <= imag_max_3;
                end
            Z4: begin 
                real_min <= real_min_4; real_max <= real_max_4;
                imag_min <= imag_min_4; imag_max <= imag_max_4;
                end
        endcase
        
        case(data_read)
        // data read�� ����, 16�ܰ��� gray scale�� temp_gray�� ����
        // temp_gray�� �� RGB siganl�� �����
            4'd0: temp_gray <= GRAY_0;
            4'd1: temp_gray <= GRAY_1;
            4'd2: temp_gray <= GRAY_2;
            4'd3: temp_gray <= GRAY_3;
            4'd4: temp_gray <= GRAY_4;
            4'd5: temp_gray <= GRAY_5;
            4'd6: temp_gray <= GRAY_6;
            4'd7: temp_gray <= GRAY_7;
            4'd8: temp_gray <= GRAY_8;
            4'd9: temp_gray <= GRAY_9;
            4'd10: temp_gray <= GRAY_10;
            4'd11: temp_gray <= GRAY_11;
            4'd12: temp_gray <= GRAY_12;
            4'd13: temp_gray <= GRAY_13;
            4'd14: temp_gray <= GRAY_14;
            4'd15: temp_gray <= GRAY_15;
        endcase
    end
    
    assign o_red = temp_gray;
    assign o_green = temp_gray;
    assign o_blue = temp_gray;
    
endmodule
