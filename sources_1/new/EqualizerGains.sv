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
//    input eq_wr_rst,
    input [num_of_filters-1:0] eq_wr_sel,    
    input [7:0] eq_gain_lsb,
    input [7:0] eq_gain_msb,
    input [1:0] test_sel,
//    output wr_addr_zero,
    // pipe input
    input l_data_en,        // expecting a strobe
    input r_data_en,        // expecting a strobe
    input [47:0] l_data_in[num_of_filters-1:0],
    input [47:0] r_data_in[num_of_filters-1:0],
    // pipe output
    output l_data_valid,
    output r_data_valid,
    output [23:0] l_data_out,
    output [23:0] r_data_out,
    output [15:0] eq_test_d,
    output eq_test_en
    
);

reg eq_run, eq_wr_dly, eq_valid_stb;
reg [3:0] eq_rd_addr, eq_rd_addr_dly1;
reg [2:0] eq_run_dly;

wire [63:0] l_mult_out, r_mult_out, l_accum_out, r_accum_out;
wire [15:0] gain;
wire clken = 1'b1;

assign l_data_valid = eq_valid_stb;
assign r_data_valid = eq_valid_stb;

// truncation
assign l_data_out = l_accum_out[63:40];
//assign r_data_out = r_accum_out[63:40];

assign r_data_out =         (test_sel == 0) ? {8'h00, r_accum_out[15:0]} :
                            (test_sel == 1) ? {8'h00, r_accum_out[31:16]} :
                            (test_sel == 2) ? {8'h00, r_accum_out[47:32]} :
                            (test_sel == 3) ? {8'h00, r_accum_out[63:48]} :
                            0;
                            
                            
//assign wr_addr_zero = (eq_wr_addr == 0);



//wire [3:0] eq_rd_addr = bypass ? eq_rd_sel : eq_rd_count;
//wire [3:0] eq_rd_addr = eq_rd_count;

/* coefficient write address generator
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
*/            

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

always @ (posedge clk) begin            // <<<<< check this
    eq_rd_addr_dly1 <= eq_rd_addr;
    if (!eq_run) 
        eq_rd_addr <= 0;
    else
        eq_rd_addr <= eq_rd_addr + 1;
end

always @ (posedge clk) begin
    eq_run_dly[0] <= eq_run;
    eq_run_dly[2:1] <= eq_run_dly[1:0];   
    eq_valid_stb <=  eq_run_dly[2] & !eq_run_dly[1];
end

// RAM holding the gains for each (16) eq element... pipeline stage = 1   
ram_2port_16x16 eq_gain_ram (
  .clk              (clk),                          // input wire clk
  .we               (eq_wr),                        // input wire we
  .a                (eq_wr_sel),                    // input wire [3 : 0] a
  .d                ({eq_gain_msb, eq_gain_lsb}),   // input wire [15 : 0] d
  .dpra             (eq_rd_addr),                   // input wire [3 : 0] dpra
  .qdpo             (gain)                          // output wire [15 : 0] dpo
);

// defines the weight of each eq element (left chnl)... pipeline stage = 1         
mult_48x16 left_eq_mult (
  .CLK              (clk),                          // input wire CLK
  .SCLR             (eq_valid_stb),                 // input wire SCLR
  .CE               (eq_run_dly[0]),                // input wire CE
  .A                (l_data_in[eq_rd_addr_dly1]),    // input wire [47 : 0] A
  .B                (gain),                         // input wire [15 : 0] B
  .P                (l_mult_out)                    // output wire [63 : 0] P
);
 
// defines the weight of each eq element (right chnl)... pipeline stage = 1         
mult_48x16 right_eq_mult (
  .CLK              (clk),                          // input wire CLK
  .SCLR             (eq_valid_stb),                 // input wire SCLR
  .CE               (eq_run_dly[0]),                // input wire CE
  .A                (r_data_in[eq_rd_addr_dly1]),    // input wire [47 : 0] A  <<<<<<
  .B                (gain),                         // input wire [15 : 0] B
  .P                (r_mult_out)                    // output wire [63 : 0] P
);

// adds all of the eq elements together (left)
eq_accum left_eq_accum (
  .CLK          (clk),              // input wire CLK
  .CE           (eq_run_dly[1]),    // input wire CE
  .SCLR         (eq_valid_stb),     // input wire SCLR
  .B            (l_mult_out),       // input wire [63 : 0] B
  .Q            (l_accum_out)       // output wire [63 : 0] Q
);
 
// adds all of the eq elements together (right)... pipeline stage = 1  
eq_accum right_eq_accum (
  .CLK          (clk),              // input wire CLK
  .CE           (eq_run_dly[1]),    // input wire CE
  .SCLR         (eq_valid_stb),     // input wire SCLR
  .B            (r_mult_out),       // input wire [63 : 0] B
  .Q            (r_accum_out)       // output wire [63 : 0] Q
);

//assign eq_test_d = {r_data_in[eq_rd_addr_dly][11:0], gain[7:5], eq_run};
assign eq_test_en = eq_run;
assign eq_test_d = {r_mult_out[7:0], gain[3:0], eq_rd_addr[1:0], eq_valid_stb, eq_run};
/*
assign eq_test_d =      (test_sel == 0) ? {r_data_in[eq_rd_addr_dly][11:0], gain[7:5], eq_run} :
                        (test_sel == 1) ? {r_data_in[eq_rd_addr_dly][11:0], eq_rd_addr[1:0], eq_run_dly[0], eq_run} :
                        (test_sel == 2) ? {r_mult_out[11:0], eq_rd_addr[1:0], eq_run_dly[0], eq_run} :
                        (test_sel == 3) ? {r_mult_out[23:12], eq_rd_addr[1:0], eq_run_dly[0], eq_run} :
                        0;
*/


endmodule
