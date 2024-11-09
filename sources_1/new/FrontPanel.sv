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
    input [7:0] l_audio_signal,     // from AudioMux
    input [7:0] r_audio_signal,     // from AudioMux
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
    // inputs  
    .clk                    (clk),
    .reset                  (reset),
    .encoder_A              (encoder_A),
    .encoder_B              (encoder_B),
    .encoder_sw             (encoder_sw),
    // outputs
    .enc_state_change_stb   (enc_state_change_stb),     // strobe when enc value state changes
    .clockwise              (clkwise),
    .click                  (click),                    // enc_value of one in sync with enc_state_change_stb
    .switch                 (switch),                   // switch value in sync with enc_state_change_stb
    // below for test
    .enc_sw_value           (enc_sw_value),             // debounced switch value output
    .enc_value              (enc_value)                 // debounced encoder value output[1:0] 
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
//      rotary_encoder_reg[0] = click
//      rotary_encoder_reg[1] = clkwise
//      rotary_encoder_reg[2] = switch
//      rotary_encoder_reg[3] = state change
//      rotary_encoder_reg[4] = overflow
//      rotary_encoder_reg[7:5] = 0

always @ (posedge clk) begin

    rotary_encoder_reg[7:5] <= 0;       // spare bits set to zero

    if (enc_state_change_stb)  begin        // enc state change occurs
        rotary_encoder_reg[3] <= 1'b1;      // state change bit enabled
        if (rotary_encoder_reg[3] == 1'b1)  // if state change when overflow bit is still set
            rotary_encoder_reg[4] <= 1'b1;  // overflow bit enabled

        rotary_encoder_reg[0] <= click;
        rotary_encoder_reg[1] <= clkwise;
        rotary_encoder_reg[2] <= switch;
    end
    else if (rotary_encoder_rd_stb)  begin  // clear state change & overflow bitafter being read by the cpu
        rotary_encoder_reg[3] <= 1'b0;
        rotary_encoder_reg[4] <= 1'b0;
        rotary_encoder_reg[2:0] <= rotary_encoder_reg[2:0];
    end
    else
       rotary_encoder_reg[4:0] <= rotary_encoder_reg[4:0]; 
end
    
endmodule
