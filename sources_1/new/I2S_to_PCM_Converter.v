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
    output reg          l_dout_valid,       // strobe
    output reg          r_dout_valid,       // strobe
    output reg [23:0]   l_pcm_data,
    output reg [23:0]   r_pcm_data,
    output reg [7:0]    bit_cnt_reg,        // number of bits in a l or r sample
    output reg [9:0]    sub_sample_cnt      // number of mclks between 2 samples
);

reg         bclk_en;
reg         lrclk_dly;
reg [2:0]   bclk_shift;
reg [23:0]  lr_shift_data;
reg [7:0]   i2s_bit_cnt;
reg [9:0]   sub_sample_counter;


// positive edge bclk detect & enable
always @ (posedge clk) begin
    bclk_shift[0] <= bclk;
    bclk_shift[2:1] <= bclk_shift[1:0];
    if (bclk_shift == 3'b001) 
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
            if (!lrclk) begin       // left chnl
                l_dout_valid <= 1'b1;
                l_pcm_data <= lr_shift_data;
             end
            else begin              // right chnl
                r_dout_valid <= 1'b1;
                r_pcm_data <= lr_shift_data;
            end
        end
        else begin
            i2s_bit_cnt <= i2s_bit_cnt + 1;
            l_dout_valid <= 1'b0;
            r_dout_valid <= 1'b0;
            l_pcm_data <= l_pcm_data;
            r_pcm_data <= r_pcm_data;
        end
    end
    else begin
        i2s_bit_cnt <= i2s_bit_cnt;
        l_dout_valid <= 1'b0;
        r_dout_valid <= 1'b0;
        l_pcm_data <= l_pcm_data;
        r_pcm_data <= r_pcm_data;
    end
end        

            
// i2s data shift in register
always @ (posedge clk) begin
    if(bclk_en) begin
        lr_shift_data[0] <= i2s_data;
        lr_shift_data[23:1] <= lr_shift_data[22:0];
    end
    else begin
        lr_shift_data <= lr_shift_data;
    end
end

// sub sample counter
always @ (posedge clk) begin
    if(bclk_en && !lrclk_dly && lrclk) begin    // start/end of a sample
        sub_sample_counter <= 0;
        sub_sample_cnt <= sub_sample_counter;
    end
    else begin
        sub_sample_counter <= sub_sample_counter + 1;        
        sub_sample_cnt <= sub_sample_cnt;
    end
end

/* load shifted data                
always @ (posedge clk) begin
    if(bclk_en) begin
        if (i2s_bit_cnt == (num_of_sample_bits - 1))
            if (!lrclk) begin
                l_pcm_data <= lr_shift_data;
            end
            else begin
                r_pcm_data <= lr_shift_data;
            end
        else begin
            l_pcm_data <= l_pcm_data;
            r_pcm_data <= r_pcm_data;
        end
    end
    else begin
        l_pcm_data <= l_pcm_data;
        r_pcm_data <= r_pcm_data;
    end
end
*/
    


endmodule
