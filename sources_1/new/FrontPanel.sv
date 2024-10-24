`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2024 03:38:27 PM
// Design Name: 
// Module Name: FrontPanel
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


module FrontPanel(
// Common signals
    input clk,
    input reset,
    input audio_clk_enable,
    input audio_enable,
// Rotary Encoder    
    input encoder_A,
    input encoder_B,
    input rotary_encoder_rd_stb,
    output enc_state_change,
    output clkwise,
    output [7:0] rotary_encoder_reg,
//  -VU Meter
    input [7:0] l_audio_signal,
    input [7:0] r_audio_signal,
    output l_VU_pwm,
    output r_VU_pwm,
// test
    output [15:0] test    
 );
 
// clockwise            enc_value(BA) = {00, 01, 11, 10}        
// counter clockwise    enc_value(BA) = {00, 10, 11, 01}  
assign test[1:0] = enc_test_state;

assign test[2] = clkwise;    
    
 rotaryEncoder rot_enc (   
    .clk                    (clk),
    .reset                  (reset),
    .encoder_A              (encoder_A),
    .encoder_B              (encoder_B),
    .rotary_encoder_rd_stb  (rotary_encoder_rd_stb),
    .enc_state_change       (enc_state_change),
    .rotary_encoder_reg     (rotary_encoder_reg),
    // for test
    .clkwise                (clkwise),
    .enc_test_out           (enc_test_state)                // output[3:0]    
 );
 

VU_MeterDriver VU_mtr (
    .clk,
    .audio_clk_enable       (audio_clk_enable),         // 96KHz strobe
    .audio_enable           (audio_enable),             // '1' if music playing
    .l_audio_signal         (l_audio_signal),     // msb's
    .r_audio_signal         (r_audio_signal),     // msb's
    .l_VU_pwm               (l_VU_pwm),
    .r_VU_pwm               (r_VU_pwm)
);
 
    
endmodule
