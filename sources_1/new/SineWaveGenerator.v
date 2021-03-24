`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/22/2021 01:50:13 PM
// Design Name: 
// Module Name: SineWaveGenerator
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


module SineWaveGenerator(
    input           clk,
    input           reset_n,
    input           run,
    input [3:0]     clk_inc,
    output          data_valid,
    output [23:0]   sin_out
);

reg [3:0] sin_count;
reg       clken;    
    
sinWaveGen test_sin (
  .aclk                 (clk),                                // input wire aclk
  .aclken               (clken),                // input wire aclken
  .s_axis_phase_tvalid  (s_axis_phase_tvalid),  // input wire s_axis_phase_tvalid
  .s_axis_phase_tdata   (s_axis_phase_tdata),   // input wire [15 : 0] s_axis_phase_tdata
  .m_axis_data_tvalid   (m_axis_data_tvalid),   // output wire m_axis_data_tvalid
  .m_axis_data_tdata    (sin_out)               // output wire [23 : 0] m_axis_data_tdata
);
    
always @ (posedge clk) begin
    if (!reset_n || !run) begin
        sin_count <= 0;
        clken <= 0;
    end
    else if (sin_count == clk_inc) begin
        sin_count <= 0;
        clken <= 1'b1;
    end
    else begin
        sin_count <= sin_count + 1;
        clken <= 0;
    end
end

         
endmodule
