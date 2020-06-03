`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/02/2020 04:57:05 PM
// Design Name: 
// Module Name: sram_Interface
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


module sram_Interface(
    input clk,
    input reset_n,
    input [1:0] control,
    input sQi_cs0,
    input sQi_clk,
    inout [3:0] sQi_sio,
    input [15:0] sram_wr_reg,
    output reg [15:0] sram_rd_reg
);

always @ (posedge control[0]) begin
    sram_rd_reg <= {12'h000,sQi_sio};
end

assign sQi_sio = (control[1] == 1) ?  sram_wr_reg[3:0] : 4'bzzzz;

endmodule
