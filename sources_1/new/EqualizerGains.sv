`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/10/2021 02:52:01 PM
// Design Name: 
// Module Name: EqualizerGains
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


module EqualizerGains #(
    parameter num_of_filters = 4
) (
    input clk,
    input reset_n,
    input eq_wr,
    input [num_of_filters - 1 : 0] eq_wr_sel,    
    input [15:0] eq_gain,
    input [47:0] l_audio_din[num_of_filters - 1 : 0],
    input [47:0] r_audio_din[num_of_filters - 1 : 0],
    output [23:0] l_audio_dout,
    output [23:0] r_audio_dout
);

reg [47:0] audio_out_l, audio_out_r;

assign l_audio_dout[23:0] = audio_out_l[47:24];
assign r_audio_dout[23:0] = audio_out_r[47:24];


// Generate the number of filters for the Equalizer
    integer i;
    
    always @ (posedge clk) begin
        for (i = 0; i < num_of_filters; i = i + 1) begin
           case (eq_wr_sel) 
                i : audio_out_l <= l_audio_din[i];
                default : audio_out_l <= 0;      
           endcase
           case (eq_wr_sel) 
                i : audio_out_r <= r_audio_din[i];
                default : audio_out_r <= 0;      
           endcase
        end
    end
        
 

endmodule
