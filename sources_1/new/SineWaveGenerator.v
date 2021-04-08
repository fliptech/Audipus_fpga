`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/22/2021 01:50:13 PM
// Design Name: 
// Module Name: SineWaveGenerator
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


module SineWaveGenerator # (
    parameter NUMBER_OF_FREQS = 4
)(
    input               clk,
    input               run,
    input [3:0]         freq_sel,   // [3:0] => ... 4125Hz, 2250Hz, 562Hz, 93Hz
    output reg          data_valid,
    output reg [23:0]   sin_out
);

reg [2:0] sin_clken_count;
reg [3:0] chnl_count;
reg [5:0] sample_count;
reg       sin_clken, sin_data_ready; 

wire [23:0] sin_data_out;
wire [15:0] m_axis_phase_tdata;
    
sinWaveGen test_sin (
  .aclk                 (clk),                  // input wire aclk
  .aclken               (sin_clken),            // input wire aclken
  .m_axis_data_tvalid   (sin_data_valid),       // output wire m_axis_data_tvalid
  .m_axis_data_tready   (sin_data_ready),                  // input wire m_axis_data_tready
  .m_axis_data_tdata    (sin_data_out),         // output wire [23 : 0] m_axis_data_tdata
  // the rest below is not used
  .m_axis_phase_tvalid  (m_axis_phase_tvalid),  // input wire s_axis_phase_tvalid
  .m_axis_phase_tready  (run),                  // input wire m_axis_phase_tready
  .m_axis_phase_tdata   (m_axis_phase_tdata),   // input wire [15 : 0] s_axis_phase_tdata
  .event_pinc_invalid   (event_pinc_invalid)    // output wire event_pinc_invalid
);

// divide mclk 49.152MHz by 8 to create 6.144MHz via clken
always @ (posedge clk) begin
    if (!run) begin
        sin_clken <= 1'b0;
        sin_clken_count <= 0;
    end
    else if (sample_count == 3'b111) begin      // divide by 8
        sin_clken_count <= 0;;
        sin_clken <= 1'b1;
    end
    else begin
        sin_clken_count <= sin_clken_count + 1;
        sin_clken <= 1'b0;
    end
end

// Count off 64 sin_clken for a 96000Hz sample rate
// generate data_valid
always @ (posedge clk) begin
    if (!run) begin
        sin_data_ready <= 0;
        data_valid <= 1'b0;
    end
    else begin
        if (sin_clken) begin
            if (sample_count == 6'h3f) begin
                sin_data_ready = 1'b1;
                data_valid <= 1'b1;
            end
            else begin
                sample_count <= sample_count + 1;
                data_valid <= 1'b0;
            end
        end
        else begin
            sample_count <= sample_count;
            data_valid <= 1'b0;
        end
    end
end



// sin_data_out provides a multiple output stream of different defined frequencies, in a defined order
// sin_count[3:0] => 4125Hz, 2250Hz, 562Hz, 93Hz :: order 0=>3


always @ (posedge clk) begin
    if (!run) begin
        sin_data_ready <= 1'b0;
        chnl_count <= 0;      
    end
    else begin
        if (sin_clken) begin
            if ((sample_count == 6'h3f) && sin_data_valid) begin
                sin_data_ready <= 1'b1;
                chnl_count <= 0;                  
            end
            else if ((chnl_count == NUMBER_OF_FREQS-1) && sin_data_ready) begin
                sin_data_ready <= 1'b0;
                chnl_count <= 0;                                  
            end
            else begin
                sin_data_ready <= sin_data_ready;
                chnl_count <= chnl_count + 1;
            end
        end
        else begin
            sin_data_ready <= sin_data_ready;
            chnl_count <= chnl_count;
        end
    end
end



always @ (posedge clk) begin
    if (!sin_data_valid || !run) 
        sin_out <= 0;
    else begin
        if (sin_clken) begin
            if (chnl_count == freq_sel) 
                sin_out <= sin_data_out;
            else
                sin_out <= sin_out;
        end
        else
            sin_out <= sin_out;
    end
end

         
endmodule
