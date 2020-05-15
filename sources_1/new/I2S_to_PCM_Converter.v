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


module I2S_to_PCM_Converter(
    input clk,
    input reset_n,
    input sclk,
    input bclk,
    input lrclk,
    input s_data,
    output reg l_data_en,
    output reg r_data_en,
    output reg [23:0] l_data,
    output reg [23:0] r_data
);

reg         bclk_en;
reg [2:0]   bclk_shift, lrclk_shift;

// positive edge bclk detect & enable
always @ (posedge clk) begin
    bclk_shift[0] <= bclk;
    bclk_shift[2:1] <= bclk_shift[1:0];
    if (bclk_shift == 3'b001) 
        bclk_en <= 1'b1;
    else
        bclk_en <= 1'b0;
end

// lrclk edge detect & data valid generation
always @ (posedge clk) begin
    if(bclk_en) begin
        lrclk_shift[0] <= lrclk;
        lrclk_shift[2:1] <= lrclk_shift[1:0];
        if (lrclk_shift == 3'b001) 
            l_data_en <= 1'b1;
        else if (lrclk_shift == 3'b110) 
            r_data_en <= 1'b1;
        else begin
            l_data_en <= 1'b0;
            r_data_en <= 1'b0;
        end
    end
    else begin
        l_data_en <= l_data_en;
        r_data_en <= r_data_en;     
    end
end


always @ (posedge clk) begin
    if(bclk_en) begin
        if (lrclk) begin
            l_data[0] <= s_data;
            l_data[23:1] <= l_data[22:0];
        end
        else begin
            r_data[0] <= s_data;
            r_data[23:1] <= r_data[22:0];
        end
    end
    else begin
        l_data <= l_data;
        r_data <= r_data;
    end
end

endmodule
