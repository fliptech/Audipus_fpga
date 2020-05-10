`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/10/2020 02:07:34 PM
// Design Name: 
// Module Name: AudioProcessing
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


module AudioProcessing #(
    parameter num_of_taps = 64,
    parameter num_of_equalizers = 8
)(
    input clk,
    input reset_n,
    input i2s_sclk,
    input i2s_bclk,
    input i2s_lrclk,
    input i2s_d,
    input dac_zero_r,
    input dac_zero_l,
    output dac_rst,
    output dac_sclk,
    output dac_bclk,
    output dac_lrclk,
    output dac_data,
    output sram_spi_cs,
    output sram_spi_clk,
    inout [3:0] sram_sio,
    
    //registers
    input [15:0]    fir_coef_eq01[num_of_taps-1:0]
);
endmodule
