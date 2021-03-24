`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/23/2021 09:59:35 PM
// Design Name: 
// Module Name: SignalPipeLineDelay
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


module SignalPipeLineDelay #(
    parameter SIG_DLY = 3
) (    
    input clk,
    input reset_n,
    input signal_in,
    output signal_out
);

reg [SIG_DLY:0] signal_delay;

assign signal_out = signal_delay[SIG_DLY];
    
// setting clk delays between audio_en and X_pcm_d_en
always @ (posedge clk) begin
    signal_delay[0] <= signal_in;
    signal_delay[SIG_DLY:1] <= signal_delay[SIG_DLY - 1:0];
end

    
endmodule
