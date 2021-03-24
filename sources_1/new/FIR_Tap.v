`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/12/2020 03:53:54 PM
// Design Name: 
// Module Name: FIR_Tap
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


module FIR_Tap (
    input clk,
    input reset_n,
    input audio_en,
    input data_en,                  
    input [15:0] coefficients,
    input [23:0] data_in,
    output [47:0] data_out
);


wire            fir_bypass = 0;
wire [39:0]     mult_dout;
wire [47:0]     firTap_dout;

assign data_out = firTap_dout[47:16];  // barrel shift ???


fir_tap_multiply fir_tap_mult (
    .CLK    (clk),                  // input wire CLK
    .CE     (data_en),           // input wire CE
    .SCLR   (reset_n),              // input wire SCLR
    .B      (data_in),             // input wire [23 : 0] B
    .A      (coefficients),         // input wire [15 : 0] A
    .P      (mult_dout)             // output wire [39 : 0] P);
 );
   
    
    
    
fir_accumulator fir_accum (
  .CLK          (clk),                  // input wire CLK
  .CE           (data_en),              // input wire CE
  .BYPASS       (fir_bypass),           // input wire BYPASS
  .SCLR         (reset_n || audio_en),  // input wire SCL
  .B            (mult_dout[39:8]),      // input wire [31 : 0] B
  .Q            (firTap_dout)           // output wire [47 : 0] Q
);

        
endmodule
