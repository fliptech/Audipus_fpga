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


module spi_Interface # (
    parameter taps_per_filter = 4
) (
    input clk,
    input reset_n,
    input       spi_cs0,
    input       spi_clk,        
    input       spi_mosi,
    output      spi_miso,
//  registers
    output reg [15:0]   control_reg,
    output reg [15:0]   eq_tap_sel_reg,                       // eq bits 15:10, tap bits 9:0
    input [15:0]        mpio_rd_reg,                       // eq bits 15:10, tap bits 9:0
    output reg [15:0]   mpio_wr_reg,                       // eq bits 15:10, tap bits 9:0
    input [15:0]        sram_rd_reg,                       // eq bits 15:10, tap bits 9:0
    output reg [15:0]   sram_wr_reg,                       // eq bits 15:10, tap bits 9:0
    input [15:0]        status,
    output reg [15:0]   motor_interval,
    output reg [15:0]   aux_port,
    output reg [15:0]   test_port,
    output reg [15:0]   fir_coef_eq01[taps_per_filter-1:0]
);

//	GENERAL REGISTERS	
//	Write / Read
	parameter CONTROL          = 16'h0000;		// Control Reg
	parameter EQ_TAP_SEL       = 16'h0001;		// Equalizer & Tap select Reg
	parameter MPIO_SEL         = 16'h0002;		// Equalizer & Tap select Reg
	parameter SRAM_SEL         = 16'h0003;		// Equalizer & Tap select Reg
	parameter STATUS           = 16'h0004;		// Equalizer & Tap select Reg
	parameter MOTOR            = 16'h0005;		// Equalizer & Tap select Reg
	parameter AUX              = 16'h0006;		// Equalizer & Tap select Reg
	parameter TEST             = 16'h0007;		// Equalizer & Tap select Reg
	


rPi_Interface rpi (
    .clk            (clk),
    .reset_n        (reset_n),
    .spi_cs0        (spi_cs0),
    .spi_clk        (spi_clk),        
    .spi_mosi       (spi_mosi),     // input
    .spi_miso       (spi_miso),     // output tri
    .reg_read_stb   (rd_strobe),
    .reg_write_stb  (wr_strobe),
    .spi_addr       (spi_addr),
    .spi_write_data (spi_write_data),
    .spi_read_data  (spi_read_data) 
);





wire    spi_write_data, spi_read_data;


// Register Write
always @ (posedge clk) begin

	if (wr_strobe) begin
//		if (selGeneral) begin
			if (spi_addr == CONTROL)                 control_reg         <= spi_write_data;
			else if (spi_addr == EQ_TAP_SEL)         eq_tap_sel_reg      <= spi_write_data;
			else if (spi_addr == MPIO_SEL)           mpio_wr_reg         <= spi_write_data;
			else if (spi_addr == SRAM_SEL)           sram_wr_reg         <= spi_write_data;
			else if (spi_addr == MOTOR)              motor_interval      <= spi_write_data;
			else if (spi_addr == AUX)                aux_port            <= spi_write_data;
			else if (spi_addr == TEST)               test_port           <= spi_write_data;

    end
end

// Register Read
assign spi_read_data = 
            (rd_strobe && (spi_addr == CONTROL))        ?   control_reg :
            (rd_strobe && (spi_addr == EQ_TAP_SEL))     ?   eq_tap_sel_reg :
            (rd_strobe && (spi_addr == MPIO_SEL))       ?   mpio_rd_reg :
            (rd_strobe && (spi_addr == SRAM_SEL))       ?   sram_rd_reg :
            (rd_strobe && (spi_addr == STATUS))         ?   status :
            (rd_strobe && (spi_addr == MOTOR))          ?   motor_interval :
            
            16'hdead;
        
endmodule


