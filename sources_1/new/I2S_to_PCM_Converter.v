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
    parameter MAX_NUM_OF_INPUT_BITS = 32,
    parameter MAX_NUM_OF_OUTPUT_BITS = 24
) (
    input               clk,
    input               reset_n,
    input               bclk,
    input               lrclk,
    input               i2s_data,
    output              dout_valid,       // strobe
    output [23:0]       l_pcm_data,
    output [23:0]       r_pcm_data,
//    output reg [23:0]   l_pcm_data,
//    output reg [23:0]   r_pcm_data,
    output reg [7:0]    bit_cnt_reg        // number of bits in a l or r sample
);

reg         bclk_en, l_dout_valid, r_dout_valid;
reg         lrclk_dly;
reg [2:0]   bclk_shift;
reg [7:0]   i2s_bit_cnt, shift_bit_cnt;
reg [9:0]   sub_sample_counter;
reg [MAX_NUM_OF_INPUT_BITS-1:0]  lr_shift_data, l_d_out, r_d_out, l_scaled_d, r_scaled_d;

assign dout_valid = r_dout_valid & bclk_en;   // only right (or only left) data_valid is necessary

// positive edge bclk detect & enable
always @ (posedge clk) begin
    bclk_shift[0] <= bclk;
    bclk_shift[2:1] <= bclk_shift[1:0];
    if (bclk_shift == 3'b011) 
        bclk_en <= 1'b1;
    else
        bclk_en <= 1'b0;
end

// lrclk edge detect strobe, bit count & valid generation
// load shifted data                
always @ (posedge clk) begin
    if(bclk_en) begin
        lrclk_dly <= lrclk;
 
        if (lrclk_dly != lrclk) begin
            if (!lrclk) begin       // left chnl
                l_dout_valid <= 1'b1;
             end
            else begin              // right chnl
                r_dout_valid <= 1'b1;
            end
        end
        else begin
            l_dout_valid <= 1'b0;
            r_dout_valid <= 1'b0;
        end
    end
    else begin
        l_dout_valid <= l_dout_valid;
        r_dout_valid <= r_dout_valid;
    end
end        

// Shift In I2S data
always @ (posedge clk) begin
    if(bclk_en) begin
        if (l_dout_valid || r_dout_valid) begin // l,r valid strobe
            bit_cnt_reg <= i2s_bit_cnt;
            i2s_bit_cnt <= 0;
            lr_shift_data[0] <= i2s_data;
            lr_shift_data[MAX_NUM_OF_INPUT_BITS-1:1] <= 0;
            if (!lrclk) begin       // left chnl
                l_d_out <= lr_shift_data;
            end
            else begin              // right chnl
                r_d_out <= lr_shift_data;
            end
        end
        else begin
            i2s_bit_cnt <= i2s_bit_cnt + 1;
            lr_shift_data[0] <= i2s_data;
            lr_shift_data[MAX_NUM_OF_INPUT_BITS-1:1] <= lr_shift_data[MAX_NUM_OF_INPUT_BITS-2:0];
            l_d_out <= l_d_out;
            r_d_out <= r_d_out;
        end
    end
    else begin
        i2s_bit_cnt <= i2s_bit_cnt;
        lr_shift_data <= lr_shift_data;
        l_d_out <= l_d_out;
        r_d_out <= r_d_out;
    end        
end
    

/* bypass utill tested
assign  l_pcm_data =  (test_sel == 3) ? l_scaled_d : l_d_out;
assign  r_pcm_data =  (test_sel == 3) ? r_scaled_d : r_d_out;
*/

assign  l_pcm_data =  l_scaled_d[MAX_NUM_OF_INPUT_BITS-1:MAX_NUM_OF_INPUT_BITS-MAX_NUM_OF_OUTPUT_BITS];
assign  r_pcm_data =  r_scaled_d[MAX_NUM_OF_INPUT_BITS-1:MAX_NUM_OF_INPUT_BITS-MAX_NUM_OF_OUTPUT_BITS];
        
// BARREL SHIFTER <<< check this

integer state;

always @ (posedge clk) begin
    case (state)
    0: begin
        if (bclk_en && (l_dout_valid || r_dout_valid)) begin
            shift_bit_cnt <= bit_cnt_reg;
            l_scaled_d <= l_d_out;
            r_scaled_d <= r_d_out;
            state = 1;
        end
        else begin
            l_scaled_d <= l_scaled_d;
            r_scaled_d <= r_scaled_d;
            state = 0;
        end
    end
    1: begin     
//        if (test_sel == 3) begin
            if (shift_bit_cnt < (MAX_NUM_OF_INPUT_BITS - 1)) begin
                shift_bit_cnt <= shift_bit_cnt + 1;
                l_scaled_d[0] <= 1'b0;
                l_scaled_d[MAX_NUM_OF_INPUT_BITS-1:1] <= l_scaled_d[MAX_NUM_OF_INPUT_BITS-2:0];
                r_scaled_d[0] <= 1'b0;
                r_scaled_d[MAX_NUM_OF_INPUT_BITS-1:1] <= r_scaled_d[MAX_NUM_OF_INPUT_BITS-2:0];
                state = 1;
            end        
            else begin
                shift_bit_cnt <= bit_cnt_reg;
                l_scaled_d <= l_scaled_d;
                r_scaled_d <= r_scaled_d;
                state = 0;
            end   
//        end
//        else begin
//           shift_bit_cnt <= bit_cnt_reg;
//            l_scaled_d <= l_scaled_d;
//            r_scaled_d <= r_scaled_d;
//            state = 0;
    end
    endcase
end

endmodule
