`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/12/2021 12:08:30 PM
// Design Name: 
// Module Name: FrontEndTest
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


module FrontEndTest(
    input               clk,
    input               run,
//    input [7:0]         smp_rate_divide_lsb,    // sets the sample rate of the test triangle waveform
//    input [7:0]         smp_rate_divide_msb,
    input [7:0]         triangle_incrmnt,       // msb only, lsb set to 0s, sets the slope of the triangle based on num_of_bits and smp_rate
 // triangle_incrmnt = 2^numOfBits / samplePerCycle = 2^24 / 96 = 16,777,216 / 96 = 174762 = 0x2aaaa
     
    output reg          sin_clken, 
    output              l_dout_valid,       // strobe
    output              r_dout_valid,       // strobe
    output [23:0]       l_pcm_data,
    output [23:0]       r_pcm_data
);

parameter SmpRate_192KHz = 6'hff;   //   256
parameter SmpRate_96KHz = 6'h1ff;   //   512
parameter SmpRate_48KHz = 6'h3ff;   //  1024
parameter SmpRate_44_1KHz = 6'h45a; //  1115 -> 0x458
parameter SmpRate_88_2KHz = 6'h22c; //   557

parameter numOfBits = 24;

assign bit_cnt_reg = numOfBits;

// samplePerCycle = sample_rate / tri_freq = 96000/1000 = 96


reg neg, data_valid;
reg [23:0] triangle_count;
reg [5:0] sample_count;
reg [2:0] sin_clken_count;

assign l_pcm_data = triangle_count;
assign r_pcm_data = triangle_count;

//wire [15:0] smp_rate_divide = {smp_rate_divide_msb, smp_rate_divide_lsb};  // = mclk/sample_rate
wire [15:0] smp_rate_divide = SmpRate_44_1KHz;  // = mclk/sample_rate


assign l_dout_valid = data_valid; 
assign r_dout_valid = data_valid; 

// create the test sample clk strobe datavalid
// divide mclk 49.152MHz by smp_rate_divide to create the SampleRate via clken
always @ (posedge clk) begin
    if (!run) begin
        data_valid <= 1'b0;
        sin_clken_count <= 0;
    end
    else if (sin_clken_count == smp_rate_divide) begin      // smp_rate_divide = mclk/sample_rate
        sin_clken_count <= 0;
        data_valid <= 1'b1;
    end
    else begin
        sin_clken_count <= sin_clken_count + 1;
        data_valid <= 1'b0;
    end
end



// triangle wave test
always @ (posedge clk) begin
    if (!run) begin
        triangle_count <= 0;
//        neg <= 1'b0;
     end
    else begin
        if (data_valid) begin
            if (!neg) begin
                if ((triangle_count + triangle_incrmnt) < 24'h7ffffe) begin     // keep positive number, msb=0 (for now)
                    triangle_count <= triangle_count + triangle_incrmnt;
                    neg <= neg;
                end
                else begin
                    triangle_count <= triangle_count - triangle_incrmnt;
                    neg <= 1'b1;
                end
            end
            else begin
                if ((triangle_count - triangle_incrmnt) > triangle_incrmnt) begin   // keep positive number, msb=0 (for now)
                    triangle_count <= triangle_count - triangle_incrmnt;
                    neg <= neg;
                end
                else begin
                    triangle_count <= triangle_count + triangle_incrmnt;
                    neg <= 1'b0;
                end
            end
        end
        else begin
            triangle_count <= triangle_count;
            neg <= neg;
        end
    end
end



endmodule
