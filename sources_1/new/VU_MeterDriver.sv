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
    input audio_clk_enable,
    input audio_enable,
    input [7:0] l_audio_signal,     // msb's
    input [7:0] r_audio_signal,     // msb's
    output reg l_VU_pwm,
    output reg r_VU_pwm
);

parameter NUMBER_OF_AVERAGES = 16;

reg         VU_sample, pwm_ready;
reg [3:0]   accum_cnt = 0;
reg [5:0]   VU_pwm_clk_cnt = 0;
reg [23:0]  l_avg_pwm, r_avg_pwm;
reg [6:0]  l_pwm_duty_cycle, r_pwm_duty_cycle;


// generates average interval (VU sample rate) => 96KHz/NUMBER_OF_AVERAGES = 6KHz
always @ (posedge clk) begin
    if (audio_clk_enable) begin
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

//unsigned accum
VUmeter_accum left_VU_accum (
    .CLK(clk),              // input wire CLK
    .CE(audio_clk_enable),  // input wire CE
    .BYPASS(VU_sample),     // input wire BYPASS
    .SCLR(audio_enable),    // input wire SCLR
    .B({~l_audio_signal[7], l_audio_signal[6:0]}),     // input wire [7 : 0] converted to unsigned
    .Q(l_avg_pwm)           // output wire [15 : 0] Q
);

//unsigned accum
VUmeter_accum right_VU_accum (
    .CLK(CLK),              // input wire CLK
    .CE(audio_clk_enable),  // input wire CE
    .BYPASS(VU_sample),     // input wire BYPASS
    .SCLR(audio_enable),    // input wire SCLR
    .B({~r_audio_signal[7], r_audio_signal[6:0]}),     // input wire [7 : 0] converted to unsigned
    .Q(r_avg_pwm)           // output wire [15 : 0] Q
);

// audio data averager
always @ (posedge clk) begin
    if (VU_sample) begin        // stb @ 6K cycles
        pwm_ready = 1'b1;
    end 
    else if (VU_pwm_clk_cnt == 63) begin    // stb @ (49.152MHz / 64) cycles/sec => 768,000 cycles/sec
        VU_pwm_clk_cnt = 0;
       
        if (pwm_ready) begin
            // load duty cycle counter (7bits)
            l_pwm_duty_cycle <= l_avg_pwm[15:9];
            r_pwm_duty_cycle <= r_avg_pwm[15:9];
            pwm_ready = 1'b0;
        end
    end 
    // samples per duty cycle = 768K / 6K cycles = 128
    else begin
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
            l_pwm_duty_cycle <= r_pwm_duty_cycle - 1;
            r_VU_pwm <= 1'b1;
        end
        else begin
            r_pwm_duty_cycle <= 0;
            r_VU_pwm <= 1'b0; 
        end            
     end
end // always
        
endmodule
