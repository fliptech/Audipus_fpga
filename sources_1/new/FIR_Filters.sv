`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/02/2021 12:51:46 PM
// Design Name: 
// Module Name: FIR_Filters
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


module FIR_Filters #(
    parameter num_of_filters = 4
)(
    input           clk,
    input           reset_n,
    input           audio_en,
    // coefficient signals   
    input           coef_rst,
    input           coefficient_wr_en,
    input [3:0]     coef_select,
    input [7:0]     coef_wr_lsb_data,
    input [7:0]     coef_wr_msb_data,
    input [7:0]     taps_per_filter,   
    output          wr_addr_zero,
    // i2s signals
    input [23:0]    l_pcm_chnl,
    input [23:0]    r_pcm_chnl,
    // audio out
    output [47:0]   l_audio_out[num_of_filters - 1 :0],
    output [47:0]   r_audio_out[num_of_filters - 1 :0]
     
);

reg [7:0] buf_rd_addr, buf_rd_counter, buf_pntr;
reg fir_en;
wire [23:0] l_buf_data_out, r_buf_data_out;

wire [15:0] coefficients[num_of_filters - 1 : 0];
reg [num_of_filters - 1 : 0]   coef_wr_en;

// Coefficient write mux


// circular buffer control
always @ (posedge clk) begin
    if (!reset_n || !audio_en) begin
        buf_rd_addr <= taps_per_filter - 1;
        buf_rd_counter <= 0;
        buf_pntr <= taps_per_filter - 1;
    end
    else begin
//      if (buf_rd_counter == (taps_per_filter - 1)) begin
        if (r_data_valid) begin         // if new audio sample
            buf_rd_counter <= 0;
            buf_pntr = buf_pntr - 1;    // for clkwise turn
            buf_rd_addr = buf_pntr;
        end
        else if (fir_en) begin            
            buf_rd_counter <= buf_rd_counter + 1; 
            buf_rd_addr <= buf_rd_addr + 1;
            buf_pntr <= buf_pntr;
        end
        else begin
            buf_rd_counter <= buf_rd_counter; 
            buf_rd_addr <= buf_rd_addr;
            buf_pntr <= buf_pntr;
        end
    end        
end


always @ (posedge clk) begin
    if (!reset_n || !audio_en)
        fir_en <= 1'b0;
    else if (r_data_valid)
        fir_en <= 1'b1;
    else if (buf_rd_counter == (taps_per_filter - 1))
        fir_en <= 1'b0; 
    else
        fir_en <= fir_en;
end        

// circular buffer control

// left         
circular_fir_buffer l_circular_buffer (
  .clk(clk),            // input wire clk
  .we(r_data_valid),    // input wire we >>> r is correct <<<; wr to buf one clk before fir_en
  .a(buf_pntr),         // input wire [7 : 0] a (wr)
  .d(l_pcm_chnl),       // input wire [23 : 0] d
  .dpra(buf_rd_addr),   // input wire [7 : 0] dpra (rd)
  .dpo(l_buf_data_out)  // output wire [23 : 0] dpo
);

// right        
circular_fir_buffer r_circular_buffer (
  .clk(clk),            // input wire clk
  .we(r_data_valid),    // input wire we; wr to buf one clk before fir_en
  .a(buf_pntr),         // input wire [7 : 0] a (wr) 
  .d(r_pcm_chnl),       // input wire [23 : 0] d
  .dpra(buf_rd_addr),   // input wire [7 : 0] dpra (rd)
  .dpo(r_buf_data_out)  // output wire [23 : 0] dpo
);

// Generate the number of filters for the Equalizer
genvar i;

generate
    for (i = 0; i < num_of_filters; i = i + 1) 
    begin: fir_instantiate

        FIR_coefficients fir_coef (
            .clk                (clk),              // input
            .reset_n            (reset_n),          // input
            .coef_rst           (coef_rst),         // input
            .wr_en              (coef_wr_en[i]),    // input
            .rd_en              (fir_en),           // input 
            .coef_wr_lsb_data   (coef_wr_lsb_data), // [7:0] input   
            .coef_wr_msb_data   (coef_wr_msb_data), // [7:0] input 
            .taps_per_filter    (taps_per_filter),  // [7:0] input
            .coef_rd_addr       (buf_rd_counter),   // [7:0] input
            .wr_addr_zero       (wr_addr_zero),     // output
            .coefficients       (coefficients[i])   // [15:0] output
        );    
        
        
            
        FIR_Tap fir_tap_l (
            .clk                (clk),              // input              
            .reset_n            (reset_n),          // input
            .audio_en           (audio_en),         // input
            .data_en            (fir_en),           // input
            .aud_data_in        (l_buf_data_out),   // [23:0] input    
            .coefficients       (coefficients[i]),  // [15:0] input
            .audio_data_out     (l_audio_out[i])    // [47:0] output      
        );        
        
        FIR_Tap fir_tap_r (
            .clk                (clk),              // input              
            .reset_n            (reset_n),          // input
            .audio_en           (audio_en),         // input
            .data_en            (fir_en),           // input
            .aud_data_in        (r_buf_data_out),   // [23:0] input    
            .coefficients       (coefficients[i]),  // [15:0] input
            .audio_data_out     (r_audio_out[i])    // [47:0] output      
        );        
        
    
        always @ (posedge clk) begin    
            coef_wr_en[i] <= (coef_select == i) ?  coefficient_wr_en : 1'b0; 
        end
        
    end     // for loop 
         
endgenerate 

endmodule
