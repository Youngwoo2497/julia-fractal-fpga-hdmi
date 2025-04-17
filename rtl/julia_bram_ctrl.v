`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/03 22:13:07
// Design Name: 
// Module Name: BRAM_julia
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


module julia_bram_ctrl#(
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
    
    // FSM chapter 참조, button edge를 구현하기 위한 reg, wire
    wire [2:0] push;        // assign으로 btn과 연동
    reg [2:0] push_reg;     // clk 단위로 btn과 연동
    wire [2:0] push_button; // btn의 edge를 감지
    
    assign push = ~btn;
    assign push_button[0] = push[0] & ~push_reg[0];
    assign push_button[1] = push[1] & ~push_reg[1];
    assign push_button[2] = push[2] & ~push_reg[2];
    
    wire ready;             // julia set calculate 완료, 좌표를 이동해도 됨
    wire [8:0] iter;   // iteration 횟수 (0~256)
    
    reg signed [19:0] x_lcd = 0;
    reg signed [19:0] y_lcd = 0;        // LCD의 좌표 (0,0)~(1279,719), read address 로 연결
    reg signed [31:0] x_com;
    wire signed [31:0] y_com;         // 복소평면의 좌표 (-4.00, -2.25)~(+4.00, +2.25), julia set 의 input으로 연결
    reg signed [31:0] y_com_reverse;
    
    
    ///////////////////////////////////////////////////////////////////////////
    // [1] Julia set insatnce module import
    // input : clk, rst, c_change(btn[0]), x_com, y_com
    // output: ready, fin_iter(iter)
    // LCD 좌표에서 환산한 복소평면의 좌표(후술)를 입력하면,
    // 해당 좌표에서 julia set 계산 후 iteration 횟수를 반환한다.
    // ready 신호를 반환하여 BRAM write timing과, LCD 좌표 변경 timing을 제어한다.
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
    // julia 모듈에서 반환한 ready 신호에 맞춰 write를 진행한다.
    // read timing은 상시 가능하도록 설정한다.
    // data와 address 설정에 관해서는 후술.
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
    // [3] zoom state, write data 설정 (단위: clk)
    // [3-1] 4개의 state에 따라 (FSM 참조) 복소평면의 실수, 허수 범위 조절 ([5]에 이어짐)
    // [3-2] iteration 횟수에 따라 write할 data(8bit)를 16단계(4bit)로 지정
    ///////////////////////////////////////////////////////////////////////////
    reg [31:0] real_min, real_max; reg [31:0] imag_min, imag_max;
    
    // Z1 state 의 상수 : 기본 배율의 실수(-4.00~4.00), 허수(-2.25~2.25) 범위
    localparam real_min_1 = 32'hfffc_0000; localparam real_max_1 = 32'h0004_0000;   // -4.00~4.00
    localparam imag_min_1 = 32'hfffd_c000; localparam imag_max_1 = 32'h0002_4000;     // -2.25~2.25
    // Z2 state 의 상수 : x2 배율 실수(-2.00~2.00), 허수(-1.125~1.125) 범위
    localparam real_min_2 = 32'hfffe_0000; localparam real_max_2 = 32'h0002_0000;   // -2.00~2.00
    localparam imag_min_2 = 32'hfffe_e000; localparam imag_max_2 = 32'h0001_2000;     // -1.125~1.125
    // Z3 state 의 상수 : x4 배율 실수(-1.00~1.00), 허수(-0.5625~0.5625) 범위
    localparam real_min_3 = 32'hffff_0000; localparam real_max_3 = 32'h0001_0000;   // -1.00~1.00
    localparam imag_min_3 = 32'hffff_7000; localparam imag_max_3 = 32'h0000_9000;     // -0.5625~0.5625
    // Z4 state 의 상수 : x8 배율 실수(-0.5~0.5), 허수(-0.28125~0.28125) 범위
    localparam real_min_4 = 32'hffff_8000; localparam real_max_4 = 32'h0000_8000;   // -0.5~0.5
    localparam imag_min_4 = 32'hffff_b800; localparam imag_max_4 = 32'h0000_4800;     // -0.28125~0.28125
    
    // gray scale의 상수 : 8bit의 data 16단계를 지정
    localparam GRAY_0 = 8'd0; localparam GRAY_1 = 8'd17;  localparam GRAY_2 = 8'd34;  localparam GRAY_3 = 8'd51;
    localparam GRAY_4 = 8'd68; localparam GRAY_5 = 8'd85;  localparam GRAY_6 = 8'd102;  localparam GRAY_7 = 8'd119;
    localparam GRAY_8 = 8'd136; localparam GRAY_9 = 8'd153;  localparam GRAY_10 = 8'd170;  localparam GRAY_11 = 8'd187;
    localparam GRAY_12 = 8'd204; localparam GRAY_13 = 8'd221;  localparam GRAY_14 = 8'd238;  localparam GRAY_15 = 8'd255;

    
    // btn[2], btn[3] 입력에 따라 조절되는 실수, 허수 범위를 조절하는 state
    localparam Z1 = 2'b00; localparam Z2 = 2'b01; localparam Z3 = 2'b10; localparam Z4 = 2'b11;
    reg [1:0] zoom_state = Z1;  // 기본 state는 Z1
    
    reg wait_state = 1'b0;  // clk signal 타이밍을 맞추기 위해, waiting하는 state
    
    always @(posedge clk) begin
        push_reg <= push;   // clk 단위로 btn을 연동함, button edge 인식에 사용됨
        
        // 입력 button 에 따라 zoom state 를 조절하는 FSM
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
        
        // julia set의 결과, iteration 횟수에 따라 data_write를 결정
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

        // data write가 진행되는 동안 wait_state를 조절해 한 clk 쉬어가기
        if (ready) wait_state <= 1'b1;
        if (wait_state) begin
            wait_state <= 1'b0; x_lcd <= x_lcd + 20'b1;
            if (x_lcd == 20'd1280) begin x_lcd <= 20'b0; y_lcd <= y_lcd + 20'd1; end
            if (y_lcd == 20'd720) begin x_lcd <= 20'd0; y_lcd <= 20'd0; end
        end
    end
    
    ///////////////////////////////////////////////////////////////////////////
    // [4] BRAM address 설정 (단위: * (always))
    // write address : LCD 좌표에 해당하는 x_lcd, y_lcd로 계산
    // y_lcd의 경우, 상하반전을 시키기 위해 y_com_reverse와 mul 모듈을 이용해 -1만큼 곱함
    // (LCD 좌표는 ready 신호가 활성화될 때마다 1씩 증가한다. 에 후술)
    // read address : input으로 받는 sx, sy로 계산
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
    // [5] zoom state, RGB value output 설정 (단위: * (always))
    // zoom state: [3]에서 제어한 zoom_state에 따라 실시간으로 실수, 허수 범위를 조절한다.
    // RGB value: [3]에서 제어한 data에 따라, read data가 이에 해당하면 
    //              gray scale을 실시간으로 output으로 연결한다.
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
        // data read에 따라, 16단계의 gray scale을 temp_gray에 저장
        // temp_gray는 곧 RGB siganl와 연결됨
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
