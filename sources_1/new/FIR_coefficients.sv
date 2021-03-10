`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2021 10:59:16 AM
// Design Name: 
// Module Name: FIR_coefficients
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


module FIR_coefficients #(
    parameter num_of_filters = 4
)(    
    input           clk,
    input           reset_n,
    input           coef_rst,
    input           wr_en,
    input           rd_en,
    input [7:0]     coef_wr_lsb_data,
    input [7:0]     coef_wr_msb_data,
    input [7:0]     taps_per_filter,
    input [7:0]     coef_rd_addr,
    output          wr_addr_zero,
    output [15:0]   coefficients
);
    
       
    reg [7:0] coef_wr_addr;
    
    assign wr_addr_zero = (coef_wr_addr == 0);
    
            
// coefficient write address generator
always @ (posedge clk) begin 
    if (!reset_n) begin
        coef_wr_addr <= 0;
    end
    else begin
        if (wr_en) begin                            // msb wr enable
            if (coef_wr_addr == taps_per_filter)
                coef_wr_addr <= 0;
            else      
                coef_wr_addr <= coef_wr_addr + 1;
            end
        else 
            coef_wr_addr <= coef_wr_addr;        
    end        
end
            
 
 
coef_ram FIR_coef_ram (
    .clk(clk),                                  // input wire clk
    .we(wr_en),                                 // input wire we
    .a(coef_wr_addr),                           // input wire [7 : 0] a
    .d({coef_wr_msb_data, coef_wr_lsb_data}),   // input wire [15 : 0] d
    .dpra(coef_rd_addr),                        // input wire [7 : 0] dpra
    .dpo(coefficients)                          // output wire [15 : 0] dpo
);           
    
endmodule
