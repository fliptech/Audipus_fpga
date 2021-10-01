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
 
    input [1:0]         data_out_select,
    input               l_pcm_valid,
    input               r_pcm_valid,
    input [23:0]        l_pcm_data,
    input [23:0]        r_pcm_data,
     
    output reg          l_frontEnd_valid,       // strobe
//    output reg          r_frontEnd_valid,       // strobe
    output reg          data_valid,             // strobe
    output reg [23:0]   l_frontEnd_data,
    output reg [23:0]   r_frontEnd_data,
    output reg [10:0]   smp_clken_count    
);

parameter SmpRate_192KHz = 11'hff;   //   256
parameter SmpRate_96KHz = 11'h1ff;   //   512
parameter SmpRate_48KHz = 11'h3ff;   //  1024
parameter SmpRate_44_1KHz = 11'h45a; //  1115 -> 0x458
parameter SmpRate_88_2KHz = 11'h22c; //   557

parameter numOfBits = 24;

assign bit_cnt_reg = numOfBits;

// samplePerCycle = sample_rate / tri_freq = 96000/1000 = 96


reg neg;
reg [23:0] triangle_count;
//reg [10:0] smp_clken_count;

reg          r_frontEnd_valid;

assign l_dout_valid = data_valid; 
assign r_dout_valid = data_valid; 

// create the test sample clk strobe datavalid
// divide mclk 49.152MHz by smp_rate_divide to create the SampleRate via clken
always @ (posedge clk) begin
    if (!run) begin
        data_valid <= 1'b0;
        smp_clken_count <= 0;
    end
    else if (smp_clken_count == SmpRate_44_1KHz) begin      // smp_rate_divide = mclk/sample_rate
        smp_clken_count <= 0;
        data_valid <= 1'b1;
    end
    else begin
        smp_clken_count <= smp_clken_count + 1;
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



// output data mux
always @ (posedge clk) begin
    if (!run) begin
        l_frontEnd_data <= 0;
        r_frontEnd_data <= 0;
        l_frontEnd_valid <= 0;
        r_frontEnd_valid <= 0;
     end
    else begin
        if (data_out_select == 0) begin
            l_frontEnd_valid <= l_pcm_valid;
            r_frontEnd_valid <= r_pcm_valid;
        end
        else begin
            l_frontEnd_valid <= data_valid;
            r_frontEnd_valid <= data_valid;
        end
//      SW command:     feTest
        if (data_valid) begin
            case (data_out_select)
                0: begin
                    l_frontEnd_data <= l_pcm_data;               
                    r_frontEnd_data <= r_pcm_data;
                end         
                1: begin    // positive dc value
                    l_frontEnd_data <= 24'h7fff00;
                    r_frontEnd_data <= 24'h7fff00;
                end
                2:  begin    // negative dc value
                    l_frontEnd_data <= 24'h8000ff;
                    r_frontEnd_data <= 24'h8000ff;
                end
                3:  begin
                    l_frontEnd_data <= triangle_count;
                    r_frontEnd_data <= triangle_count;
                end
            endcase
        end
        else begin
            l_frontEnd_data <= l_frontEnd_data;
            r_frontEnd_data <= r_frontEnd_data;
        end
    end
end


endmodule
