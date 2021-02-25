`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/01/2020 04:05:31 PM
// Design Name: 
// Module Name: rPi_Interface
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


module rPi_Interface # (
    parameter num_of_addr_bits = 7,
    parameter num_of_data_bits = 16    
)(
    input       clk,
    input       reset_n,
    input       spi_cs0,
    input       spi_clk,        
    input       spi_mosi,
    output tri  spi_miso,
    output reg  reg_read_stb,
    output reg  reg_write_stb,
    output reg  [num_of_addr_bits-1:0]  spi_addr,
    output reg  [num_of_data_bits-1:0]  spi_write_data,
    input       [num_of_data_bits-1:0]  spi_read_data 

);

parameter num_of_shift_bits = num_of_addr_bits + num_of_data_bits + 1; 

wire        spi_sel = 1'b0;
reg         shift_in_clken = 0, shift_out_clken = 0;         // spi clk enable
reg         spi_write = 0;                          // spi write / read mode
//reg         spi_miso_data_load = 0;               // loads data to the shift out register
reg         end_spi_addr, end_spi_segment;
reg [4:0]   spi_bit_count = 0;
reg [2:0]   spi_shift_clk;
reg [num_of_shift_bits-1:0] spi_shift_in_data;
reg [num_of_data_bits-1:0]  spi_shift_out_data;

reg         spi_cs0_dly;
reg [num_of_addr_bits-1:0]  rd_spi_addr;
reg [num_of_addr_bits-1:0]  wr_spi_addr;
reg spi_miso_d, miso_tristate;

//assign spi_addr = spi_write ? wr_spi_addr : rd_spi_addr;
assign reg_read_en = end_spi_addr;
assign reg_write_en = end_spi_segment;

assign spi_miso = miso_tristate ? 0'bz : spi_miso_d;

 
// positive / negative spi_clk edge detect and enable    
always @ (posedge clk) begin
    spi_shift_clk[0] <= spi_clk;
    spi_shift_clk[2:1] <= spi_shift_clk[1:0];
    if (spi_shift_clk == 3'b001) begin          // positive edge
        shift_in_clken <= 1'b1;
        shift_out_clken <= 1'b0;
    end
    else if (spi_shift_clk == 3'b110) begin     // negative edge
        shift_out_clken <= 1'b1;
        shift_in_clken <= 1'b0;
    end
    else begin
        shift_in_clken <= 1'b0;
        shift_out_clken <= 1'b0;
    end
end
    
    
// spi shift in register  
always @ (posedge clk) begin
     if (spi_cs0 && shift_in_clken) begin
        spi_shift_in_data[0] <= spi_mosi;
        spi_shift_in_data[num_of_shift_bits-1:1] <= spi_shift_in_data[num_of_shift_bits-2:0];
     end
    else begin
        spi_shift_in_data <= spi_shift_in_data;
    end
end


// spi shift out register  
always @ (posedge clk) begin
     if (spi_cs0 && shift_out_clken) begin
        spi_miso_d <= spi_shift_out_data[num_of_data_bits];
        if  (reg_read_stb) begin   
            spi_shift_out_data[num_of_data_bits-1:0] <=  spi_read_data;
        end
        else begin            
            spi_shift_out_data[0] <= 1'b0;
            spi_shift_out_data[num_of_data_bits-1:1] <= spi_shift_out_data[num_of_data_bits-2:0];
        end
    end
    else begin
        spi_shift_out_data <= spi_shift_out_data;
    end
end

            
// control lines
always @ (posedge clk) begin
    if (!spi_cs0 || !reset_n) begin
        spi_bit_count <= 0;
        spi_write <= spi_write;
        miso_tristate <= 1'b1;
        reg_read_stb <= 0;
    end
    else if (shift_in_clken) begin
        spi_bit_count <= spi_bit_count + 1;
        reg_read_stb <= 0;
        if (spi_bit_count == 5'b00000) begin
            spi_write <= !spi_shift_in_data[0];
            miso_tristate <= 1'b1;
        end
        else if (spi_bit_count == num_of_addr_bits) begin
            reg_read_stb <= 1'b1;
//            spi_addr <= spi_shift_in_data[1:num_of_addr_bits]; //<<<<<<
            spi_addr <= spi_shift_in_data[num_of_addr_bits:1]; //<<<<<<
            spi_shift_in_data[num_of_data_bits-1:0] <=  spi_read_data;
            miso_tristate <= 1'b0;
        end
        else begin
            reg_read_stb <= 0;
            miso_tristate <= miso_tristate;
            spi_write <= spi_write;
            spi_bit_count <= spi_bit_count;
        end
    end
end

always @ (posedge clk) begin
    spi_cs0_dly <= spi_cs0;
    
    if (!reset_n)
        end_spi_segment <= 1'b0;
    else begin
        if (spi_cs0 && !spi_cs0_dly) begin      // end of spi segment
            reg_write_stb <= spi_write;       // write strobe if in write mode
            spi_write_data <= spi_shift_out_data[num_of_data_bits-1:0];
        end    
        else
            end_spi_segment <= 1'b0;
    end
end
        

endmodule
