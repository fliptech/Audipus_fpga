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
    input data_valid_stb,
    input fir_en,                  
    input [15:0] coefficients,
    input [23:0] data_in,
    output [47:0] data_out
);


wire            fir_bypass = 0;
wire [39:0]     mult_dout;

wire fir_clr = !reset_n || data_valid_stb;


fir_tap_multiply fir_tap_mult (
    .CLK    (clk),                  // input wire CLK
    .CE     (fir_en),           // input wire CE
    .SCLR   (fir_clr),              // input wire SCLR
    .B      (data_in),             // input wire [23 : 0] B
    .A      (coefficients),         // input wire [15 : 0] A
    .P      (mult_dout)             // output wire [39 : 0] P);
 );
   
    
    
    
fir_accumulator fir_accum (
  .CLK          (clk),                  // input wire CLK
  .CE           (fir_en),               // input wire CE
  .BYPASS       (fir_bypass),           // input wire BYPASS
  .SCLR         (fir_clr),              // input wire SCL
  .B            (mult_dout[39:8]),      // input wire [31 : 0] B
  .Q            (data_out)              // output wire [47 : 0] Q, latency = 4
);

        
endmodule
