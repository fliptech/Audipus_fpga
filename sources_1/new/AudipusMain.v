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
        input pcm9211_mpo0,
        input pcm9211_mpo1,
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
        inout   [22:27] rPi4,
        
        
        output [17:0] test,
        inout [9:0] aux,
        output [3:0] step_drv,
        output [3:0] led
    );
    
    wire spi_cs0 = !spi_cs0_n;
    
    wire spi_cs_pcm1792 = control_reg[0] ? spi_cs1_n : 1'b1;
    wire spi_cs_pcm9211 = control_reg[0] ? 1'b1 : spi_cs1_n ;
    
// System Registers
    wire [15:0] control_reg;


    
    ClockGeneration system_clks (
        .main_clk   (main_clk),
        .reset_n    (reset_n),
        .sys_clk    (clk)
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
        .spi_cs_pcm1792 (spi_cs_pcm1792),
        .spi_cs_pcm9211 (spi_cs_pcm9211),
//  registers
        .control_reg    (control_reg),          // out [15:0]
        .eq_tap_sel_reg (eq_tap_sel_reg),       // eq bits 15:10, tap bits 9:0
        .fir_coef_eq01  (fir_coef_eq01)
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


endmodule
