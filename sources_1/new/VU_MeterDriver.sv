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
    input l_data_en,         // 96KHz strobe
    input r_data_en,         // 96KHz strobe
    input audio_enable,             // '1' if music playing
    input [7:0] l_audio_signal,     // msb's
    input [7:0] r_audio_signal,     // msb's
    input [7:0] vu_test_reg,        // for test only
    output l_VU_out,
    output r_VU_out
);

parameter NUMBER_OF_AVERAGES = 16;

assign l_VU_out = vu_test_reg[0] ? test_VU_pwm : l_VU_pwm;
assign r_VU_out = vu_test_reg[0] ? test_VU_pwm : r_VU_pwm;

reg         l_VU_sample, r_VU_sample;
reg         l_VU_pwm, r_VU_pwm, test_VU_pwm;
reg [3:0]   l_accum_cnt, r_accum_cnt;
reg [5:0]   l_VU_pwm_clk_cnt, r_VU_pwm_clk_cnt, test_VU_pwm_clk_cnt;
reg [23:0]  l_avg_pwm, r_avg_pwm;
reg [6:0]   l_pwm_duty_cycle, r_pwm_duty_cycle, test_pwm_duty_cycle, test_VU_sample_cnt;
//reg [6:0]   test_cnt;


// generates average interval (VU sample rate) => 96KHz/NUMBER_OF_AVERAGES = 6KHz
// left
always @ (posedge clk) begin
    if (l_data_en && audio_enable) begin
        if (l_accum_cnt == (NUMBER_OF_AVERAGES - 1)) begin     
            l_VU_sample <= 1'b1;      // strobe
            l_accum_cnt <= 0;
        end
        else begin
            l_VU_sample <= 1'b0;
            l_accum_cnt <= l_accum_cnt + 1;
        end
    end    
    else begin
        l_VU_sample <= 1'b0;
        l_accum_cnt <= l_accum_cnt;
    end           
end // always

// generates average interval (VU sample rate) => 96KHz/NUMBER_OF_AVERAGES = 6KHz
// right
always @ (posedge clk) begin
    if (r_data_en && audio_enable) begin
        if (r_accum_cnt == (NUMBER_OF_AVERAGES - 1)) begin     
            r_VU_sample <= 1'b1;      // strobe
            r_accum_cnt <= 0;
        end
        else begin
            r_VU_sample <= 1'b0;
            r_accum_cnt <= r_accum_cnt + 1;
        end
    end    
    else begin
        r_VU_sample <= 1'b0;
        r_accum_cnt <= r_accum_cnt;
    end           
end // always


//left unsigned accum
VUmeter_accum left_VU_accum (
    .CLK(clk),              // input wire CLK
    .CE(l_data_en),  // input wire CE
    .BYPASS(VU_sample),     // input wire BYPASS, 6KHz interval
    .SCLR(!audio_enable),   // input wire SCLR
    .B({~l_audio_signal[7], l_audio_signal[6:0]}),     // input wire [7 : 0] converted to unsigned
    .Q(l_avg_pwm)           // output wire [15 : 0] Q
);

//right unsigned accum
VUmeter_accum right_VU_accum (
    .CLK(clk),              // input wire CLK
    .CE(r_data_en),  // input wire CE
    .BYPASS(VU_sample),     // input wire BYPASS, 6KHz interval
    .SCLR(!audio_enable),   // input wire SCLR
    .B({~r_audio_signal[7], r_audio_signal[6:0]}),     // input wire [7 : 0] converted to unsigned
    .Q(r_avg_pwm)           // output wire [15 : 0] Q
);

// LEFT audio data pwm generator
always @ (posedge clk) begin
    if (l_VU_sample && l_data_en) begin        // stb @ 6K cycles
        l_pwm_duty_cycle <= ~l_avg_pwm[15:9];        // load left duty cycle count inverted
        l_VU_pwm_clk_cnt <= 0;
    end
    // define duty cycle resolution as 128 increments per cycle
    // duty cycle clk rate (enable) - 6KHz x 128 = 768KHz
    // to create 768KHz = 49.152MHz / 64 = VU_pwm_clk_cnt
    else if (l_VU_pwm_clk_cnt == 63) begin    
        l_VU_pwm_clk_cnt <= 0;
        // left
        if (l_pwm_duty_cycle > 0) begin
            l_pwm_duty_cycle <= l_pwm_duty_cycle - 1;
            l_VU_pwm <= 1'b1;
        end
        else begin
            l_pwm_duty_cycle <= 0;
            l_VU_pwm <= 1'b0; 
        end
     end
     else begin
        l_VU_pwm_clk_cnt <= l_VU_pwm_clk_cnt + 1;
        l_pwm_duty_cycle <= l_pwm_duty_cycle;
     end

end // always
        
        
// RIGHT audio data pwm generator
 always @ (posedge clk) begin
    if (r_VU_sample && r_data_en) begin        // stb @ 6K cycles
       r_pwm_duty_cycle <= ~r_avg_pwm[15:9];        // load tight duty cycle count inverted
       r_VU_pwm_clk_cnt <= 0;
    end
    // define duty cycle resolution as 128 increments per cycle
    // duty cycle clk rate (enable) - 6KHz x 128 = 768KHz
    // to create 768KHz = 49.152MHz / 64 = VU_pwm_clk_cnt
    else if (r_VU_pwm_clk_cnt == 63) begin    
        r_VU_pwm_clk_cnt <= 0;
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
        r_VU_pwm_clk_cnt <= r_VU_pwm_clk_cnt + 1;
        r_pwm_duty_cycle <= r_pwm_duty_cycle;
     end

end // always


//    TEST    \\
// below for VU meter test only
 always @ (posedge clk) begin
    if (vu_test_reg[0]) begin                       // if VU test enabled
        if (test_VU_pwm_clk_cnt == 63) begin        // VU bit sample interval
            test_VU_pwm_clk_cnt <= 0;
            
            if (test_VU_sample_cnt == 127) begin    // VU word sample interval (if new word)
                test_VU_sample_cnt <= 0;
                test_pwm_duty_cycle <= vu_test_reg[7:1];
                test_VU_pwm <= 1'b0;
            end    
            else if (test_pwm_duty_cycle > 0) begin
                    test_pwm_duty_cycle <= test_pwm_duty_cycle - 1;
                    test_VU_sample_cnt <= test_VU_sample_cnt + 1;
                    test_VU_pwm <= 1'b1;
            end
            else begin
                    test_pwm_duty_cycle <= 0;
                    test_VU_sample_cnt <= test_VU_sample_cnt + 1;
                    test_VU_pwm <= 1'b0;
            end
        end        
        else begin 
            test_VU_pwm_clk_cnt <= test_VU_pwm_clk_cnt + 1;
            test_pwm_duty_cycle <= test_pwm_duty_cycle;
            test_VU_sample_cnt <= test_VU_sample_cnt;
            test_VU_pwm <= test_VU_pwm; 
        end
    end
    else begin// VU test not enabled
        test_VU_sample_cnt <= 0; 
        test_pwm_duty_cycle <= vu_test_reg[7:1];
        test_VU_pwm_clk_cnt <= 0;
        test_VU_pwm <= 0; 
    end    
end // always 
        
endmodule
