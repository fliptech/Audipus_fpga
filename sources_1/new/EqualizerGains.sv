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
//    input scaler_output_sel,
    input [num_of_filters-1:0] eq_wr_sel,    
    input [7:0] eq_gain_lsb,
    input [7:0] eq_gain_msb,
    input [3:0] eq_shift,
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
    output reg [23:0] l_data_out,
    output reg [23:0] r_data_out,
    output [15:0] eq_test_d,
    output eq_test_en
    
);

parameter scale_value = 6716;

reg eq_run, eq_wr_dly, eq_valid_stb, scaler_mult_ce;
reg [3:0] eq_rd_addr, eq_rd_addr_dly1;
reg [2:0] eq_run_dly;

wire [63:0] l_mult_out, r_mult_out, l_accum_out, r_accum_out;
//reg [63:0]  l_shifted_accum_out, r_shifted_accum_out;
reg [63:0]  scaler_mult_in;
wire [15:0] gain;
wire clken = 1'b1;

reg [3:0]   shift_cnt;
reg         hold, data_valid;

assign l_data_valid = data_valid;
assign r_data_valid = data_valid;

// truncation
// assign l_data_out =     l_shifted_accum_out[63:40];
// assign r_data_out =     r_shifted_accum_out[63:40];


/*
assign r_data_out =         (test_sel == 0) ? {8'h00, r_accum_out[15:0]} :
                            (test_sel == 1) ? {8'h00, r_accum_out[31:16]} :
                            (test_sel == 2) ? {8'h00, r_accum_out[47:32]} :
                            (test_sel == 3) ? {8'h00, r_accum_out[63:48]} :
                            0;
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



/* Output Bit Shifter
always @ (posedge clk) begin
    if (eq_valid_stb) begin
        hold <= 1'b0;
        shift_cnt <= eq_shift;      // load count
        l_data_valid <= 1'b0;
        r_data_valid <= 1'b0;
        l_shifted_accum_out <= l_accum_out;
        r_shifted_accum_out <= r_accum_out;
    end
    else if (shift_cnt == 0) begin
        if (!hold) begin
            hold <= 1'b1;
            l_data_valid <= 1'b1;
            r_data_valid <= 1'b1;
        end
        else begin
            hold <= hold;
            l_data_valid <= 1'b0;
            r_data_valid <= 1'b0;
        end
        shift_cnt <= 0;
        l_shifted_accum_out <= l_shifted_accum_out;
        r_shifted_accum_out <= r_shifted_accum_out;
    end
    else begin
        hold <= hold;
        l_data_valid = 1'b0;
        r_data_valid = 1'b0;
        shift_cnt <= shift_cnt - 1;
        l_shifted_accum_out[0] <= 1'b0;
        r_shifted_accum_out[0] <= 1'b0;
        l_shifted_accum_out[63:1] <= l_shifted_accum_out[62:0];
        r_shifted_accum_out[63:1] <= r_shifted_accum_out[62:0];
    end
end
*/

// Output Scaler        
// scaler state machine
enum reg[3:0] {IDLE, LEFT, RIGHT, LEFT_STB, LEFT_EN, RIGHT_STB, RIGHT_EN, D_VALID} eq_scaler_state;

always @ (posedge clk) begin
    if (reset_n == 1'b0) eq_scaler_state <= IDLE;
    case (eq_scaler_state) 
        IDLE: begin
            data_valid <= 1'b0;
            scaler_mult_ce <= 1'b0;
            scaler_mult_in <= scaler_mult_in;
            l_data_out <= l_data_out;
            r_data_out <= r_data_out;
            if (eq_valid_stb)          // start another cycle
               eq_scaler_state <= LEFT;
            else          
               eq_scaler_state <= IDLE;
        end           
        LEFT: begin
            data_valid <= 1'b0;
            scaler_mult_ce <= 1'b1;
            scaler_mult_in <= l_accum_out;
            l_data_out <= l_data_out;
            r_data_out <= r_data_out;
            eq_scaler_state <= LEFT_STB;
        end
        LEFT_STB: begin
            data_valid <= 1'b0;
            scaler_mult_ce <= 1'b0;
            scaler_mult_in <= l_accum_out;
            l_data_out <= l_data_out;
            r_data_out <= r_data_out;
            eq_scaler_state <= LEFT_EN; 
        end        
        LEFT_EN: begin
            data_valid <= 1'b0;
            scaler_mult_ce <= 1'b0;
            scaler_mult_in <= r_accum_out;
            l_data_out <= l_data_out;
            r_data_out <= r_data_out;
            eq_scaler_state <= RIGHT; 
        end        
        RIGHT: begin
            data_valid <= 1'b0;
            scaler_mult_ce <= 1'b1;
            scaler_mult_in <= r_accum_out;
            l_data_out <= scaler_data_out;            
            r_data_out <= r_data_out;
            eq_scaler_state <= RIGHT_STB;
        end
        RIGHT_STB: begin
            data_valid <= 1'b0;
            scaler_mult_ce <= 1'b0;
            scaler_mult_in <= scaler_mult_in;
            l_data_out <= l_data_out;
            r_data_out <= r_data_out;
            eq_scaler_state <= RIGHT_EN;             
        end        
        RIGHT_EN: begin
            data_valid = 1'b1;
            scaler_mult_ce <= 1'b0;
            scaler_mult_in <= scaler_mult_in;
            l_data_out <= l_data_out;
            r_data_out <= r_data_out;            
            eq_scaler_state <= D_VALID; 
        end        
        D_VALID: begin
            data_valid = 1'b1;
            scaler_mult_ce <= 1'b0;
            scaler_mult_in <= scaler_mult_in;
            l_data_out <= l_data_out;
            r_data_out <= scaler_data_out;            
            eq_scaler_state <= IDLE; 
        end        
    endcase
end 

// eq scaler multiplier        
eq_output_scaler eq_scaler (
    .CLK            (clk),              // input wire CLK
    .CE             (scaler_mult_ce),   // input wire CE
    .SCLR           (~reset_n),         // input wire SCLR
    .A              (scale_value),      // input wire [12 : 0] A
    .B              (scaler_mult_in),   // input wire [63 : 0] B
    .P              (scaler_data_out)        // output wire [23 : 0] P
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
