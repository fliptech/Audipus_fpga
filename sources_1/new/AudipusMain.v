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
        input reset_n,
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
        
        
        output [17:0]   test,
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
    wire [7:0] filter_select_reg;
    wire [7:0] number_of_taps_reg;
    wire [7:0] fir_coef_msb, fir_coef_lsb;
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
    
    assign pcm9211_clk = i2s_clk_out; 
    
    wire    pcmToT2S_valid;   
    

        
    wire [7:0] status = 
        {1'b0, rPix, rPi20, rPi17, dac_zero_l, dac_zero_r, 
         pcm9211_int1, pcm9211_int0}; 
    
    wire [7:0]   sram_control_reg;
    
    wire        spi_rd_stb, spi_wr_stb;
    
    //test
//    wire [4:0]       spi_bit_count;
//    wire [2:0]       spi_shift_clk;
     // for test
    wire    sin_clken, sin_gen_valid, sin_data_ready;

    wire            shift_in_clken, shift_out_clken;
    wire            miso_tristate;
    wire            clkGen_i2s_clk;
    wire [6:0]      spi_addr;
    
    wire [7:0]      sram_start_addr;
    

// ASSIGNMENTS

   

//  spi devices cs mux
//  rPix[23:22] select the spi_cs_n for each device
    assign spi_cs_fpga_n = spi_cs0_n || !(!rPix[23] && !rPix[22]);
    assign spi_cs_pcm1792_n = spi_cs0_n || !(!rPix[23] && rPix[22]);
    assign spi_cs_pcm9211_n = spi_cs0_n || !(rPix[23] && !rPix[22]);

    //audio control register
    assign spdif_out = 1'b0;        // temp << check


    
    ClockGeneration system_clks (
        .main_clk   (main_clk),
        .reset_n    (reset_n),
        .sys_clk    (clk),
        .i2s_sclk   (clkGen_i2s_clk),
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
//  input registers, input [7:0]
        .status                 (status_reg),
        .audio_status           (audio_status_reg),
        .sram_to_spi_data       (sram_to_spi_data),           
        .mpio_to_spi_data       (mpio_to_spi_data),           
//  output registers, output [7:0]
        // Audio
        .audio_control_reg      (audio_control_reg),
        .taps_per_filter_reg    (number_of_taps_reg),
        .filter_select_reg      (filter_select_reg),
        .coef_wr_lsb_data_reg   (fir_coef_lsb),
        .coef_wr_msb_data_reg   (fir_coef_msb),
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
        .i2s_sclk           (pcm9211_i2s_sclk),
        .i2s_bclk           (pcm9211_i2s_bclk),
        .i2s_lrclk          (pcm9211_i2s_lrclk),
        .i2s_d              (pcm9211_i2s_d),
        .clkGen_i2s_clk     (clkGen_i2s_clk),
        //output i2s
        .audio_enable       (!dac_rst),
        .dac_sclk           (dac_sclk),
        .dac_bclk           (dac_bclk),
        .dac_data           (dac_data),
        .dac_lrclk          (dac_lrclk),
        .pcmToI2S_valid     (pcmToI2S_valid),
        // audio SRAM interface signals
//        .sram_spi_cs        (spi_cs),
//        .sram_spi_clk       (spi_clk),
//        .sram_spi_sio       (spi_sio),       // inout [3:0]       
        // cpu registers
        .coef_wr_en         (coef_wr_en),
        .eq_wr_en           (eq_wr_en),
        .audio_control      (audio_control_reg),
        .filter_select      (filter_select_reg),
        .sin_freq_select    (test_reg[3:0]),
        .taps_per_filter    (number_of_taps_reg),
        .coef_wr_lsb_data   (fir_coef_lsb),
        .coef_wr_msb_data   (fir_coef_msb),
        .eq_wr_lsb_data     (eq_gain_lsb),
        .eq_wr_msb_data     (eq_gain_msb),
        .audio_status       (audio_status_reg),
        // test
        .sin_wave_valid     (test[5]),
        .wave               (test[15:8]),
        // for test
        .sin_clken          (test[3]), 
        .sin_data_valid     (test[6]), 
        .sin_data_ready     (test[7])
        
    );
    

    PCM9211_mpio_Interface mpio (
        .mpio_control   (mpio_control_reg),     // input[1:0]
        .mpioa          (pcm9211_mpioA),
        .mpiob          (pcm9211_mpioB),
        .mpioc          (pcm9211_mpioC),
        .mpio_rd_reg    (mpio_to_spi_data),     // output [7:0]
        .mpio_wr_reg    (spi_to_mpio_data)      // input [7:0]
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
    assign test[2:0] = {dac_data, dac_lrclk, dac_bclk};
    assign test[4] = pcmToI2S_valid;
    assign test[17] = clk;      

  
endmodule
