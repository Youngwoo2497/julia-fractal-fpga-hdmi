`timescale 1ns / 1ps

module fixed_point_mul (
    input wire signed [31:0] a,   // multiplicand
    input wire signed [31:0] b,   // multiplier
    output reg signed [31:0] val  // multiplication result
    );
    
    // Write your code for the step 1
    
    reg signed [63:0] raw_result;
    
    always @(*) begin
        raw_result <= a * b;
            // multiplicand x multiplier
        val <= raw_result[47:16];
    end

endmodule
