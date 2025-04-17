`timescale 1ns / 1ps

module gfx (
    input wire clk,
    input wire rst,
    input wire signed [15:0] i_x,
    input wire signed [15:0] i_y,
    input wire i_v_sync,
    input wire [2:0] i_btn,
    output reg [7:0] o_red,
    output reg [7:0] o_green,
    output reg [7:0] o_blue
    );
    
    // Write your code for the step 2 ~ 4
    
//    wire fractal_hit;
    wire [7:0] fractal_red;
    wire [7:0] fractal_green;
    wire [7:0] fractal_blue;
    
    BRAM_julia #(
    .H_RES(1280),
    .V_RES(720)
    )
    BRAM_julia_inst(
    //input
    .clk(clk),
    .rst(rst),
    .sx(i_x),
    .sy(i_y),
    .btn(i_btn),
    
    //output
    .o_red(fractal_red),
    .o_green(fractal_green),
    .o_blue(fractal_blue)
    );
    
    always@(*) begin
        o_red <= fractal_red;
        o_green <= fractal_green;
        o_blue <= fractal_blue;
    end
    
endmodule
