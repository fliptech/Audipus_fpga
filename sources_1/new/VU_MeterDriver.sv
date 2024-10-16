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
    input reset,
    input audio_enable,
    input [15:0] l_audio_signal,
    input [15:0] r_audio_signal,
    output reg l_VU_pwm,
    output reg r_VU_pwm
);

parameter NUMBER_OF_AVERAGES = 16;

reg         VU_sample, pwm_ready;
reg [3:0]   accum_cnt;
reg [5:0]   VU_pwm_clk_cnt;
reg [23:0]  l_avg_pwm, r_avg_pwm;
reg [15:0]  l_pwm_duty_cycle, r_pwm_duty_cycle;

always @ (posedge clk) begin


    if (audio_enable) begin
        if (accum_cnt == (NUMBER_OF_AVERAGES - 1)) begin    // VU sample rate = 96KHz/NUMBER_OF_AVERAGES = 6KHz
            VU_sample <= 1'b1;
            accum_cnt <= 0;
        end
    end        

end // always

VUmeter_accum left_VU_accum (
    .CLK(clk),              // input wire CLK
    .CE(audio_enable),      // input wire CE
    .BYPASS(VU_sample),     // input wire BYPASS
    .SCLR(reset),           // input wire SCLR
    .B(l_audio_signal),     // input wire [15 : 0] B
    .Q(l_avg_pwm)           // output wire [23 : 0] Q
);

VUmeter_accum right_VU_accum (
    .CLK(CLK),              // input wire CLK
    .CE(audio_enable),      // input wire CE
    .BYPASS(VU_sample),     // input wire BYPASS
    .SCLR(reset),           // input wire SCLR
    .B(r_audio_signal),     // input wire [15 : 0] B
    .Q(r_avg_pwm)           // output wire [23 : 0] Q
);


always @ (posedge clk) begin

    if (VU_sample) begin        // stb @ 6K cycles
        pwm_ready = 1'b1;
    end 
    else if (VU_pwm_clk_cnt == 63) begin    // stb @ (49.152MHz / 64) cycles/sec => 768,000 cycles/sec
        VU_pwm_clk_cnt = 0;
       
        if (pwm_ready) begin
            l_pwm_duty_cycle <= l_avg_pwm;
            r_pwm_duty_cycle <= r_avg_pwm;
            pwm_ready = 1'b0;
        end
    end 
    else
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
