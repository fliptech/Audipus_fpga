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
        output spi_miso,
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
        output pcm9211_i2s_clk_out,
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
        
        inout   rPi4,
        inout   rPi16,
        inout   rPi17,
        inout   rPi20,
        inout   [27:22] rPix,
        
        
        output [17:0]   test,
        inout [9:0]     aux,
        output [3:0]    step_drv,
        output [3:0]    led,
        output          spdif_out
    );
    
parameter taps_per_filter = 4;

// System Registers
    
    assign pcm9211_clk = pcm9211_i2s_clk_out;       // << check
    assign spdif_out = control_reg[7];              // temp

    wire [15:0] control_reg;
    wire [15:0] mpio_rd_reg, mpio_rd_reg;

    wire spi_cs0 = !spi_cs0_n;
    
    wire [1:0] mpio_control = control_reg[3:2];
    wire [1:0] sram_control = control_reg[5:4];
    
    wire spi_cs_pcm1792 = control_reg[0] ? spi_cs1_n : 1'b1;
    wire spi_cs_pcm9211 = control_reg[0] ? 1'b1 : spi_cs1_n ;
    wire [15:0] status = 
        {2'b00, rPix, rPi20, rPi17, rPi16, rPi4, 
         pcm9211_int1, pcm9211_int0, pcm9211_mpio0, pcm9211_mpio1}; 

    wire [15:0]   fir_coef_eq01[taps_per_filter-1:0];

    
    ClockGeneration system_clks (
        .main_clk   (main_clk),
        .reset_n    (reset_n),
        .sys_clk    (clk),
        .i2s_sclk    (pcm9211_i2s_clk_out),
        .locked     (sys_clk_locked)
    );
    
    Indicators led_lights (
        .clk        (clk),
        .led        (led)       // out[3:0]
    );
    
    spi_Interface sys_reg (        
        .clk            (clk),
        .reset_n        (reset_n),
        .spi_cs0        (spi_cs0),
        .spi_clk        (spi_clk),        
        .spi_mosi       (spi_mosi),
        .spi_miso       (spi_miso),
//  registers
        .control_reg    (control_reg),          // out [15:0]
        .eq_tap_sel_reg (eq_tap_sel_reg),       // eq bits 15:10, tap bits 9:0
        .mpio_rd_reg    (mpio_rd_reg),
        .mpio_wr_reg    (mpio_wr_reg),
        .status         (status),                // input [9:0]
        .motor_interval (motor_interval),
        .aux_port       (aux),
        .test_port      (test),
        .fir_coef_eq01  (fir_coef_eq01)
    );
    
    sram_Interface sQi_interface (        
        .clk            (clk),
        .reset_n        (reset_n),
        .control        (sram_control),         // input [1:0]
        .sQi_cs0        (sram_spi_cs),
        .sQi_clk        (sram_spi_clk), 
        .sQi_sio        (sram_spi_sio),          // inout [3:0] 
        .sram_rd_reg    (sram_rd_reg),          // output [15:0]
        .sram_wr_reg    (sram_wr_reg)           // input [15:0]
    );
    
    
    AudioProcessing (
        .clk            (clk),
        .reset_n        (reset_n),
        .bypass         (control_reg[1]),
        .i2s_sclk       (pcm9211_i2s_sclk),
        .i2s_bclk       (pcm9211_i2s_bclk),
        .i2s_lrclk      (pcm9211_i2s_lrclk),
        .i2s_d          (pcm9211_i2s_d),
        
        .dac_rst        (dac_rst),
        .dac_sclk       (dac_sclk),
        .dac_bclk       (dac_bclk),
        .dac_data       (dac_data),
        .dac_lrclk      (dac_lrclk),
        .dac_zero_r     (dac_zero_r),
        .dac_zero_l     (dac_zero_l),
        
        .sram_spi_cs    (spi_cs),
        .sram_spi_clk   (spi_clk),
        .sram_spi_sio   (spi_sio),       // inout [3:0]
        
        .fir_coef_eq01  (fir_coef_eq01)
    );

    PCM9211_mpio_Interface (
        .mpio_control   (mpio_control),     // input[1:0]
        .mpioa          (pcm9211_mpioA),
        .mpiob          (pcm9211_mpioB),
        .mpioc          (pcm9211_mpioC),
        .mpio_rd_reg    (mpio_rd_reg),      // output [15:0]
        .mpio_wr_reg    (mpio_wr_reg)       // input [15:0]
    );
        
/*    StepperMotorDrive step_drive (
        .clk            (clk),
        .motor_interval (motor_interval),   // input [15:0]
        .step_drv       (step_drv)          // output [3:0]
        
    );
*/    
endmodule
