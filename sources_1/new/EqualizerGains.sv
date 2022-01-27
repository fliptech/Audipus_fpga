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
    input run,
//    input bypass,           // choses one filter
    // cpu interface
    input eq_wr,
    input eq_wr_rst,
    input [3:0] eq_wr_sel,    
    input [3:0] eq_rd_sel,    
    input [7:0] eq_gain_lsb,
    input [7:0] eq_gain_msb,
    output wr_addr_zero,
    // pipe input
    input l_data_en,        // expecting a strobe
    input r_data_en,        // expecting a strobe
    input [47:0] l_data_in[3:0],
    input [47:0] r_data_in[3:0],
    // pipe output
    output l_data_valid,
    output r_data_valid,
    output [23:0] l_data_out,
    output [23:0] r_data_out,
    output [15:0] eq_test_d,
    output eq_test_en
    
);

reg eq_run, eq_wr_dly, eq_valid_stb;
reg [47:0] audio_out_l, audio_out_r;
reg [3:0] eq_wr_addr, eq_rd_addr, eq_rd_addr_dly;
reg [1:0] eq_run_dly;

wire [63:0] l_mult_out, r_mult_out, l_accum_out, r_accum_out;
wire [15:0] gain;
wire clken = 1'b1;
wire bypass = 1'b0;

assign l_data_valid = eq_valid_stb;
assign r_data_valid = eq_valid_stb;

// truncation
assign l_data_out[23:0] = l_accum_out[63:40];
assign r_data_out[23:0] = r_accum_out[63:40];

assign wr_addr_zero = (eq_wr_addr == 0);



//wire [3:0] eq_rd_addr = bypass ? eq_rd_sel : eq_rd_count;
//wire [3:0] eq_rd_addr = eq_rd_count;

// coefficient write address generator
//      auto increments eq_wr_addr after every write
always @ (posedge clk) begin
    eq_wr_dly <= eq_wr; 
    if (!reset_n || eq_wr_rst) begin
        eq_wr_addr <= 0;
    end
    else begin
        if (eq_wr_dly)                            // msb wr enable
            eq_wr_addr <= eq_wr_addr + 1;
        else 
            eq_wr_addr <= eq_wr_addr;        
    end        
end
            

// coefficient read address generator
always @ (posedge clk) begin 
    if (!reset_n || !run)
        eq_run <= 1'b0;
    else if (r_data_en)        // strobe
        eq_run <= 1'b1;        
    else if (eq_rd_addr == (num_of_filters - 1))
        eq_run <= 1'b0;
    else
        eq_run <= eq_run;
end

always @ (posedge clk) begin 
    eq_rd_addr_dly <= eq_rd_addr;
    if (!eq_run) 
        eq_rd_addr <= 0;
    else
        eq_rd_addr <= eq_rd_addr + 1;
end

always @ (posedge clk) begin
    eq_run_dly[0] <= eq_run;
    eq_run_dly[1] <= eq_run_dly[0];   
    eq_valid_stb <=  eq_run_dly[1] & !eq_run_dly[0];
end

/* Create mux for the number of filters for the Equalizer
    genvar i;
generate    
    for (i = 0; i < num_of_filters; i = i + 1) begin
         // Coefficient write mux
        always @ (posedge clk) begin    
            l_mult_in <= (eq_rd_addr == i) ?  audio_out_l[i] : 1'b0; 
        end        
    end     // for loop         
endgenerate
*/ 
    
// RAM holding the gains for each (16) eq element    
ram_2port_16x16 eq_gain_ram (
  .clk              (clk),                          // input wire clk
  .we               (eq_wr),                        // input wire we
  .a                (eq_wr_addr),                   // input wire [3 : 0] a
  .d                ({eq_gain_msb, eq_gain_lsb}),   // input wire [15 : 0] d
  .dpra             (eq_rd_addr),                   // input wire [3 : 0] dpra
  .dpo              (gain)                          // output wire [15 : 0] dpo
);

// defines the weight of each eq element (left chnl)       
mult_48x16 left_eq_mult (
  .CLK              (clk),                          // input wire CLK
  .SCLR             (r_data_en),                    // input wire SCLR
  .CE               (eq_run_dly[0]),                   // input wire CE
  .A                (audio_out_l[eq_rd_addr_dly]),  // input wire [47 : 0] A
  .B                (gain),                         // input wire [15 : 0] B
  .P                (l_mult_out)                    // output wire [63 : 0] P
);
 
// defines the weight of each eq element (right chnl)       
mult_48x16 right_eq_mult (
  .CLK              (clk),                          // input wire CLK
  .SCLR             (r_data_en),                    // input wire SCLR
  .CE               (eq_run_dly[0]),                   // input wire CE
  .A                (audio_out_r[eq_rd_addr_dly]),  // input wire [47 : 0] A
  .B                (gain),                         // input wire [15 : 0] B
  .P                (r_mult_out)                    // output wire [63 : 0] P
);

// adds all of the eq elements together (left)
eq_accum left_eq_accum (
  .CLK          (clk),              // input wire CLK
  .CE           (eq_run_dly[1]),    // input wire CE
  .SCLR         (r_data_en),        // input wire SCLR
  .BYPASS       (bypass),           // input wire BYPASS
  .B            (l_mult_out),       // input wire [63 : 0] B
  .Q            (l_accum_out)       // output wire [63 : 0] Q
);
 
// adds all of the eq elements together (right)
eq_accum right_eq_accum (
  .CLK          (clk),              // input wire CLK
  .CE           (eq_run_dly[1]),    // input wire CE
  .SCLR         (r_data_en),        // input wire SCLR
  .BYPASS       (bypass),           // input wire BYPASS
  .B            (r_mult_out),       // input wire [63 : 0] B
  .Q            (r_accum_out)       // output wire [63 : 0] Q
);

assign eq_test_d = gain;
assign eq_test_en = eq_run;
//assign eq_test_d1 = {2'b00, l_data_en, r_data_en, eq_wr_addr, eq_wr_rst, 2'b00, eq_rd_addr, eq_run};

endmodule
