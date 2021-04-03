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


module SineWaveGenerator # (
    parameter BCLK_DIV = 8
)(
    input               clk,
    input               run,
    input [3:0]         freq_sel,   // [3:0] => ... 4125Hz, 2250Hz, 562Hz, 93Hz
    output reg          data_valid,
    output reg [23:0]   sin_out
);

reg [3:0] sin_count;
reg [BCLK_DIV-1:0] clken_count;
reg       clken; 

wire [23:0] sin_data_out;
wire [15:0] m_axis_phase_tdata;
    
sinWaveGen test_sin (
  .aclk                 (clk),                  // input wire aclk
  .aclken               (clken),                // input wire aclken
  .m_axis_data_tvalid   (sin_data_valid),       // output wire m_axis_data_tvalid
  .m_axis_data_tready   (run),                  // input wire m_axis_data_tready
  .m_axis_data_tdata    (sin_data_out),         // output wire [23 : 0] m_axis_data_tdata
  // the rest below is not used
  .m_axis_phase_tvalid  (m_axis_phase_tvalid),  // input wire s_axis_phase_tvalid
  .m_axis_phase_tready  (run),                  // input wire m_axis_phase_tready
  .m_axis_phase_tdata   (m_axis_phase_tdata),   // input wire [15 : 0] s_axis_phase_tdata
  .event_pinc_invalid   (event_pinc_invalid)    // output wire event_pinc_invalid
);

// sin_data_out provides a multiple output stream of different defined frequencies, in a defined order
// sin_count[3:0] => 4125Hz, 2250Hz, 562Hz, 93Hz :: order 0=>3
always @ (posedge clk) begin
    if (!sin_data_valid || !run) begin
        sin_count <= 0;
        sin_out <= 0;
        data_valid <= 1'b0;
    end
    else if (sin_count == freq_sel) begin
        sin_count <= sin_count + 1;;
        sin_out <= sin_data_out;
        data_valid <= 1'b1;
    end
    else begin
        sin_count <= sin_count + 1;
        sin_out <= sin_out;
        data_valid <= 1'b0;
    end
end

always @ (posedge clk) begin
    if (!sin_data_valid || !run) begin
        clken_count <= 0;
        clken <= 1'b0;
    end
    else if (clken_count == freq_sel) begin
        clken_count <= clken_count + 1;;
        clken <= 1'b1;
    end
    else begin
        clken_count <= clken_count + 1;
        clken <= 1'b0;
    end
end

         
endmodule
