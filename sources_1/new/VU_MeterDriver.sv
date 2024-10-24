`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2024 02:03:14 PM
// Design Name: 
// Module Name: VU_MeterDriver
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


module VU_MeterDriver(
    input clk,
    input audio_clk_enable,         // 96KHz strobe
    input audio_enable,             // '1' if music playing
    input [7:0] l_audio_signal,     // msb's
    input [7:0] r_audio_signal,     // msb's
    output reg l_VU_pwm,
    output reg r_VU_pwm
);

parameter NUMBER_OF_AVERAGES = 16;

reg         VU_sample;
reg [3:0]   accum_cnt = 0;
reg [5:0]   VU_pwm_clk_cnt = 0;
reg [23:0]  l_avg_pwm, r_avg_pwm;
reg [6:0]   l_pwm_duty_cycle, r_pwm_duty_cycle;


// generates average interval (VU sample rate) => 96KHz/NUMBER_OF_AVERAGES = 6KHz
always @ (posedge clk) begin
    if (audio_clk_enable && audio_enable) begin
        if (accum_cnt == (NUMBER_OF_AVERAGES - 1)) begin     
            VU_sample <= 1'b1;      // strobe
            accum_cnt <= 0;
        end
        else begin
            VU_sample <= 1'b0;
            accum_cnt <= accum_cnt + 1;
        end
    end    
    else begin
        VU_sample <= 1'b0;
        accum_cnt <= accum_cnt;
    end           
end // always

//left unsigned accum
VUmeter_accum left_VU_accum (
    .CLK(clk),              // input wire CLK
    .CE(audio_clk_enable),  // input wire CE
    .BYPASS(VU_sample),     // input wire BYPASS
    .SCLR(!audio_enable),   // input wire SCLR
    .B({~l_audio_signal[7], l_audio_signal[6:0]}),     // input wire [7 : 0] converted to unsigned
    .Q(l_avg_pwm)           // output wire [15 : 0] Q
);

//right unsigned accum
VUmeter_accum right_VU_accum (
    .CLK(CLK),              // input wire CLK
    .CE(audio_clk_enable),  // input wire CE
    .BYPASS(VU_sample),     // input wire BYPASS
    .SCLR(!audio_enable),   // input wire SCLR
    .B({~r_audio_signal[7], r_audio_signal[6:0]}),     // input wire [7 : 0] converted to unsigned
    .Q(r_avg_pwm)           // output wire [15 : 0] Q
);

// audio data pwm generator
always @ (posedge clk) begin
    if (VU_sample && audio_clk_enable) begin        // stb @ 6K cycles
        l_pwm_duty_cycle <= l_avg_pwm[15:9];        // load left duty cycle count
        r_pwm_duty_cycle <= r_avg_pwm[15:9];        // load tight duty cycle count
        VU_pwm_clk_cnt = 0;
    end
    // define duty cycle resolution as 128 increments per cycle
    // duty cycle clk rate (enable) - 6KHz x 128 = 768KHz
    // to create 768KHz = 49.152MHz / 64 = VU_pwm_clk_cnt
    else if (VU_pwm_clk_cnt == 63) begin    
        VU_pwm_clk_cnt = 0;
        // left
        if (l_pwm_duty_cycle > 0) begin
            l_pwm_duty_cycle <= l_pwm_duty_cycle - 1;
            l_VU_pwm <= 1'b1;
        end
        else begin
            l_pwm_duty_cycle <= 0;
            l_VU_pwm <= 1'b0; 
        end
        
        // right                    
        if (r_pwm_duty_cycle > 0) begin
            r_pwm_duty_cycle <= r_pwm_duty_cycle - 1;
            r_VU_pwm <= 1'b1;
        end
        else begin
            r_pwm_duty_cycle <= 0;
            r_VU_pwm <= 1'b0; 
        end            
     end
     else begin
        VU_pwm_clk_cnt <= VU_pwm_clk_cnt + 1;
        l_pwm_duty_cycle <= l_pwm_duty_cycle;
        r_pwm_duty_cycle <= r_pwm_duty_cycle;
     end

end // always
        
endmodule
