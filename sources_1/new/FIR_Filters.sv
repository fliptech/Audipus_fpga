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
    parameter taps_per_filter = 4
)(
    input           clk,
    input           reset_n,
    input           audio_en,
    // coefficient signals   
    input           coef_addr_rst,
    input           coefficient_wr_en,
    input [5:0]     coef_select,        // selects which coefficient RAM to write and rd via test
    input [7:0]     coef_wr_lsb_data,   // must be written AFTER coef_wr_msb_data
    input [7:0]     coef_wr_msb_data,
    input [7:0]     coefs_per_tap_lsb,  // must be written AFTER coef_wr_msb_data
    input           coefs_per_tap_msb,  // from audio_control[6]
    output          wr_addr_zero,
    // input signals
    input           l_data_en,
    input           r_data_en,
    input [23:0]    l_data_in,
    input [23:0]    r_data_in,
    // output signals
    output          l_data_valid,
    output          r_data_valid,
    output [47:0]   l_data_out[taps_per_filter - 1 :0],
    output [47:0]   r_data_out[taps_per_filter - 1 :0],
    output [15:0]   test_data,
    output          fir_test_en
     
);

reg [8:0] buf_rd_addr, coef_rd_addr, buf_pntr;
reg fir_en, fir_valid_stb, data_en, data_armed;
reg [8:0] coef_wr_addr;

wire [23:0] l_buf_data_out, r_buf_data_out;

wire [15:0] coefficients[taps_per_filter - 1 : 0];
reg [taps_per_filter - 1 : 0]   coef_wr_en;

wire fir_data_valid;

assign l_data_valid = fir_data_valid;
assign r_data_valid = fir_data_valid;

wire [8:0] coefs_per_tap = {coefs_per_tap_msb, coefs_per_tap_lsb};  // 511 max
          
assign wr_addr_zero = (coef_wr_addr == 0);

// coefficient write address generator
//      auto increments coef_wr_addr after every write
always @ (posedge clk) begin 
    if (!reset_n || coef_addr_rst)
        coef_wr_addr <= 0;
    else if (coefficient_wr_en)
        coef_wr_addr <= coef_wr_addr + 1;
    else
        coef_wr_addr <= coef_wr_addr;        
end
            




// circular buffer control
always @ (posedge clk) begin
    if (!reset_n || !audio_en) begin
        buf_rd_addr <= taps_per_filter - 1;
        coef_rd_addr <= 0;
        buf_pntr <= taps_per_filter - 1;
    end
    else begin
//      if (coef_rd_addr == (taps_per_filter - 1)) begin
        if (data_en) begin            // if new audio sample (both left & right) strobe 
            coef_rd_addr <= 0;
            if (buf_pntr == 0)
                buf_pntr <= taps_per_filter - 1;
            else
                buf_pntr = buf_pntr - 1;    // for clkwise turn
            buf_rd_addr = buf_pntr;
        end
        else if (fir_en) begin          //  if fir processing enabled 1 clk after data_en           
            coef_rd_addr <= coef_rd_addr + 1;   // coef td addr
            buf_rd_addr <= buf_rd_addr + 1;         // circular buf rd addr
            buf_pntr <= buf_pntr;
        end
        else begin
            coef_rd_addr <= coef_rd_addr; 
            buf_rd_addr <= buf_rd_addr;
            buf_pntr <= buf_pntr;
        end
    end        
end

// data_en control
always @ (posedge clk) begin
    if (!reset_n || !audio_en) begin
        data_en <= 1'b0;
        data_armed <= 1'b0;
    end
    else begin    
        if (r_data_en && l_data_en) begin       // both simultaneously
            data_en <= 1'b1;
            data_armed <= 1'b0;
        end
        else if (r_data_en || l_data_en) begin
            if (!data_armed) begin               // arm on 1st enable (l or r)
                data_armed <= 1'b1;
                data_en <= 1'b0;
            end
            else begin                          // both l & r enabled (at slightly diffrerent times)
                data_armed <= 1'b0;
                data_en <= 1'b1;
            end
        end
        else begin
            data_armed <= data_armed;
            data_en <= 1'b0;
        end
    end                
end

// fir_en control
always @ (posedge clk) begin
    if (!reset_n || !audio_en) begin
        fir_en <= 1'b0;
        fir_valid_stb <= 1'b0;
    end
    else if (data_en)  begin          // strobe: if new audio sample (both left & right)
        fir_en <= 1'b1;
        fir_valid_stb <= 1'b0;
    end
    else if (coef_rd_addr == (coefs_per_tap - 1)) begin   // last filter tap processed
        fir_en <= 1'b0;
        fir_valid_stb <= 1'b1;
    end
    else begin
        fir_en <= fir_en;
        fir_valid_stb <= 1'b0;
    end
end

 
defparam fir_valid_delay.SIG_DLY = 4; // Delay of 4 clks

SignalPipeLineDelay fir_valid_delay (
    .clk        (clk),
    .signal_in  (fir_valid_stb),
    .signal_out (fir_data_valid)
);
        

// left 2-port ram        
circular_fir_buffer l_circular_buffer (
  .clk(clk),            // input wire clk
  .we(l_data_en),       // input wire we; wr to buf one clk before fir_en
  .a(buf_pntr),         // input wire [7 : 0] a (wr)
  .d(l_data_in),        // input wire [23 : 0] d
  .dpra(buf_rd_addr),   // input wire [7 : 0] dpra (rd)
  .dpo(l_buf_data_out)  // output wire [23 : 0] dpo
);

// right 2-port ram        
circular_fir_buffer r_circular_buffer (
  .clk(clk),            // input wire clk
  .we(r_data_en),       // input wire we; wr to buf one clk before fir_en
  .a(buf_pntr),         // input wire [7 : 0] a (wr) 
  .d(r_data_in),        // input wire [23 : 0] d
  .dpra(buf_rd_addr),   // input wire [7 : 0] dpra (rd)
  .dpo(r_buf_data_out)  // output wire [23 : 0] dpo
);



// Generate the number of filters for the Equalizer
genvar i;

generate
    for (i = 0; i < taps_per_filter; i = i + 1) 
    begin: fir_instantiate

  
 
        coef_ram FIR_coef_ram (
            .clk    (clk),                                      // input wire clk
            .we     (coef_wr_en[i]),                            // input wire we
            .a      (coef_wr_addr),                             // input wire [7 : 0] a
            .d      ({coef_wr_msb_data, coef_wr_lsb_data}),     // input wire [15 : 0] d
            .dpra   (coef_rd_addr),                           // input wire [8 : 0] dpra
            .dpo    (coefficients[i])                           // output wire [15 : 0] dpo
        );           
                
                    
        FIR_Tap fir_tap_l (
            .clk                (clk),              // input              
            .reset_n            (reset_n),          // input
            .audio_en           (audio_en),         // input
            .data_en            (fir_en),           // input
            .data_in            (l_buf_data_out),   // [23:0] input    
            .coefficients       (coefficients[i]),  // [15:0] input
            .data_out           (l_data_out[i])     // [47:0] output      
        );        
        
        FIR_Tap fir_tap_r (
            .clk                (clk),              // input              
            .reset_n            (reset_n),          // input
            .audio_en           (audio_en),         // input
            .data_en            (fir_en),           // input
            .data_in            (r_buf_data_out),   // [23:0] input    
            .coefficients       (coefficients[i]),  // [15:0] input
            .data_out           (r_data_out[i])     // [47:0] output      
        );        
        
    
        // Coefficient write mux
        always @ (posedge clk) begin    
            coef_wr_en[i] <= (coef_select == i) ?  coefficient_wr_en : 1'b0; 
        end
        
    end     // for loop 
         
endgenerate 

// Test modules

    assign test_data  =  coefficients[coef_select];
    assign fir_test_en = fir_en;
    

endmodule
