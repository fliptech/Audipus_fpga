`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/14/2020 10:12:38 AM
// Design Name: 
// Module Name: PWM_to_I2S_Converter
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


module PCM_to_I2S_Converter(
    input clk,
    input reset_n,
    input  l_data_valid,
    input  r_data_valid,
    input  [23:0] l_data,
    input  [23:0] r_data,
    output reg l_data_en,
    output reg r_data_en,
    output sclk,
    output reg bclk,
    output reg lrclk,       
    output reg s_data
);

reg         bclk_en, l_shift_en, r_shift_en;
reg [2:0]   bclk_shift, lrclk_shift;
reg [23:0]  l_data_reg, r_data_reg;
reg [15:0]  i2s_seq_cnt;
reg [15:0]  lr_cnt;

// timing signals @ sample freq = 96KHz
always @ (posedge clk) begin    // clk freq = 49.152MHz
    if (reset_n) begin
        i2s_seq_cnt <= 0;    
        bclk <= 1'b0;
    end
    else begin
        i2s_seq_cnt <= i2s_seq_cnt + 1;
        
        case (i2s_seq_cnt)
 //         0 :    bclk <= 1'b0;
            7  : bclk <= 1'b1;
            15  : begin
                bclk <= 1'b0;
                bclk_en <= 1'b1;
            end
            2999 :  begin
                i2s_seq_cnt <= 0;
                bclk <= 1'b0;
            end
        endcase               
    end
end

always @ (posedge clk) begin    // clk freq = 49.152MHz
    if (reset_n) begin
        lr_cnt <= 0;    
        bclk <= 1'b0;
    end
    else if (bclk_en) begin         // 1 bclk = 10 clk 
        lr_cnt <= lr_cnt + 1;
               
        case (lr_cnt)
            15  : begin
                l_data_en <= 1'b1;
                lrclk <= 1'b1;
            end
            31  : begin
                lrclk <= 1'b0;
                r_data_en <= 1'b1;
                lr_cnt = 0;
            end
            default: begin
                l_data_en <= 1'b0;
                r_data_en <= 1'b0;
                lrclk <= lrclk;
            end
        endcase
    end
    else begin
        lr_cnt <= lr_cnt;
        lrclk <= lrclk;
    end
end
                
        

always @ (posedge clk) begin
    if (bclk_en) begin
        if (l_data_en)
            l_data_reg <= l_data;
        else if (r_data_en)
            r_data_reg <= r_data;
        else if (!lrclk) begin
            s_data <= l_data_reg[0];
            l_data_reg[23] <= 1'b0;
            l_data_reg[22:0] <= l_data_reg[23:1];
        end
        else if (lrclk) begin
            s_data <= r_data_reg[0];
            r_data_reg[23] <= 1'b0;
            r_data_reg[22:0] <= r_data_reg[23:1];
        end
    else begin
        s_data <= s_data;
        l_data_reg <= l_data_reg;            
        r_data_reg <= r_data_reg;
    end
    end
        
end


endmodule
