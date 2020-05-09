`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/05/2020 05:48:23 PM
// Design Name: 
// Module Name: spi_Innerface
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


module spi_Interface (
    input clk,
    input reset_n,
    input       spi_cs0,
    input       spi_cs1,
    input       spi_clk,        
    input       spi_mosi,
    output reg  spi_miso,
    output      spi_cs_pcm1792,
    output      spi_cs_pcm9211,
//  registers
    output reg [15:0] control_reg
);


rPi_Interface rpi (
    .clk            (clk),
    .reset_n        (reset_n),
    .spi_cs0        (spi_cs0),
    .spi_clk        (spi_clk),        
    .spi_mosi       (spi_mosi),
    .spi_miso       (spi_miso),
    .reg_read_en    (rd_strobe),
    .reg_write_en   (wr_strobe),
    .spi_addr       (spi_addr),
    .spi_write_data (spi_write_data),
    .spi_read_data  (spi_read_data) 
);


assign spi_cs_pcm1792 = control_reg[0] ? spi_cs1 : 1'b0;
assign spi_cs_pcm9211 = control_reg[0] ? 1'b0 : spi_cs1 ;


//	GENERAL REGISTERS	
//	Write / Read
	parameter CONTROL      = 16'h0000;		// Control Reg


wire    spi_write_data, spi_read_data;


// Register Write
always @ (posedge clk) begin

	if (wr_strobe) begin
//		if (selGeneral) begin
			if (spi_addr == CONTROL)		control_reg		<= spi_write_data;

    end
end

// Register Read
assign spi_read_data = 
            (rd_strobe && (spi_addr == CONTROL))    ?   control_reg :
            16'hdead;
        
endmodule


