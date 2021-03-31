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
//    output reg sram_spi_cs,
//    output reg sram_spi_clk,
//    inout [3:0] sram_spi_sio,
    // cpu registers 
    input       coef_wr_en,
    input       eq_wr_en,
    input [7:0] audio_control,      // cpu reg
    input [7:0] equalizer_select,   // cpu reg 
    input [7:0] taps_per_filter,    // cpu reg
    input [7:0] coef_wr_lsb_data,   // cpu reg
    input [7:0] coef_wr_msb_data,   // cpu reg
    input [7:0] eq_wr_lsb_data,     // cpu reg
    input [7:0] eq_wr_msb_data,     // cpu reg
    output [7:0] audio_status       // cpu reg
);

// sets clk delays between audio_en and X_pcm_d_en

wire pcmToI2S_sclk;
wire pcmToI2S_bclk;
wire pcmToI2S_lrclk;
wire pcmToI2S_data;
wire l_eq_valid, r_eq_valid;
 
reg         l_i2sToPcm_valid, r_i2sToPcm_valid;
wire        l_fir_data_valid, r_fir_data_valid;
wire [23:0] l_pcm_data, r_pcm_chnl;
wire [23:0] l_mux_out, r_mux_out;
wire [47:0] l_fir_data_out[num_of_filters - 1 :0], r_fir_data_out[num_of_filters - 1 :0];


assign dac_rst = !reset_n;
/////// audio control register ////////
assign bypass =         audio_control[0];
assign eq_bypass =      audio_control[1];
assign audio_enable =   audio_control[2];
wire test_en =          audio_control[3];
wire coef_sel =         audio_control[7:4];

// audio_status register
assign audio_status[0]  = fir_wr_addr_zero;
assign audio_status[1]  = eq_wr_addr_zero;

//assign audio_out = 

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
    .clk            (clk),              // input
    .reset_n        (reset_n),          // input
    .sclk           (i2s_sclk),         // input
    .bclk           (i2s_bclk),         // input
    .lrclk          (i2s_lrclk),        // input
    .i2s_data       (i2s_d),            // input
    .l_dout_valid   (l_i2sToPcm_valid), // output     
    .r_dout_valid   (r_i2sToPcm_valid), // output     
    .l_pcm_data     (l_pcm_data),       // [23:0] output
    .r_pcm_data     (r_pcm_data)        // [23:0] output
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
    .wr_addr_zero       (fir_wr_addr_zero),     // output
    // input signals
    .l_data_en          (l_i2sToPcm_valid),     // input enable strobe 
    .r_data_en          (r_i2sToPcm_valid),     // input enable strobe 
    .l_data_in          (l_pcm_data),           // [23:0] input
    .r_data_in          (r_pcm_data),           // [23:0] input
    // output signals
    .l_data_valid       (l_fir_data_valid),     // output valid (after a fir process till next sample)    
    .r_data_valid       (r_fir_data_valid),     // output valid (after a fir process till next sample)    
    .l_data_out         (l_fir_data_out),       // [47:0][num_of_filters] output
    .r_data_out         (r_fir_data_out)        // [47:0][num_of_filters] output
);

// Audio_SRAM_Interface () ->> to do

EqualizerGains eq_gain (
    .clk            (clk),
    .reset_n        (reset_n),
    .bypass         (eq_bypass),
    .eq_wr          (eq_wr_en),
    .eq_wr_sel      (equalizer_select),                 // input [num_of_filters - 1 : 0]     
    .eq_gain_lsb    (eq_wr_lsb_data),                   // input [7:0] 
    .eq_gain_msb    (eq_wr_msb_data),                   // input [7:0]
    .l_data_in      (l_fir_data_out),                   // input [47:0][num_of_filters - 1 : 0]
    .r_data_in      (r_fir_data_out),                   // input [47:0][num_of_filters - 1 : 0]
    .wr_addr_zero   (eq_wr_addr_zero),                  // output
    .l_data_out     (l_eq_out),                         // output [23:0] 
    .r_data_out     (r_eq_out)                          // output [23:0] 
);


SineWaveGenerator sinGen(
    .clk        (clk),              // input
    .run        (sin_wave_run),     // input
    .freq_sel   (sin_wave_inc),     // input [3:0], selects freq out from a stream
    .data_valid (sin_wave_valid),   // output strobe
    .sin_out    (sin_wave)          // output [23:0]
);
    
assign l_mux_out =  test_en ?   sin_wave : l_eq_out;
assign r_mux_out =  test_en ?   sin_wave : r_eq_out;
assign l_mux_en = test_en ?  sin_wave_valid : l_eq_valid;
assign r_mux_en = test_en ?  sin_wave_valid : r_eq_valid;

PCM_to_I2S_Converter pcm_to_i2s(
    .clk            (clk),              // input
    .reset_n        (reset_n),          // input
    .l_data_valid   (l_i2sToPcm_valid), // output
    .r_data_valid   (r_i2sToPcm_valid), // output
    .l_data_en      (l_mux_en),         // input
    .r_data_en      (r_mux_en),         // input
    .l_data         (l_mux_out),        // [23:0] input
    .r_data         (r_mux_out),        // [23:0] input
    .sclk           (pcmToI2S_sclk),    // output
    .bclk           (pcmToI2S_bclk),    // output
    .lrclk          (pcmToI2S_lrclk),   // output
    .s_data         (pcmToI2S_data)     // [23:0] output
);    



endmodule

