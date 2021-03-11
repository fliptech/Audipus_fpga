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
    parameter num_of_filters = 4
)(
    input clk,
    input reset_n,
    // i2s in
    input i2s_sclk,
    input i2s_bclk,
    input i2s_lrclk,
    input i2s_d,
    // dac interface, i2s out
    output dac_rst,
    output reg dac_sclk,
    output reg dac_bclk,
    output reg dac_lrclk,
    output reg dac_data,
    // audio SRAM interface signals
    output reg sram_spi_cs,
    output reg sram_spi_clk,
    inout [3:0] sram_spi_sio,
    // cpu registers 
    input       coef_wr_en,
    input       eq_wr_en,
    input [7:0] audio_control,      // cpu reg
    input [7:0] equalizer_select, 
    input [7:0] taps_per_filter,    // cpu reg
    input [7:0] coef_wr_lsb_data,   // cpu reg
    input [7:0] coef_wr_msb_data,   // cpu reg
    input [7:0] eq_wr_lsb_data,     // cpu reg
    input [7:0] eq_wr_msb_data      // cpu reg
);

// sets clk delays between audio_en and X_pcm_d_en
parameter AUD_EN_DLY = 2;

reg [AUD_EN_DLY:0] audio_en_delay;
wire pcmToI2S_sclk;
wire pcmToI2S_bclk;
wire pcmToI2S_lrclk;
wire pcmToI2S_data;
 
reg         l_pcm_d_en, r_pcm_d_en;
wire        l_data_valid, r_data_valid;
wire [23:0] l_pcm_chnl, r_pcm_chnl;
wire [23:0] l_aud_out, r_aud_out;
wire [47:0] l_fir_out[num_of_filters - 1 :0], r_fir_out[num_of_filters - 1 :0];

assign dac_rst = !reset_n;
/////// audio control register ////////
assign bypass =         audio_control[0];
assign audio_enable =   audio_control[1];
assign coef_rst =       audio_control[2];
wire coef_sel =         audio_control[7:4];

/////////////////////////////////////////

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
        dac_sclk <= pcmToI2S_sclk;
        dac_bclk <= pcmToI2S_bclk;
        dac_lrclk <= pcmToI2S_lrclk;
        dac_data <= pcmToI2S_data;
    end
end


I2S_to_PCM_Converter i2s_to_pcm(
    .clk        (clk),          // input
    .reset_n    (reset_n),      // input
    .sclk       (i2s_sclk),     // input
    .bclk       (i2s_bclk),     // input
    .lrclk      (i2s_lrclk),    // input
    .s_data     (i2s_d),        // input
    .l_data_stb (l_pcm_d_en),   // output     
    .r_data_stb (r_pcm_d_en),   // output     
    .l_data     (l_pcm_chnl),   // [23:0] output
    .r_data     (r_pcm_chnl)    // [23:0] output
);    
    
PCM_to_I2S_Converter pcm_to_i2s(
    .clk            (clk),          // input
    .reset_n        (reset_n),      // input
    .l_data_valid   (l_pcm_d_en),     // input
    .r_data_valid   (r_pcm_d_en),     // input
    .l_data_en      (l_dout_en),        // output
    .r_data_en      (r_dout_en),        // output
    .l_data         (l_aud_out),    // [23:0] input
    .r_data         (r_aud_out),    // [23:0] input
    .sclk           (pcmToI2S_sclk),     // output
    .bclk           (pcmToI2S_bclk),     // output
    .lrclk          (pcmToI2S_lrclk),    // output
    .s_data         (pcmToI2S_data)         // output
);    

FIR_Filters filters (
    .clk                (clk),                  // input
    .reset_n            (reset_n),              // input
    .audio_en           (audio_en),             // input, from audio_control reg
    // coefficient signals
    .coef_rst           (coef_rst),             // input, from audio_control reg
    .coefficient_wr_en  (coef_wr_en),           // input stb when coef wr data in valid
    .coef_select        (coef_sel),             // [3:0] input
    .coef_wr_lsb_data   (coef_wr_lsb_data),     // [7:0] input, cpu reg
    .coef_wr_msb_data   (coef_wr_msb_data),     // [7:0] input, cpu reg
    .taps_per_filter    (taps_per_filter),      // [7:0] input, cpu reg
    .wr_addr_zero       (wr_addr_zero),         // output
    // i2s signals 
    .l_pcm_chnl         (l_pcm_chnl),           // [23:0] input
    .r_pcm_chnl         (r_pcm_chnl),           // [23:0] input
    // audio out    
    .l_audio_out        (l_fir_out),            // [47:0][num_of_filters] output
    .r_audio_out        (r_fir_out)             // [47:0][num_of_filters] output
);

// Audio_SRAM_Interface () ->> to do

EqualizerGains eq_gain (
    .clk            (clk),
    .reset_n        (reset_n),
    .eq_wr          (eq_wr_en),
    .eq_wr_sel      (equalizer_select),                 // input [num_of_filters - 1 : 0]     
    .eq_gain        ({eq_wr_msb_data, eq_wr_lsb_data}), // input [15:0][num_of_filters - 1 : 0] 
    .l_audio_din    (l_fir_out),                        // input [47:0][num_of_filters - 1 : 0]
    .r_audio_din    (r_fir_out),                        // input [47:0][num_of_filters - 1 : 0]
    .l_audio_dout   (l_aud_out),                        // output [23:0] 
    .r_audio_dout   (r_aud_out)                         // output [23:0] 
);

// setting clk delays between audio_en and X_pcm_d_en
always @ (posedge clk) begin
    audio_en_delay[0] <= audio_en;
    audio_en_delay[AUD_EN_DLY:1] <= audio_en_delay[AUD_EN_DLY - 1:0];
    l_pcm_d_en <= audio_en_delay[AUD_EN_DLY]; 
    r_pcm_d_en <= audio_en_delay[AUD_EN_DLY]; 
end


endmodule

