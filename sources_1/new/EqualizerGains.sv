`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/10/2021 02:52:01 PM
// Design Name: 
// Module Name: EqualizerGains
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


module EqualizerGains #(
    parameter num_of_filters = 4
) (
    input clk,
    input reset_n,
    input bypass,
    input eq_wr,
    input [num_of_filters - 1 : 0] eq_wr_sel,    
    input [7:0] eq_gain_lsb,
    input [7:0] eq_gain_msb,
    input [47:0] l_data_in[num_of_filters - 1 : 0],
    input [47:0] r_data_in[num_of_filters - 1 : 0],
    output wr_addr_zero,
    output [23:0] l_data_out,
    output [23:0] r_data_out
);

reg [47:0] audio_out_l, audio_out_r;
reg [num_of_filters - 1 : 0] gain_wr, eq_wr_addr;

wire [63:0] l_mult_out, r_mult_out, l_accum_out, r_accum_out;
wire [15:0] gain;

assign l_data_out[23:0] = l_accum_out[63:40];
assign r_data_out[23:0] = r_accum_out[63:40];

assign wr_addr_zero = (eq_wr_addr == 0);


// coefficient write address generator
//      auto increments eq_wr_addr after every write
always @ (posedge clk) begin 
    if (!reset_n) begin
        eq_wr_addr <= 0;
    end
    else begin
        if (eq_wr) begin                            // msb wr enable
            if (eq_wr_addr == num_of_filters)
                eq_wr_addr <= 0;
            else      
                eq_wr_addr <= eq_wr_addr + 1;
            end
        else 
            eq_wr_addr <= eq_wr_addr;        
    end        
end
            



// Create mux for the number of filters for the Equalizer
    integer i;
    
    always @ (posedge clk) begin
        for (i = 0; i < num_of_filters; i = i + 1) begin
           case (eq_wr_sel) 
                i : audio_out_l <= l_data_in[i];
                default : audio_out_l <= 0;      
           endcase
           case (eq_wr_sel) 
                i : audio_out_r <= r_data_in[i];
                default : audio_out_r <= 0;      
           endcase
            gain_wr[i] <= (eq_wr_sel == i) ?  eq_wr : 1'b0; 
        end
    end
    
// RAM holding the gains for each (16) eq element    
ram_2port_16x16 eq_gain_ram (
  .clk              (clk),                          // input wire clk
  .we               (eq_we),                        // input wire we
  .a                (eq_wr_addr),                   // input wire [3 : 0] a
  .d                ({eq_gain_msb, eq_gain_lsb}),   // input wire [15 : 0] d
  .dpra             (eq_out_cnt),                   // input wire [3 : 0] dpra
  .dpo              (gain)                          // output wire [15 : 0] dpo
);

// defines the weight of each eq element (left chnl)       
mult_48x16 left_eq_mult (
  .CLK              (clk),          // input wire CLK
  .SCLR             (!reset_n),     // input wire SCLR
  .CE               (clken),        // input wire CE
  .A                (audio_out_l),  // input wire [47 : 0] A
  .B                (gain),         // input wire [15 : 0] B
  .P                (l_mult_out)    // output wire [63 : 0] P
);
 
// defines the weight of each eq element (right chnl)       
mult_48x16 right_eq_mult (
  .CLK              (clk),          // input wire CLK
  .SCLR             (!reset_n),     // input wire SCLR
  .CE               (clken),        // input wire CE
  .A                (audio_out_l),  // input wire [47 : 0] A
  .B                (gain),         // input wire [15 : 0] B
  .P                (r_mult_out)    // output wire [63 : 0] P
);

// adds all of the eq elements together (left)
eq_accum left_eq_accum (
  .CLK          (clk),              // input wire CLK
  .CE           (clken),            // input wire CE
  .SCLR         (!reset_n),         // input wire SCLR
  .BYPASS       (bypass),           // input wire BYPASS
  .B            (l_mult_out),       // input wire [63 : 0] B
  .Q            (l_accum_out)       // output wire [63 : 0] Q
);
 
// adds all of the eq elements together (right)
eq_accum right_eq_accum (
  .CLK          (clk),              // input wire CLK
  .CE           (clken),            // input wire CE
  .SCLR         (!reset_n),         // input wire SCLR
  .BYPASS       (bypass),           // input wire BYPASS
  .B            (r_mult_out),       // input wire [63 : 0] B
  .Q            (r_accum_out)       // output wire [63 : 0] Q
);


endmodule
