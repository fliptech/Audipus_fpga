`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:  Flip Technologies, Inc.
// Engineer: flip
// 
// Create Date: 05/01/2020 01:49:41 PM
// Design Name: 
// Module Name: AudipusMain
// Project Name: Audipus
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision: x0.01
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
parameter num_of_out_regs = 8;
parameter num_of_in_regs = 4;
parameter num_of_equalizers = 8;

    module AudipusMain (
//        input reset_n,
        output spi_cs_pcm9211_n,
        output spi_cs_pcm1792_n,
        input spi_cs0_n,
        input spi_cs1_n,
        input spi_clk,
        input spi_mosi,
        output tri spi_miso,
        output pcm9211_clk,
        input pcm9211_int0,
        input pcm9211_int1,
        input pcm9211_i2s_sclk,
        input pcm9211_i2s_bclk,
        input pcm9211_i2s_lrclk,
        input pcm9211_i2s_d,
        input pcm9211_mpio0,
        input pcm9211_mpio1,
        inout [3:0] pcm9211_mpioA,
        inout [3:0] pcm9211_mpioB,
        inout [3:0] pcm9211_mpioC,
        output i2s_clk_out,
        input main_clk,
        inout security,
        output dac_rst,
        output dac_sclk,
        output dac_bclk,
        output dac_data,
        output dac_lrclk,
        input dac_zero_r,
        input dac_zero_l,
        output sram_spi_cs,
        output sram_spi_clk,
        inout  [3:0] sram_spi_sio,
        
        input   rPi4,
        input   rPi16,
        input   rPi17,
        input   rPi20,
        input   [27:22] rPix,
        
        
        output reg [16:0]   test,
        output              test_clk,
        inout [9:0]     aux,
        output [3:0]    step_drv,
        output [3:0]    led,
        output          spdif_out
    );
    
parameter num_of_filters = 4;


// System Registers
    
////////////////////
//   CONNECTIONS  //
////////////////////
// audio connections
    wire       coef_wr_en;
    wire       eq_wr_en;
    wire [7:0] audio_status_reg;
    wire [7:0] audio_control_reg;
    wire [7:0] eq_select_reg;
    wire [7:0] eq_shift_reg;
    wire [7:0] coef_select_reg;
    wire [7:0] coefs_per_tap_lsb_reg;
    wire [7:0] fir_coef_msb, fir_coef_lsb;
    wire [7:0] eq_scaler_msb_reg, eq_scaler_lsb_reg;

// sram connections 
    wire [7:0] sram_to_spi_data, spi_to_sram_reg;   
    wire [7:0] sram_control;
// aux connections   
    wire [7:0] aux_reg, test_reg; 
    assign aux = {2'b00, aux_reg};   
// mpio connections    
    wire [7:0] mpio_control_reg;
    wire [7:0] mpio_to_spi_data, spi_to_mpio_reg;
    
    wire [7:0] eq_gain_lsb, eq_gain_msb;
    
    wire            clkGen_i2s_clk;         // 24.576MHz
    assign pcm9211_clk = clkGen_i2s_clk; 
    assign i2s_clk_out = clkGen_i2s_clk; 
    assign dac_sclk = clkGen_i2s_clk; 
    
    wire    pcmToT2S_valid;   
    
    wire    reset_n = 1'b1; // temporary until external reset

    // status register        
    wire [6:0] status_reg = 
        {1'b0, 1'b0, 1'b0, 1'b0, 1'b0, rPi20, rPi17};
    
    // interrupt register
    wire [7:0] interrupt_reg = 
        {1'b0, 1'b0, 1'b0, 1'b0, dac_zero_l, dac_zero_r, 
         pcm9211_int1, pcm9211_int0}; 
 
    
    wire [7:0]  sram_control_reg, i2sToPcm_bit_reg; 
    wire [15:0] test_data_out;
    
    wire [7:0]  fe_test_reg, triangle_inc_reg;
    
    wire        spi_rd_stb, spi_wr_stb;
    
    //test
//    wire [4:0]       spi_bit_count;
//    wire [2:0]       spi_shift_clk;
     // for test
    wire    sin_clken, sin_gen_valid, sin_data_ready;

    wire            shift_in_clken, shift_out_clken;
    wire            miso_tristate;
    wire [6:0]      spi_addr;
    
    wire [7:0]      sram_start_addr;
    

// ASSIGNMENTS

   

//  spi devices cs mux
//  rPix[23:22] select the spi_cs_n for each device
    assign spi_cs_fpga_n = spi_cs0_n || !(!rPix[23] && !rPix[22]);
    assign spi_cs_pcm1792_n = spi_cs0_n || !(!rPix[23] && rPix[22]);
    assign spi_cs_pcm9211_n = spi_cs0_n || !(rPix[23] && !rPix[22]);
//    assign spi_cs_lcd_n = spi_cs0_n || !(rPix[23] && rPix[22]);

    //audio control register
    
    wire i2s_mux = audio_status_reg[7];
    
    assign spdif_out = 1'b0;        // temp << check

         
     // for test
    wire        test_dout_valid;
    wire [7:0]  test_wave; 
    wire [2:0]  interp_cnt;  
     
    
    ClockGeneration system_clks (
        .main_clk   (main_clk),
        .reset_n    (reset_n),
        .sys_clk    (clk),
        .i2s_sclk   (clkGen_i2s_clk),   // 24.576MHz
        .locked     (sys_clk_locked)
    );
    
    Indicators led_lights (
        .clk        (clk),
        .led        (led)       // out[3:0]
    );
    
/////////// SPI  \\\\\\\\\\\    
    spi_Interface sys_reg (        
        .clk                    (clk),
        .reset_n                (reset_n),
// spi signals
        .spi_cs0                (!spi_cs_fpga_n),
        .spi_clk                (spi_clk),        
        .spi_mosi               (spi_mosi),
        .spi_miso               (spi_miso),
// control signals
        .rd_strobe              (spi_rd_stb),
        .wr_strobe              (spi_wr_stb), 
        .coef_wr_stb            (coef_wr_en),
        .eq_wr_stb              (eq_wr_en),
        .rotary_encoder_rd_stb  (rotary_encoder_rd_stb),
//  input registers, input [7:0]
        .status                 (status_reg),       // in [6:0]
        .audio_status           (audio_status_reg),
        .interrupt_input        (interrupt_reg),        // interrupt[7] used
        .sram_to_spi_data       (sram_to_spi_data),           
        .mpio_to_spi_data       (mpio_to_spi_data),
        .rotary_encoder_reg     (rotary_encoder_reg),           
//  output registers, output [7:0]
        // Audio
        .audio_control_reg      (audio_control_reg),
        .coefs_per_tap_lsb_reg  (coefs_per_tap_lsb_reg),
        .coef_select_reg        (coef_select_reg),
        .coef_wr_lsb_data_reg   (fir_coef_lsb),
        .coef_wr_msb_data_reg   (fir_coef_msb),
        .eq_select_reg          (eq_select_reg),
        .eq_scaler_msb_reg      (eq_scaler_msb_reg),
        .eq_scaler_lsb_reg      (eq_scaler_lsb_reg),
        .eq_wr_lsb_data_reg     (eq_gain_lsb),
        .eq_wr_msb_data_reg     (eq_gain_msb),
        //sram
        .sram_control_reg       (sram_control_reg),
        .sram_start_addr_reg    (sram_start_addr),
        .spi_to_sram_reg        (spi_to_sram_reg),
        // mpio
        .mpio_control_reg       (mpio_control_reg),
        .spi_to_mpio_reg        (spi_to_mpio_reg),
        // aux
        .aux_reg                (aux_reg),
        // test
        .test_reg               (test_reg),
        .fe_test_reg            (fe_test_reg),
        .triangle_inc_reg       (triangle_inc_reg),
        .i2sToPcm_bit_reg       (i2sToPcm_bit_reg),
        .shift_in_clken         (shift_in_clken),       
        .shift_out_clken        (shift_out_clken),
        .miso_tristate          (miso_tristate), 
        .spi_addr               (spi_addr)      
    );
/*    
    sram_Interface sQi_interface (        
        .clk            (clk),
        .reset_n        (reset_n),
        .control        (sram_control),         // input [1:0]
        .sQi_cs0        (sram_spi_cs),
        .sQi_clk        (sram_spi_clk), 
        .sQi_sio        (sram_spi_sio),          // inout [3:0] 
        .sram_rd_reg    (sram_to_spi_reg),      // output [15:0]
        .sram_wr_reg    (spi_to_sram_reg)       // input [15:0]
    );
*/    
    
    AudioProcessing aud_proc (
        .clk                (clk),
        .reset_n            (reset_n),
        // input i2s
        .i2s_bclk           (pcm9211_i2s_bclk),
        .i2s_lrclk          (pcm9211_i2s_lrclk),
        .i2s_d              (pcm9211_i2s_d),
        //output i2s
        .audio_enable       (!dac_rst),     // output
        .dac_bclk           (dac_bclk),
        .dac_data           (dac_data),
        .dac_lrclk          (dac_lrclk),
//        .pcmToI2S_valid     (pcmToI2S_valid),
        // audio SRAM interface signals
//        .sram_spi_cs        (spi_cs),
//        .sram_spi_clk       (spi_clk),
//        .sram_spi_sio       (spi_sio),       // inout [3:0]       
        // cpu registers
        .coef_wr_en         (coef_wr_en),
        .eq_wr_en           (eq_wr_en),
        .audio_control      (audio_control_reg),
        .coefs_per_tap_lsb  (coefs_per_tap_lsb_reg),   // msb bit is audio_control[6]
        .coef_select        (coef_select_reg),
        .coef_wr_lsb_data   (fir_coef_lsb),
        .coef_wr_msb_data   (fir_coef_msb),
        .eq_select          (eq_select_reg),
        .eq_scaler_msb_reg  (eq_scaler_msb_reg),
        .eq_scaler_lsb_reg  (eq_scaler_lsb_reg),
        .eq_wr_lsb_data     (eq_gain_lsb),
        .eq_wr_msb_data     (eq_gain_msb),
        .audio_status       (audio_status_reg),
        .test_reg           (test_reg),
        .i2sToPcm_bit_cnt   (i2sToPcm_bit_reg),
        // test
        .test_dout_valid    (test_dout_valid),
        .test_data_out      (test_data_out),
        .fe_test_reg        (fe_test_reg),
        .triangle_inc_reg   (triangle_inc_reg)
    );


    PCM9211_mpio_Interface mpio (
        .mpio_control   (mpio_control_reg),     // input[1:0]
        .mpioa          (pcm9211_mpioA),
        .mpiob          (pcm9211_mpioB),
        .mpioc          (pcm9211_mpioC),
        .mpio_rd_reg    (mpio_to_spi_data),     // output [7:0]
        .mpio_wr_reg    (spi_to_mpio_data)      // input [7:0]
    );
    
    FrontPanel fnt_pnl (
// Common signals
    .clk                    (clk),
    .reset_n                (reset_n),
    .audio_clk_enable,      (test_dout_valid),      // <<< check
    .audio_enable           (!dac_rst),
// Rotary Encoder    
    .encoder_A              (aux[3]),
    .encoder_B              (aux[4]),
    .encoder_sw             (aux[2]),
    .rotary_encoder_rd_stb  (rotary_encoder_rd_stb),
    .rotary_encoder_reg     (rotary_encoder_reg),
    .enc_state_change       (enc_state_change),
//  -VU Meter
    .l_audio_signal,    // input [7:0]
    .r_audio_signal,    // input [7:0]
    .l_VU_pwm,          // output
    .r_VU_pwm,          // output
// test
    .test               // output [15:0]
);        
        
    StepperMotorDrive step_drive (
        .clk            (clk),
        .motor_en       (sram_control_reg[0]),              // input
        .reverse        (sram_control_reg[1]),              // input
        .motor_interval ({2'b00, sram_control_reg[7:2]}),   // input [7:0]
        .step_drv       (step_drv)                          // output [3:0]
        
    );
  

// Test Assignments

/*  SPI Test
    assign test[3:0] = {spi_clk, spi_cs_fpga_n, spi_miso, spi_mosi};
    assign test[4] = spi_rd_stb;
    assign test[5] = spi_wr_stb;
    assign test[6] = shift_out_clken; 
    assign test[7] = shift_in_clken;  
    assign test[8] =  miso_tristate;
    assign test[15:9] = spi_addr;
//    assign test[15:13] = ;
*/ 
// I2S Test
//    assign test[2:0] = {dac_data, dac_lrclk, dac_bclk};
  
    assign test[2:0] = {pcm9211_i2s_d, pcm9211_i2s_lrclk, pcm9211_i2s_bclk};
    assign test[3] = pcm9211_mpio0;
//    assign test[3] = test_dout_valid;
    assign test [15:4] = test_data_out[15:4];
       

/*
always @ (posedge clk) begin
           
    test [15:0] <= test_data_out;
    test[16] <= test_dout_valid;  // clk qualifier
end
*/    
assign test_clk = clk;      

            
    
  
endmodule
