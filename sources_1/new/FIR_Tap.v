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


module FIR_Tap # (
    parameter num_of_taps = 16
)(
    input clk,
    input reset_n,
    input data_en,                  // a strobe
    input [15:0] coefficients,
    input [23:0] aud_data_in,
    output data_valid,
    output reg [num_of_taps-1:0] coef_addr,
    output [31:0] audio_data_out
);

reg [23:0]      fir_d [num_of_taps-1:0];
reg [23:0]      mux_data;
reg [31:0]      val;
//reg             data_en_dly, process_en;
reg [7:0]       process_cnt;            // change if more than 256 taps

integer i;

// data shift register
always @ (posedge clk) begin 
    if (!reset_n) begin
        for (i = 0; i < num_of_taps; i = i + 1) begin
            fir_d[i] <= 0;
        end
    end
    else if (data_en) begin
        fir_d[0] <= aud_data_in;
        fir_d[num_of_taps-1:1] <= fir_d[num_of_taps-2:0];
    end
    else begin
        fir_d <= fir_d;
    end
end

// coefficient address generator
always @ (posedge clk) begin 
    if (!reset_n) begin
        coef_addr <= 0;
    end
    else begin
        if (data_en && (coef_addr < num_of_taps))
            coef_addr <= coef_addr + 1;
        else 
            coef_addr <= coef_addr;        
    end        
end
            
// datamux
always @ (posedge clk) begin 
    for (i = 0; i < num_of_taps; i = i + 1) begin
        if      ((coef_addr == i) && data_en) mux_data <= fir_d[i];
        else    mux_data <= mux_data;
    end
end    

fir_tap_multiply fir_tap_mult (
    .CLK    (clk),                  // input wire CLK
    .CE     (data_en),           // input wire CE
    .SCLR   (reset_n),              // input wire SCLR
    .B      (mux_data),             // input wire [23 : 0] B
    .A      (coefficients),         // input wire [15 : 0] A
    .P      (mult_dout)             // output wire [39 : 0] P);
 );
   
    
    
    
fir_accumulator fir_accum (
  .CLK          (clk),                  // input wire CLK
  .CE           (data_en),              // input wire CE
  .BYPASS       (fir_bypass),           // input wire BYPASS
  .SCLR         (reset_n),              // input wire SCL
  .B            (mult_dout),            // input wire [31 : 0] B
  .Q            (audio_data_out)        // output wire [47 : 0] Q
);


        
endmodule
