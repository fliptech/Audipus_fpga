`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/31/2020 05:09:44 PM
// Design Name: 
// Module Name: PCM9211_mpio_Interface
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


module PCM9211_mpio_Interface(
    input [7:0]     mpio_control,
//    input           mpio_cs,
//    input           mpio_rd,
//    input           mpio_wr,
    inout [3:0]     mpioa,
    inout [3:0]     mpiob,
    inout [3:0]     mpioc,
    input [7:0]        mpio_wr_reg,
    output reg [7:0]   mpio_rd_reg
);

reg [3:0] mpioa_reg, mpiob_reg, mpioc_reg;

always @ (posedge mpio_control[0]) begin
    mpio_rd_reg <= {mpiob, mpioa};
//    mpio_rd_reg <= {4'b0000, mpioc, mpiob, mpioa};
end

assign mpioa = (mpio_control[1] == 1) ?  mpio_wr_reg[3:0] : 4'bzzzz;
assign mpiob = (mpio_control[1] == 1) ?  mpio_wr_reg[7:4] : 4'bzzzz;
//assign mpioc = (mpio_control[1] == 1) ?  mpio_wr_reg[11:8] : 4'bzzzz;

endmodule

