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
    input fir_mult_clr,
    input fir_accum_clr,
    input fir_en,                  
    input fir_accum_en,                  
    input [15:0] coefficients,
    input [23:0] data_in,
    output [11:0] test_out,
    output reg [47:0] data_out
);


wire            fir_bypass = 0;
wire [39:0]     mult_dout;


wire [47:0] accum_out;

//assign test_out = mult_dout[19:8];
assign test_out = {mult_dout[11:8], data_in[11:8], coefficients[3:0]};


fir_tap_multiply fir_tap_mult (
    .CLK    (clk),                  // input wire CLK
    .CE     (fir_en),               // input wire CE
    .SCLR   (fir_mult_clr),         // input wire SCLR overides CE
    .B      (data_in),              // input wire [23 : 0] B
    .A      (coefficients),         // input wire [15 : 0] A
    .P      (mult_dout)             // output wire [39 : 0] P);
 );
   
    
    
    
fir_accumulator fir_accum (
  .CLK          (clk),                  // input wire CLK
  .CE           (fir_accum_en),         // input wire CE
  .BYPASS       (fir_bypass),           // input wire BYPASS
  .SCLR         (fir_accum_clr),        // input wire SCL overides CE
  .B            (mult_dout[39:8]),      // input wire [31 : 0] B
  .Q            (accum_out)             // output wire [47 : 0] Q, latency = 1
);


// output hold
always @ (posedge clk) begin
    if (fir_accum_clr)
        data_out <= accum_out;
    else
        data_out <= data_out;
end
        
endmodule
