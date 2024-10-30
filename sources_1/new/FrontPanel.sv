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
    input reset_n,
    input audio_clk_enable,
    input audio_enable,
// Rotary Encoder    
    input encoder_A,
    input encoder_B,
    input encoder_sw,
    input rotary_encoder_rd_stb,
    output reg [7:0] rotary_encoder_reg,
    output reg enc_state_change,
 //  -VU Meter
    input [7:0] l_audio_signal,
    input [7:0] r_audio_signal,
    output l_VU_pwm,
    output r_VU_pwm,
// test
    output [15:0] test    
 );
 
 wire       clkwise;
 
// clockwise            enc_value(BA) = {00, 01, 11, 10}        
// counter clockwise    enc_value(BA) = {00, 10, 11, 01}  
assign test[0] = encoder_A;
assign test[1] = encoder_B;
assign test[2:3] = enc_value;   // sampled, debounced encoder value => [B,A]
assign test[4] = clkwise;       // rotation direction   
assign test[3] = enc_state_change;
assign test[4] =  l_VU_pwm;
assign test[5] =  r_VU_pwm;


assign test[4] =  l_VU_pwm;
assign test[5] =  r_VU_pwm;

assign test[7] =  audio_clk_enable;

// clockwise            enc_value(BA) = {00, 01, 11, 10}        
// counter clockwise    enc_value(BA) = {00, 10, 11, 01}  
    
 rotaryEncoder rot_enc (   
    .clk                    (clk),
    .reset                  (reset),
    .encoder_A              (encoder_A),
    .encoder_B              (encoder_B),
    .enc_state_change_stb   (enc_state_change_stb),     // strobe when enc value state changes
    .enc_value              (enc_value),                // debounced encoder value output[1:0] 
    // for test
    .clockwise              (clkwise),
    .encoder_state          (encoder_state)             // output[1:0] (for test)   
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
 
// rotary cpu interface
always @ (posedge clk) begin

    if (enc_state_change_stb)
        enc_state_change <= 1'b1;
    else if (rotary_encoder_rd_stb)
        enc_state_change <= 1'b0;
    else
        enc_state_change <= enc_state_change;
                
    if (enc_state_change_stb) begin
        rotary_encoder_reg[1:0] <= enc_value;
        rotary_encoder_reg[2] <= clkwise;
        rotary_encoder_reg[7:3] <= 0;
    end
    else
        rotary_encoder_reg <= rotary_encoder_reg;       
end
    
endmodule
