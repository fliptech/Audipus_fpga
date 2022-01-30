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
    input [7:0]         triangle_inc_reg,       // msb only, lsb set to 0s, sets the slope of the triangle based on num_of_bits and smp_rate
  // triangle_incrmnt = 2^numOfBits / samplePerCycle = 2^24 / 96 = 16,777,216 / 96 = 174762 = 0x2aaaa
 
    input [3:0]         data_out_select,
    input               pcm_valid,
    input [23:0]        l_pcm_data,
    input [23:0]        r_pcm_data,
    input [7:0]         coefs_per_tap_lsb,    // [7:0] input, cpu reg
    input               coefs_per_tap_msb,    // input taken from audio_control[6]
     
    output              frontEnd_valid,       // strobe
    output [23:0]       l_frontEnd_data,
    output [23:0]       r_frontEnd_data
);

parameter SmpRate_192KHz = 11'hff;   //   256
parameter SmpRate_96KHz = 11'h1ff;   //   512
parameter SmpRate_48KHz = 11'h3ff;   //  1024
parameter SmpRate_44_1KHz = 11'h45a; //  1115 -> 0x45a
parameter SmpRate_88_2KHz = 11'h22c; //   557

parameter numOfBits = 24;

assign bit_cnt_reg = numOfBits;

// samplePerCycle = sample_rate / tri_freq = 96000/1000 = 96


reg neg, data_valid, data_valid_out;
reg [23:0] frontEnd_data, triangle_count;
reg [10:0] smp_clken_count;
reg [8:0]  impulse_count;

wire [23:0]  triangle_incrmnt = {3'h0, triangle_inc_reg, 13'h0000};

// PCM ByPass
assign frontEnd_valid = (data_out_select == 0) ? pcm_valid : data_valid_out; 

assign l_frontEnd_data = (data_out_select == 0) ? l_pcm_data : frontEnd_data;
assign r_frontEnd_data = (data_out_select == 0) ? r_pcm_data : frontEnd_data;
//  *********************** 


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

// impulse count generation
always @ (posedge clk) begin
    if (!run && (data_out_select != 4)) begin
        impulse_count <= 0;
//        neg <= 1'b0;
     end
    else begin
        if (data_valid) begin
            if (impulse_count == ({coefs_per_tap_lsb, coefs_per_tap_lsb} + 4))
                impulse_count <= 0;
            else 
                impulse_count <= impulse_count + 1;
        end 
        else begin
            impulse_count <= impulse_count;
        end
    end
end
           


// output data mux
always @ (posedge clk) begin
    if (!run) begin
        frontEnd_data <= 0;
        data_valid_out <= 0;
     end
    else begin
        data_valid_out <= data_valid;        // 1 clk delay
//      SW command:     feTest
        if (data_valid) begin
            case (data_out_select)
                1: begin    // positive dc value
                    frontEnd_data <= 24'h7fff00;
                end
                2:  begin    // negative dc value
                    frontEnd_data <= 24'h8000ff;
                end
                3:  begin
                    frontEnd_data <= triangle_count;
/*                    
                    l_frontEnd_data[23] <= !triangle_count[23];     // define sign bit
                    l_frontEnd_data[22:0] <= triangle_count[22:0];
                    r_frontEnd_data[23] <= !triangle_count[23];     // define sign bit
                    r_frontEnd_data[22:0] <= triangle_count[22:0];
*/                    
                end
                4: begin    // impulse
                    if (impulse_count == 1)
                        frontEnd_data <= 24'h7fff00;
                    else
                        frontEnd_data <= 0;
//                        frontEnd_data <= 24'h8000ff;
                end
                default:
                    frontEnd_data <= 0;
            endcase
        end
        else begin
            frontEnd_data <= frontEnd_data;
        end
    end
end


endmodule
