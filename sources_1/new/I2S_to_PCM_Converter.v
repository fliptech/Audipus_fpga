`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/11/2020 03:53:06 PM
// Design Name: 
// Module Name: I2S_to_PWM_Converter
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


module I2S_to_PCM_Converter # (
    parameter num_of_sample_bits = 24
) (
    input clk,
    input reset_n,
    input sclk,
    input bclk,
    input lrclk,
    input s_data,
    output l_data_stb,
    output r_data_stb,
    output reg [23:0] l_data,
    output reg [23:0] r_data
);

reg         bclk_en, l_data_en, r_data_en;
reg         lrclk_dly;
reg [2:0]   bclk_shift;
reg [23:0]  lr_shift_data;
reg [31:0]  lr_cnt;

assign l_data_stb = l_data_en & bclk_en;
assign r_data_stb = r_data_en & bclk_en;

// positive edge bclk detect & enable
always @ (posedge clk) begin
    bclk_shift[0] <= bclk;
    bclk_shift[2:1] <= bclk_shift[1:0];
    if (bclk_shift == 3'b001) 
        bclk_en <= 1'b1;
    else
        bclk_en <= 1'b0;
end

// lrclk edge detect & data load & valid generation
always @ (posedge clk) begin
    if(bclk_en) begin
        lrclk_dly <= lrclk;
        if (lrclk_dly != lrclk) begin
            lr_cnt <= 0;
            if (!lrclk) begin
                 l_data_en <= 1'b1;
            end
            else begin
                r_data_en <= 1'b1;
            end
        end
        else begin
            lr_cnt <= lr_cnt + 1;
            l_data_en <= 1'b0;
            r_data_en <= 1'b0;
        end
                
        if (lr_cnt == (num_of_sample_bits - 1))
            if (!lrclk) begin
                l_data <= lr_shift_data;
            end
            else begin
                r_data <= lr_shift_data;
            end
        else begin
            l_data <= l_data;
            r_data <= r_data;
        end
    end
    else begin
        l_data <= l_data;
        r_data <= r_data;
        l_data_en <= l_data_en;
        r_data_en <= r_data_en;
    end
end

    

        
            

always @ (posedge clk) begin
    if(bclk_en) begin
            lr_shift_data[0] <= s_data;
            lr_shift_data[23:1] <= lr_shift_data[22:0];
    end
    else begin
        lr_shift_data <= lr_shift_data;
    end
end

endmodule
