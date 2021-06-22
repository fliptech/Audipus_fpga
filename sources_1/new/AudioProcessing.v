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
    input i2s_bclk,
    input i2s_lrclk,
    input i2s_d,
    // dac interface, i2s out
    output audio_enable,
    output reg dac_bclk,
    output reg dac_lrclk,
    output reg dac_data,
    output     pcmToI2S_valid,          // mainly for test
    // audio SRAM interface signals
//    output reg sram_spi_cs,
//    output reg sram_spi_clk,
//    inout [3:0] sram_spi_sio,
    // cpu registers 
    input       coef_wr_en,
    input       eq_wr_en,
    input [7:0] audio_control,      // cpu reg
    input [7:0] filter_select,      // cpu reg 
    input [7:0] taps_per_filter,    // cpu reg
    input [7:0] coef_wr_lsb_data,   // cpu reg
    input [7:0] coef_wr_msb_data,   // cpu reg
    input [7:0] eq_wr_lsb_data,     // cpu reg
    input [7:0] eq_wr_msb_data,     // cpu reg
    output [7:0] audio_status,      // cpu reg
    output [7:0] test_reg,          // cpu reg
    output [7:0] i2sToPcm_bit_cnt,  // cpu_reg
    // for test
    output          test_dout_valid,
    output [15:0]   test_data_out,
  // for sin test
    output [2:0]    interp_cnt        //  output, 
           
);

// sets clk delays between audio_en and X_pcm_d_en

wire pcmToI2S_sclk;
wire pcmToI2S_bclk;
wire pcmToI2S_lrclk;
wire pcmToI2S_data;
wire l_eq_valid, r_eq_valid;
wire sin_wave_valid, intrp_dout_valid;
wire fir_wr_addr_zero, eq_wr_addr_zero;
 
wire        l_i2sToPcm_valid, r_i2sToPcm_valid;
//wire        l_PcmToI2S_valid, r_PcmToI2S_valid;
wire        l_fir_data_valid, r_fir_data_valid;
wire        l_mux_valid, r_mux_valid;
wire [23:0] l_pcm_data, r_pcm_data;
wire [23:0] l_mux_out, r_mux_out;
wire [33:0] l_intrp_d_out, r_intrp_d_out;
wire [23:0] wave_out, l_eq_out, r_eq_out;
wire [47:0] l_fir_data_out[num_of_filters - 1 :0], r_fir_data_out[num_of_filters - 1 :0];
wire [9:0]  sub_sample_cnt;
wire [15:0] interp_test_d;


/////// audio control register ////////
wire audio_enable =     audio_control[0];
wire [1:0] test_d_select =  audio_control[2:1];
/////// test control register ////////
wire [1:0] audio_mux_sel =  test_reg[1:0]; // [0] routes 4 inputs directly to output i2s, inputs: i2sToPcm, interp, sinwave, eq 
wire output_test_en =       test_reg[2];   // [4] selects a fixed output pattern
wire eq_bypass =            test_reg[3];   // [3] bypasses equalizer (for fir tests)
wire sin_select =           test_reg[4];   // [5] 1=sin wave, 0=triangle wave
wire test_left =            test_reg[5];   // [5] 1=left, 0=right
wire [3:0] sin_freq_select =  {2'b00, test_reg[7:6]};

wire sin_test_en = (test_reg[1:0] == 2'b10);

// audio_status register
assign audio_status[0]  = fir_wr_addr_zero;
assign audio_status[1]  = eq_wr_addr_zero;

// test from mux
//assign test_data_out = test_left ? interp_test_d : r_pcm_data[7:0];
//assign test_dout_valid = test_left ? r_mux_valid : intrp_dout_valid;
assign test_dout_valid = l_i2sToPcm_valid;
assign test_data_out = test_left ? l_pcm_data[23:8] : l_pcm_data[15:0];

/* 
/////////////////// FIR Bypass Mux ////////////////////////////

always @ (posedge clk) begin
    if (dsp_bypass) begin
    // routes input i2s directly to output i2s
        dac_bclk <= i2s_bclk;
        dac_lrclk <= i2s_lrclk;
        dac_data <= i2s_d;
    end
    else begin
    // add audio processed output here
        dac_bclk <= pcmToI2S_bclk;
        dac_lrclk <= pcmToI2S_lrclk;
        dac_data <= pcmToI2S_data;
    end
end
/////////////////////////////////////////////////////////////
*/

I2S_to_PCM_Converter i2s_to_pcm(
    .clk            (clk),              // input
    .reset_n        (reset_n),          // input
    .bclk           (i2s_bclk),         // input
    .lrclk          (i2s_lrclk),        // input
    .i2s_data       (i2s_d),            // input
    .l_dout_valid   (l_i2sToPcm_valid), // output strobe     
    .r_dout_valid   (r_i2sToPcm_valid), // output strobe     
    .l_pcm_data     (l_pcm_data),       // [23:0] output
    .r_pcm_data     (r_pcm_data),       // [23:0] output
    .bit_cnt_reg    (i2sToPcm_bit_cnt), // [7:0] output
    .sub_sample_cnt (sub_sample_cnt)    // [9:0] output
);    
    
LinearInterpolator i2s_interpolator (
    .clk                (clk),              // input
    .reset_n            (reset_n),          // input
    .run                (audio_enable),     // input
    .l_din_en           (l_i2sToPcm_valid),       // input
    .r_din_en           (r_i2sToPcm_valid),       // input
    .l_data_in          (l_pcm_data),     // [23:0] input
    .r_data_in          (r_pcm_data),     // [23:0] input
    .sub_sample_cnt     (sub_sample_cnt),    // [9:0] input
    .dout_valid         (intrp_dout_valid), // output
    .l_data_out         (l_intrp_d_out),    // [33:0] output
    .r_data_out         (r_intrp_d_out),     // [33:0] output
    .interp_cnt         (interp_cnt),        // [2:0] output
    // for test
    .test_d_select      (test_d_select),     // audio_control[2:1]
    .test_data          (interp_test_d)     // [15:0] output
);

FIR_Filters filters (
    .clk                (clk),                  // input
    .reset_n            (reset_n),              // input
    .audio_en           (audio_enable),             // input, from audio_control reg
    // coefficient signals
    .coefficient_wr_en  (coef_wr_en),           // input stb when coef wr data in valid
    .coef_select        (filter_select[3:0]),   // [num_of_filters - 1:0] input
    .coef_wr_lsb_data   (coef_wr_lsb_data),     // [7:0] input, cpu reg
    .coef_wr_msb_data   (coef_wr_msb_data),     // [7:0] input, cpu reg
    .taps_per_filter    (taps_per_filter),      // [7:0] input, cpu reg
    .wr_addr_zero       (fir_wr_addr_zero),     // output
    // input signals
    .l_data_en          (intrp_dout_valid),     // input enable strobe 
    .r_data_en          (intrp_dout_valid),     // input enable strobe 
    .l_data_in          (l_intrp_d_out[33:10]),           // [23:0] input
    .r_data_in          (r_intrp_d_out[33:10]),           // [23:0] input
    // output signals
    .l_data_valid       (l_fir_data_valid),     // output valid strobe
    .r_data_valid       (r_fir_data_valid),     // output valid strobe
    .l_data_out         (l_fir_data_out),       // [47:0][num_of_filters] output
    .r_data_out         (r_fir_data_out)        // [47:0][num_of_filters] output
);

// Audio_SRAM_Interface () ->> to do

EqualizerGains eq_gain (
    .clk            (clk),
    .reset_n        (reset_n),
    .run            (audio_enable),
    .bypass         (eq_bypass),
    // cpu interface
    .eq_wr          (eq_wr_en),
    .eq_wr_sel      (filter_select[3:0]),                 // input [num_of_filters - 1 : 0]     
    .eq_rd_sel      (filter_select[7:4]),                 // input [num_of_filters - 1 : 0]     
    .eq_gain_lsb    (eq_wr_lsb_data),                   // input [7:0] 
    .eq_gain_msb    (eq_wr_msb_data),                   // input [7:0]
    .wr_addr_zero   (eq_wr_addr_zero),                     // output status
    // pipe input
    .l_data_en      (l_fir_data_valid),                 // input strobe
    .r_data_en      (r_fir_data_valid),                 // input strobe
    .l_data_in      (l_fir_data_out),                   // input [47:0][num_of_filters - 1 : 0]
    .r_data_in      (r_fir_data_out),                   // input [47:0][num_of_filters - 1 : 0]
    // pipe output
    .l_data_valid   (l_eq_valid),                       // output strobe
    .r_data_valid   (r_eq_valid),                       // output strobe
    .l_data_out     (l_eq_out),                         // output [23:0] 
    .r_data_out     (r_eq_out)                          // output [23:0] 
);


SineWaveGenerator sinGen(
    .clk        (clk),                  // input
    .run        (sin_test_en),          // input, enables sin (or triangle) output
    .sin_select (sin_select),           // input, 1=sin wave, 0=triangle wave
    .freq_sel   (sin_freq_select[3:0]), // input [3:0], selects freq out from a stream
    .data_valid (sin_wave_valid),       // output strobe
    .wave_out   (wave_out),              // output [23:0]
    // for test
    .sin_clken  (sin_clken), 
    .sin_data_valid (sin_gen_valid), 
    .sin_data_ready (sin_data_ready)

);
    


AudioMux aud_output_mux(
    .clk                    (clk),              // input
    .reset_n                (reset_n),          // input
    .run                    (audio_enable),     // input
    .select                 (audio_mux_sel),    // [1:0] input
    
    // i2s_To_Pcm to pcm_to_i2s modules
    .l_i2sToPcm_d_en        (l_i2sToPcm_valid), // input
    .r_i2sToPcm_d_en        (r_i2sToPcm_valid), // input
    .l_i2sToPcm_d           (l_pcm_data),       // [23:0] input
    .r_i2sToPcm_d           (r_pcm_data),       // [23:0] input
    
    // interpolator to pcm_to_i2s modules
    .l_interp_d_en          (intrp_dout_valid), // input
    .r_interp_d_en          (intrp_dout_valid), // input
    .l_interp_d             (l_intrp_d_out[33:10]),    // [23:0] input
    .r_interp_d             (r_intrp_d_out[33:10]),    // [23:0] input
    
    // test sin wave to pcm_to_i2s modules
    .sin_wave_d_en          (sin_wave_valid),   // input, for both l & r
    .sin_wave_d             (wave_out),         // [23:0] input
    
    // equalizer to pcm_to_i2s modules
    .l_eq_d_en              (l_eq_valid),       // input
    .r_eq_d_en              (r_eq_valid),       // input
    .l_eq_d                 (l_eq_out),         // [23:0] input
    .r_eq_d                 (r_eq_out),         // [23:0] input
    
    // mux outputs
    .l_pcmToI2s_d_valid     (l_mux_valid),      // output
    .r_pcmToI2s_d_valid     (r_mux_valid),      // output
    .l_pcmToI2s_d           (l_mux_out),        // [23:0] output
    .r_pcmToI2s_d           (r_mux_out)         // [23:0] output
);



PCM_to_I2S_Converter pcm_to_i2s(
    .clk            (clk),              // input
    .audio_en       (audio_enable),     // input
    .audio_test     (output_test_en),   // input, selects a fixed pattern
    .l_data_en      (l_mux_valid),      // input
    .r_data_en      (r_mux_valid),      // input
    .l_data         (l_mux_out),        // [23:0] input
    .r_data         (r_mux_out),        // [23:0] input
    .bclk           (dac_bclk),         // output
    .lrclk          (dac_lrclk),        // output
    .s_data         (dac_data),         // output
    // for test
    .i2s_valid      (dac_valid)         // output
);    


endmodule

