`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/13/2021 03:39:24 PM
// Design Name: 
// Module Name: AudioMux
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
// Selects which input routes to the PCM to I2S (output) module
//////////////////////////////////////////////////////////////////////////////////


module AudioMux(
    input               clk,
    input               reset_n,
    input               run,
    input [1:0]         select,
    
    input               l_i2sToPcm_d_en,
    input               r_i2sToPcm_d_en,
    input [23:0]        l_i2sToPcm_d,
    input [23:0]        r_i2sToPcm_d,
    
    input               l_interp_d_en,
    input               r_interp_d_en,
    input [23:0]        l_interp_d,
    input [23:0]        r_interp_d,
    
    input               sin_wave_d_en,
    input [23:0]        sin_wave_d,
    
    input               l_eq_d_en,
    input               r_eq_d_en,
    input [23:0]        l_eq_d,
    input [23:0]        r_eq_d,
    
    output reg          l_pcmToI2s_d_valid,
    output reg          r_pcmToI2s_d_valid,
    output reg [23:0]   l_pcmToI2s_d,
    output reg [23:0]   r_pcmToI2s_d
);

always @ (posedge clk) begin
    if (!reset_n || !run) begin
        l_pcmToI2s_d <= 0;    
        r_pcmToI2s_d <= 0;
        l_pcmToI2s_d_valid <= 0;    
        r_pcmToI2s_d_valid <= 0;
    end
    else begin
        case (select) 
            2'b00: begin
                l_pcmToI2s_d_valid <= l_i2sToPcm_d_en;
                r_pcmToI2s_d_valid <= r_i2sToPcm_d_en;
                
                if (l_i2sToPcm_d_en)
                    l_pcmToI2s_d <= l_i2sToPcm_d;
                else
                    l_pcmToI2s_d <= l_pcmToI2s_d;
                    
                if (r_i2sToPcm_d_en)
                    r_pcmToI2s_d <= r_i2sToPcm_d;
                else
                    r_pcmToI2s_d <= r_pcmToI2s_d;
            end
            2'b01: begin
                l_pcmToI2s_d_valid <= l_interp_d_en;
                r_pcmToI2s_d_valid <= r_interp_d_en;
                
                if (l_interp_d_en)
                    l_pcmToI2s_d <= l_interp_d;
                else
                    l_pcmToI2s_d <= l_pcmToI2s_d;
                    
                if (r_interp_d_en)
                    r_pcmToI2s_d <= r_interp_d;
                else
                    r_pcmToI2s_d <= r_pcmToI2s_d;
            end
            2'b10: begin
                l_pcmToI2s_d_valid <= sin_wave_d_en;
                r_pcmToI2s_d_valid <= sin_wave_d_en;
                
                if (sin_wave_d_en) begin
                    l_pcmToI2s_d <= sin_wave_d;
                    r_pcmToI2s_d <= sin_wave_d;
                end
                else begin
                    l_pcmToI2s_d <= l_pcmToI2s_d;
                    r_pcmToI2s_d <= r_pcmToI2s_d;
                end
            end
            2'b11: begin
                l_pcmToI2s_d_valid <= l_eq_d_en;
                r_pcmToI2s_d_valid <= r_eq_d_en;
                
                if (l_eq_d_en)
                    l_pcmToI2s_d <= l_eq_d;
                else
                    l_pcmToI2s_d <= l_pcmToI2s_d;
                    
                if (r_eq_d_en)
                    r_pcmToI2s_d <= r_eq_d;
                else
                    r_pcmToI2s_d <= r_pcmToI2s_d;
            end
        endcase
    end
end

endmodule

        