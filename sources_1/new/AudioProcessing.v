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


I2S_to_PCM_Converter (
    .clk        (clk),          // input
    .reset_n    (reset_n),      // input
    .sclk       (i2s_sclk),     // input
    .bclk       (i2s_bclk),     // input
    .lrclk      (i2s_lrclk),    // input
    .s_data     (i2s_d),        // input
    .data_en    (l_pcm_d_en),   // output     
    .data_en    (r_pcm_d_en),   // output     
    .l_data     (l_pcm_chnl),   // [23:0] output
    .r_data     (r_pcm_chnl)    // [23:0] output
);    
    
PCM_to_I2S_Converter (
    .clk        (clk),          // input
    .reset_n    (reset_n),      // input
    .data_en    (pcm_d_en),     // input
    .l_data     (l_aud_out[47:24]),    // [23:0] input
    .r_data     (r_aud_out[47:24]),    // [23:0] input
    .sclk       (i2s_sclk),     // output
    .bclk       (i2s_bclk),     // output
    .lrclk      (i2s_lrclk),    // output
    .s_data     (i2s_d)         // output
);    
 
wire        l_pcm_d_en, r_pcm_d_en;
wire        l_data_valid, r_data_valid;
wire [23:0] l_pcm_chnl, r_pcm_chnl;
wire [47:0] l_aud_out, r_aud_out;
    
FIR_Tap fir_tap_l (
    .clk                (clk),              // input              
    .reset_n            (reset_n),          // input
    .data_en            (l_pcm_d_en),       // input
    .audio_data_in      (l_pcm_chnl),       // [23:0] input    
    .coefficients       (coefficients),     // [15:0] input
    .data_valid         (l_data_valid),     // output
    .coef_addr          (coef_addr),        // [num_of_taps-1:0] output    
    .audio_data_out     (l_aud_out)         // [47:0] output      
);        

FIR_Tap fir_tap_r(
    .clk                (clk),              // input
    .reset_n            (reset_n),          // input
    .data_en            (r_pcm_d_en),       // input
    .audio_data_in      (r_pcm_chnl),       // [23:0] input    
    .coefficients       (coefficients),     // [15:0] input
    .data_valid         (r_data_valid),     // output
    .coef_addr          (coef_addr),        // [num_of_taps-1:0] output
    .audio_data_out     (r_aud_out)         // [47:0] output   
);        

endmodule

