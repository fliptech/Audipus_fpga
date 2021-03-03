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
    parameter taps_per_filter = 8,
    parameter num_of_filters = 4
    
) (
    input clk,
    input reset_n,
    input       spi_cs0,
    input       spi_clk,        
    input       spi_mosi,
    output tri  spi_miso,
//  registers
    output reg [7:0]   control_reg,
    output reg [7:0]   eq_tap_sel_reg,                       // eq bits 15:10, tap bits 9:0
    input [7:0]        mpio_rd_reg,                       // eq bits 15:10, tap bits 9:0
    output reg [7:0]   mpio_wr_reg,                       // eq bits 15:10, tap bits 9:0
    input [7:0]        sram_rd_reg,                       // eq bits 15:10, tap bits 9:0
    output reg [7:0]   sram_wr_reg,                       // eq bits 15:10, tap bits 9:0
    input [7:0]        status,
    output reg [7:0]   motor_interval,
    output reg [7:0]   aux_port,
    output reg [7:0]   test_port,
    output reg [7:0][taps_per_filter-1:0]   fir_coef_lsb[num_of_filters-1:0],
    output reg [7:0][taps_per_filter-1:0]   fir_coef_msb[num_of_filters-1:0],
//  for test
    output              rd_strobe,
    output              wr_strobe
        
);

//	GENERAL REGISTERS	
//	Write / Read
	parameter CONTROL          = 7'h00;		// Control Reg
	parameter STATUS           = 7'h01;		// Status, read only
	parameter FILTER_TAP_SEL   = 7'h02;		// Equalizer Tap select Reg
	parameter FILTER_SEL       = 7'h03;     // Equalizer (or filter number) select
	parameter FIR_COEF_LSB     = 7'h04;    // FIR coeficient lsb based on the selected EQ and EQ_TAP_SEL   
	parameter FIR_COEF_MSB     = 7'h05;    // FIR coeficient msb based on the selected EQ and EQ_TAP_SEL   
	parameter AUX              = 7'h06;		// aux Reg
	parameter TEST             = 7'h07;		// test Reg
	parameter MPIO_SEL         = 7'h03;		// Equalizer & Tap select Reg
	parameter SRAM_SEL         = 7'h04;		// Equalizer & Tap select Reg
	parameter MOTOR            = 7'h05;		// Equalizer & Tap select Reg
	parameter MPIO             = 7'h08;		// Equalizer & Tap select Reg
	

    reg filter_tap, filter;

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
			if (spi_addr == CONTROL)                 control_reg                         <= spi_write_data;
			else if (spi_addr == FILTER_TAP_SEL)     filter_tap                          <= spi_write_data;
			else if (spi_addr == FILTER_SEL)         filter                              <= spi_write_data;
			else if (spi_addr == MPIO_SEL)           mpio_wr_reg                         <= spi_write_data;
			else if (spi_addr == SRAM_SEL)           sram_wr_reg                         <= spi_write_data;
			else if (spi_addr == MOTOR)              motor_interval                      <= spi_write_data;
			else if (spi_addr == AUX)                aux_port                            <= spi_write_data;
			else if (spi_addr == TEST)               test_port                           <= spi_write_data;
			else if (spi_addr == FIR_COEF_LSB)       fir_coef_lsb[filter_tap][filter]    <= spi_write_data;
			else if (spi_addr == FIR_COEF_MSB)       fir_coef_msb[filter_tap][filter]    <= spi_write_data;

    end
end

// Register Read
assign spi_read_data = 
            (rd_strobe && (spi_addr == CONTROL))        ?   control_reg :
            (rd_strobe && (spi_addr == STATUS))         ?   status :
            (rd_strobe && (spi_addr == FILTER_TAP_SEL)) ?   filter_tap_reg :
            (rd_strobe && (spi_addr == FILTER_SEL))     ?   filter_reg :
            (rd_strobe && (spi_addr == MPIO_SEL))       ?   mpio_rd_reg :
            (rd_strobe && (spi_addr == SRAM_SEL))       ?   sram_rd_reg :
            (rd_strobe && (spi_addr == MOTOR))          ?   motor_interval :
            (rd_strobe && (spi_addr == TEST))           ?   test_port :
            
            16'hdead;
        
endmodule


