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
    parameter num_of_filters = 4,    
    parameter num_of_addr_bits = 7,     // includes r/w bit
    parameter num_of_data_bits = 8    
) (
    input       clk,
    input       reset_n,
// spi_signals
    input       spi_cs0,
    input       spi_clk,        
    input       spi_mosi,
    output tri  spi_miso,
//  control signals
    output              rd_strobe,
    output              wr_strobe,
    output reg          coef_wr_stb,
    output reg          eq_wr_stb,
//  input registers
    input [7:0]         status,  
    input [7:0]         sram_to_spi_data,
    input [7:0]         mpio_to_spi_data,
     
//  output registers
    // Audio
    output reg [7:0]    audio_control_reg,
    output reg [7:0]    taps_per_filter_reg,
    output reg [7:0]    filter_select_reg,
    output reg [7:0]    coef_wr_lsb_data_reg,
    output reg [7:0]    coef_wr_msb_data_reg,
    output reg [7:0]    eq_wr_lsb_data_reg,
    output reg [7:0]    eq_wr_msb_data_reg,
    // sram
    output reg [7:0]    sram_control_reg,
    output reg [7:0]    sram_start_addr_reg,
    output reg [7:0]    spi_to_sram_reg,
    // mpio
    output reg [7:0]    mpio_control_reg,
    output reg [7:0]    spi_to_mpio_reg,
//  aux
    output reg [7:0]    aux_reg,
    output [4:0]        spi_bit_count,
    output [2:0]        spi_shift_clk,
    output              shift_in_clken
       
);

reg filter_tap, filter;
      
wire [num_of_data_bits-1:0]  spi_write_data, spi_read_data;
wire [num_of_addr_bits-1:0]  spi_addr;


//	GENERAL REGISTERS	
//	Write / Read
	parameter AUD_CONTROL      = 7'h00;    // Audio Control Reg
	parameter STATUS           = 7'h01;    // Status, write only
	parameter NUM_FIR_TAPS     = 7'h02;    // Number of taps per filter
	parameter FILTER_SEL       = 7'h03;    // Filter to be accessed, max. number = parameter num_of_filters
	parameter FIR_COEF_LSB     = 7'h04;    // FIR coeficient lsb based on the selected EQ and EQ_TAP_SEL   
	parameter FIR_COEF_MSB     = 7'h05;    // FIR coeficient msb based on the selected EQ and EQ_TAP_SEL   
	parameter AUX              = 7'h06;    // aux Reg (tbd)
	parameter SRAM_CONTROL     = 7'h07;    // test Reg
	parameter SRAM_ADDR        = 7'h08;    // selects sram start address for auto-increment
	parameter SPI_TO_SRAM      = 7'h09;    // write, sram->spi, for a given page, addr is auto-incremented
	parameter SRAM_TO_SPI      = 7'h0a;    // read, spi->sram, for a given page, addr is auto-incremented
	parameter MPIO_CONTROL     = 7'h0b;    // selects: which MPIO to be accressed, IO direction for eack bit
	parameter SPI_TO_MPIO      = 7'h0c;    // write, mpio->spi, for selected mpio and based on IO directions      
	parameter MPIO_TO_SPI      = 7'h0d;    // read, spi->mpio for selected mpio and based on IO directions
	parameter EQ_GAIN_LSB      = 7'h0e;    // FIR coeficient lsb based on the selected EQ and EQ_TAP_SEL   
	parameter EQ_GAIN_MSB      = 7'h0f;    // FIR coeficient msb based on the selected EQ and EQ_TAP_SEL   
	



rPi_Interface rpi (
    .clk            (clk),
    .reset_n        (reset_n),
    .spi_cs0        (spi_cs0),
    .spi_clk        (spi_clk),        
    .spi_mosi       (spi_mosi),     // input
    .spi_miso       (spi_miso),     // output tri
    .spi_read_stb   (rd_strobe),
    .spi_write_stb  (wr_strobe),
    .spi_addr       (spi_addr),
    .spi_write_data (spi_write_data),
    .spi_read_data  (spi_read_data),
    .spi_bit_count  (spi_bit_count),
    .spi_shift_clk  (spi_shift_clk),
    .shift_in_clken (shift_in_clken) 
);


// Register Write
always @ (posedge clk) begin

	if (wr_strobe) begin
//		if (selGeneral) begin
			if (spi_addr == AUD_CONTROL)         audio_control_reg           <= spi_write_data;
			else if (spi_addr == NUM_FIR_TAPS)   taps_per_filter_reg         <= spi_write_data;
			else if (spi_addr == FILTER_SEL)     filter_select_reg           <= spi_write_data;
			else if (spi_addr == FIR_COEF_LSB)   coef_wr_lsb_data_reg        <= spi_write_data;
			else if (spi_addr == FIR_COEF_MSB)   coef_wr_msb_data_reg        <= spi_write_data;
			else if (spi_addr == EQ_GAIN_LSB)    eq_wr_lsb_data_reg          <= spi_write_data;
			else if (spi_addr == EQ_GAIN_MSB)    eq_wr_msb_data_reg          <= spi_write_data;
			else if (spi_addr == SRAM_CONTROL)   sram_control_reg            <= spi_write_data;
			else if (spi_addr == SRAM_ADDR)      sram_start_addr_reg         <= spi_write_data;
			else if (spi_addr == SPI_TO_SRAM)    spi_to_sram_reg             <= spi_write_data;
			else if (spi_addr == MPIO_CONTROL)   mpio_control_reg            <= spi_write_data;
			else if (spi_addr == SPI_TO_MPIO)    spi_to_mpio_reg             <= spi_write_data;
			else if (spi_addr == AUX)            aux_reg                     <= spi_write_data;

    end
end

// Register Read
assign spi_read_data = 
            (rd_strobe && (spi_addr == AUD_CONTROL))    ?   audio_control_reg :
            (rd_strobe && (spi_addr == STATUS))         ?   status :
            (rd_strobe && (spi_addr == NUM_FIR_TAPS))   ?   taps_per_filter_reg :
            (rd_strobe && (spi_addr == FILTER_SEL))     ?   filter_select_reg :
            (rd_strobe && (spi_addr == SRAM_CONTROL))   ?   sram_control_reg :
            (rd_strobe && (spi_addr == SRAM_ADDR))      ?   sram_start_addr_reg :
            (rd_strobe && (spi_addr == SRAM_TO_SPI))    ?   sram_to_spi_data :
            (rd_strobe && (spi_addr == MPIO_CONTROL))   ?   mpio_control_reg :
            (rd_strobe && (spi_addr == MPIO_TO_SPI))    ?   mpio_to_spi_data :
            (rd_strobe && (spi_addr == AUX))            ?   aux_reg :
            
            8'hc3;

always @ (posedge clk) begin
    coef_wr_stb <= (spi_addr == FIR_COEF_MSB) && wr_strobe;
    eq_wr_stb <= (spi_addr == EQ_GAIN_MSB) && wr_strobe;
end

        
endmodule
