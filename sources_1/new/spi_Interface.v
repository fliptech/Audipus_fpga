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
    parameter num_of_filters = 4    
) (
    input       clk,
    input       reset_n,
    input       spi_cs0,
    input       spi_clk,        
    input       spi_mosi,
    output tri  spi_miso,
//  control signals
    output              rd_strobe,
    output              wr_strobe,
    output reg          coef_wr_stb,
//  registers
    output reg [7:0]    audio_control,
    input [7:0]         status,
    output reg [7:0]    taps_per_filter,
    output reg [7:0]    filter_select,
    output reg [7:0]    aux_reg,
    output reg [7:0]    test_reg,
    output reg [7:0]    coef_wr_lsb_data,
    output reg [7:0]    coef_wr_msb_data,
    input [7:0]         mpio_rd_reg,
    output reg [7:0]    mpio_wr_reg,
    input [7:0]         sram_rd_reg,
    output reg [7:0]    sram_wr_reg
//  for test
        
);

//	GENERAL REGISTERS	
//	Write / Read
	parameter AUD_CONTROL      = 7'h00;		// Audio Control Reg
	parameter STATUS           = 7'h01;		// Status, read only
	parameter NUM_FIR_TAPS     = 7'h02;		// Equalizer Tap select Reg
	parameter FILTER_SEL       = 7'h03;     // Equalizer (or filter number) select
	parameter FIR_COEF_LSB     = 7'h04;    // FIR coeficient lsb based on the selected EQ and EQ_TAP_SEL   
	parameter FIR_COEF_MSB     = 7'h05;    // FIR coeficient msb based on the selected EQ and EQ_TAP_SEL   
	parameter MPIO_SELECT      = 7'h06;		// Equalizer & Tap select Reg
	parameter SRAM             = 7'h07;		// Equalizer & Tap select Reg
	parameter AUX              = 7'h08;		// aux Reg
	parameter TEST             = 7'h09;		// test Reg
	

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
			if (spi_addr == AUD_CONTROL)         audio_control           <= spi_write_data;
			else if (spi_addr == NUM_FIR_TAPS)   taps_per_filter         <= spi_write_data;
			else if (spi_addr == FILTER_SEL)     filter_select           <= spi_write_data;
			else if (spi_addr == FIR_COEF_LSB)   coef_wr_lsb_data        <= spi_write_data;
			else if (spi_addr == FIR_COEF_MSB)   coef_wr_msb_data        <= spi_write_data;
			else if (spi_addr == MPIO_SELECT)    mpio_wr_reg             <= spi_write_data;
			else if (spi_addr == SRAM)           sram_wr_reg             <= spi_write_data;
			else if (spi_addr == AUX)            aux_reg                 <= spi_write_data;
			else if (spi_addr == TEST)           test_reg                <= spi_write_data;

    end
end

// Register Read
assign spi_read_data = 
            (rd_strobe && (spi_addr == AUD_CONTROL))    ?   audio_control :
            (rd_strobe && (spi_addr == STATUS))         ?   status :
            (rd_strobe && (spi_addr == NUM_FIR_TAPS))   ?   taps_per_filter :
            (rd_strobe && (spi_addr == FILTER_SEL))     ?   filter_select :
            (rd_strobe && (spi_addr == MPIO_SELECT))    ?   mpio_rd_reg :
            (rd_strobe && (spi_addr == SRAM))           ?   sram_rd_reg :
            (rd_strobe && (spi_addr == AUX))            ?   aux_reg :
            (rd_strobe && (spi_addr == TEST))           ?   test_reg :
            
            16'hdead;

always @ (posedge clk) begin
    coef_wr_stb <= (spi_addr == FIR_COEF_MSB) && wr_strobe;
end

        
endmodule
