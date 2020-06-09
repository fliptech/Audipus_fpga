`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/08/2020 05:49:37 PM
// Design Name: 
// Module Name: ClockGeneration
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


module ClockGeneration(
    input   reset_n,
    input   main_clk,
    output  sys_clk,
    output  i2s_sclk,
    output  locked
);

wire pll_clk;

BUFG BUFG_inst(
    .I  (main_clk),
    .O  (pll_clk)
);

main_clk_gen instance_name (
    // Status and control signals
    .resetn         (reset_n), // input resetn
    .locked         (pll_locked),       // output locked
   // Clock in ports
    .clk_in1        (pll_clk),      // input clk_in1
    // Clock out ports
    .clk_out1       (sys_clk),     // output clk_out1
    .clk_out2       (i2s_sclk)     // output clk_out2
);


endmodule
