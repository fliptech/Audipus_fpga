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
    input               clk,
    input               reset_n,
    input               bclk,
    input               lrclk,
    input               i2s_data,
    output              dout_valid,       // strobe
    output reg [23:0]   l_pcm_data,
    output reg [23:0]   r_pcm_data,
    output reg [7:0]    bit_cnt_reg        // number of bits in a l or r sample
);

reg         bclk_en, l_dout_valid, r_dout_valid;
reg         lrclk_dly;
reg [2:0]   bclk_shift;
reg [23:0]  lr_shift_data, l_d_out, r_d_out;
reg [7:0]   i2s_bit_cnt, shift_bit_cnt;
reg [9:0]   sub_sample_counter;

assign dout_valid = r_dout_valid;

// positive edge bclk detect & enable
always @ (posedge clk) begin
    bclk_shift[0] <= bclk;
    bclk_shift[2:1] <= bclk_shift[1:0];
    if (bclk_shift == 3'b011) 
        bclk_en <= 1'b1;
    else
        bclk_en <= 1'b0;
end

// lrclk edge detect, bit count & valid generation
// load shifted data                
always @ (posedge clk) begin
    if(bclk_en) begin
        lrclk_dly <= lrclk;
 
        if (lrclk_dly != lrclk) begin
            i2s_bit_cnt <= 0;
            bit_cnt_reg <= i2s_bit_cnt;
            lr_shift_data <= 0;
            if (!lrclk) begin       // left chnl
                l_dout_valid <= 1'b1;
                l_d_out <= lr_shift_data;
             end
            else begin              // right chnl
                r_dout_valid <= 1'b1;
                r_d_out <= lr_shift_data;
            end
        end
        else begin
            i2s_bit_cnt <= i2s_bit_cnt + 1;            
            lr_shift_data[0] <= i2s_data;
            lr_shift_data[23:1] <= lr_shift_data[22:0];

            l_dout_valid <= 1'b0;
            r_dout_valid <= 1'b0;
            l_d_out <= l_d_out;
            r_d_out <= r_d_out;
        end
    end
    else begin
        i2s_bit_cnt <= i2s_bit_cnt;
        lr_shift_data <= lr_shift_data;
        l_dout_valid <= 1'b0;
        r_dout_valid <= 1'b0;
        l_d_out <= l_d_out;
        r_d_out <= r_d_out;
    end
end        

            
// bypass utill tested
// BARREL SHIFTER <<< check this

always @ (posedge clk) begin
    if (dout_valid) begin
        shift_bit_cnt <= bit_cnt_reg;
        l_pcm_data <= l_d_out;
        r_pcm_data <= r_d_out;
    end
    else if (shift_bit_cnt < 24) begin
        shift_bit_cnt <= shift_bit_cnt + 1;
        l_pcm_data[0] <= 1'b0;
        l_pcm_data[23:1] <= l_pcm_data[22:0];
        r_pcm_data[0] <= 1'b0;
        r_pcm_data[23:1] <= r_pcm_data[22:0];
    end        
    else begin
        shift_bit_cnt <= bit_cnt_reg;
        l_pcm_data <= l_pcm_data;
        r_pcm_data <= r_pcm_data;
    end   
end

endmodule
