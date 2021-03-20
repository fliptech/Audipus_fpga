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
    parameter num_of_addr_bits = 7,     // includes r/w bit
    parameter num_of_data_bits = 8    
)(
    input       clk,
    input       reset_n,
    input       spi_cs0,
    input       spi_clk,        
    input       spi_mosi,
    output tri  spi_miso,
    output      spi_read_stb,
    output reg  spi_write_stb,
    output reg  [num_of_addr_bits-1:0]  spi_addr,
    output reg  [num_of_data_bits-1:0]  spi_write_data,
    input       [num_of_data_bits-1:0]  spi_read_data,
    output reg                          shift_in_clken,
    output reg                          shift_out_clken,
    output reg                          miso_tristate

);

parameter num_of_shift_bits = num_of_addr_bits + num_of_data_bits + 1;  // +1 for r/w bit

//reg         shift_in_clken, shift_out_clken;        // spi clk enable
reg         spi_write;                                  // spi write / read mode

reg         spi_addr_stb;
assign      spi_read_stb = spi_addr_stb && !spi_write;
//assign      spi_read_stb = spi_addr_stb;                    // <<< for test

reg [4:0]                   spi_bit_count = 0;
reg [2:0]                   spi_shift_clk;
reg [num_of_shift_bits-1:0] spi_shift_in_data;
reg [num_of_data_bits-1:0]  spi_shift_out_data;

reg         spi_cs0_dly;
reg         spi_miso_d;
//reg         miso_tristate;

assign spi_miso = miso_tristate ? 1'bz : spi_miso_d;

 
// positive / negative spi_clk edge detect and enable    
always @ (posedge clk) begin
    spi_shift_clk[0] <= spi_clk;
    spi_shift_clk[2:1] <= spi_shift_clk[1:0];
    if (spi_shift_clk == 3'b011) begin          // positive edge
        shift_in_clken <= 1'b1;
        shift_out_clken <= 1'b0;
    end
    else if (spi_shift_clk == 3'b100) begin     // negative edge
        shift_out_clken <= 1'b1;
        shift_in_clken <= 1'b0;
    end
    else begin
        shift_in_clken <= 1'b0;
        shift_out_clken <= 1'b0;
    end
end
    
    
// spi shift in register ... Master write, Audipus input
always @ (posedge clk) begin
     if (spi_cs0 && shift_in_clken) begin
        spi_shift_in_data[0] <= spi_mosi;
        spi_shift_in_data[num_of_shift_bits-1:1] <= spi_shift_in_data[num_of_shift_bits-2:0];
        
     end
    else begin
        spi_shift_in_data <= spi_shift_in_data;
    end
end



// spi shift out register ... Master rd, Audipus output 
always @ (posedge clk) begin
     if (spi_cs0 && shift_out_clken) begin
        spi_miso_d <= spi_shift_out_data[num_of_data_bits-1];
        if  (spi_bit_count == num_of_addr_bits) begin   
//            spi_shift_out_data[num_of_data_bits-1:0] <=  spi_read_data;
            spi_shift_out_data[num_of_data_bits-1:0] <=  8'h55;             // for test
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

            
// control lines, spi address, and spi master read operation
always @ (posedge clk) begin
    if (!spi_cs0 || !reset_n) begin
        spi_bit_count <= 0;
        spi_write <= spi_write;
        miso_tristate <= 1'b1;
        spi_addr_stb <= 0;
        spi_addr <= 0;
    end
    else begin
        if (shift_in_clken) begin
            spi_bit_count <= spi_bit_count + 1;
            if (spi_bit_count == 5'b00000) begin
                spi_write <= !spi_mosi;
                miso_tristate <= 1'b1;
                spi_addr_stb <= 0;
                spi_addr <= spi_addr;
            end
            else if (spi_bit_count == num_of_addr_bits) begin
                spi_addr_stb <= 1'b1;
    //            spi_addr <= spi_shift_in_data[1:num_of_addr_bits]; //<<<<<<
                spi_addr <= spi_shift_in_data[num_of_addr_bits-1:0];    // lob off the r/w bit7
                miso_tristate <= 1'b0;
            end
            else begin
                spi_addr_stb <= 0;
                miso_tristate <= miso_tristate;
                spi_write <= spi_write;
                spi_addr <= spi_addr;
            end
        end
        else begin
            spi_addr_stb <= 0;
            miso_tristate <= miso_tristate;
            spi_write <= spi_write;
            spi_bit_count <= spi_bit_count;
            spi_addr <= spi_addr;
        end
    end
end

// spi master write operation
always @ (posedge clk) begin
    spi_cs0_dly <= spi_cs0;
    
    if (!reset_n) begin
        spi_write_stb <= 1'b0;
        spi_write_data <= 0;
    end
    else begin
        if (!spi_cs0 && spi_cs0_dly) begin      // end of spi segment
            spi_write_stb <= spi_write;       // write strobe if in write mode
            spi_write_data <= spi_shift_in_data[num_of_data_bits-1:0];
        end    
        else begin
           spi_write_stb <= 1'b0;
           spi_write_data <= spi_write_data;
        end
    end
end
        

endmodule
