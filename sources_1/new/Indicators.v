`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/02/2020 05:19:06 PM
// Design Name: 
// Module Name: Indicators
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


module Indicators(
    input clk,
    output reg [3:0] led
);

reg [23:0]  led_counter;

always @ (posedge clk) begin
    if (led_counter == 0) begin
        led_counter <= 24'hffffff;
        if (led[3] == led[0]) begin
            led[0] <= !led[0];
            led[1] <= led[0];
            led[2] <= led[0];
            led[3] <= led[0];
        end
        else begin    
            led[0] <= led[0];
            led[3:1] <= led[2:0];
        end
    end
    else begin
        led_counter <= led_counter - 1;
        led <= led;
    end
end

    


endmodule
