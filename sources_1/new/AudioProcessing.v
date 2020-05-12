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
    input bypass,
    input i2s_sclk,
    input i2s_bclk,
    input i2s_lrclk,
    input i2s_d,
    input dac_zero_r,
    input dac_zero_l,
    output dac_rst,
    output reg dac_sclk,
    output reg dac_bclk,
    output reg dac_lrclk,
    output reg dac_data,
    output reg sram_spi_cs,
    output reg sram_spi_clk,
    inout [3:0] sram_sio,
    
    //registers
    input [15:0]    fir_coef_eq01[num_of_taps-1:0]
);


assign dac_rst = !reset_n;

always @ (posedge clk) begin
    if (bypass) begin
    // audio processor bypass
        dac_sclk <= i2s_sclk;
        dac_bclk <= i2s_bclk;
        dac_lrclk <= i2s_lrclk;
        dac_data <= i2s_d;
    end
    else begin
    // add audio processed output here
        dac_sclk <= 1'b0;
        dac_bclk <= 1'b0;
        dac_lrclk <= 1'b0;
        dac_data <= 1'b0;
    end
end


I2S_to_PWM_converter (
    .clk        (clk),
    .reset_n    (reset_n),
    .sclk       (i2s_sclk),
    .bclk       (i2s_bclk),
    .lrclk      (i2s_lrclk),
    .s_data     (i2s_d),
    .data_en    (pwm_d_en),
    .l_data     (l_pwm_chnl),
    .r_data     (r_pwm_chnl)
);    
    
    

endmodule

