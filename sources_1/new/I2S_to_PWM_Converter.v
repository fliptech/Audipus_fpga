`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2020 03:53:06 PM
// Design Name: 
// Module Name: I2S_to_PWM_Converter
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


module I2S_to_PWM_Converter(
    input clk,
    input reset_n,
    input sclk,
    input bclk,
    input lrclk,
    input s_data,
    output reg data_en,
    output reg [23:0] l_data,
    output reg [23:0] r_data
);


always @ (posedge clk) begin
    if(b_clken) begin
        if (lrclk) begin
            l_data[0] <= s_data;
            l_data[23:1] <= l_data[22:0];
        end
        else begin
            r_data[0] <= s_data;
            r_data[23:1] <= r_data[22:0];
        end
    end
    else begin
        l_data <= l_data;
        r_data <= r_data;
    end
end

endmodule
