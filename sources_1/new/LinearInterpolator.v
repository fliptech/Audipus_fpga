`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/08/2021 04:25:18 PM
// Design Name: 
// Module Name: LinearInterpolator
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


module LinearInterpolator(
    input           clk,
    input           reset_n,
    input           run,
    input           l_din_en,
    input           r_din_en,
    input [23:0]    l_data_in,
    input [23:0]    r_data_in,
    output reg      dout_valid,
    output reg [31:0]   l_data_out,
    output reg [31:0]   r_data_out
);

reg [1:0]   l_snd_data[31:0];
reg [1:0]   r_snd_data[31:0];
reg [15:0]  sub_sample_counter, sub_sample_max, l_mult_coef, r_mult_coef;
reg [1:0]   sub_sample_coef[15:0];
reg         din_stb, din_dly, mult_en, dout_en;
reg [2:0]   interp_cnt;
reg [23:0]  l_mult_din, r_mult_din;
reg [1:0]   l_dout[31:0];
reg [1:0]   r_dout[31:0];
reg [9:0]   sample_out_count;



always @ (posedge clk) begin
    if (r_din_en) begin
        r_snd_data[0] <= r_data_in;
        r_snd_data[1] <= r_snd_data[0];
        l_snd_data[0] <= l_data_in;
        l_snd_data[1] <= l_snd_data[0];
        sub_sample_counter <= 0;
        sub_sample_max <= sub_sample_counter;
    end
    else begin
        r_snd_data <= r_snd_data;
        l_snd_data <= l_snd_data;
        sub_sample_max <= sub_sample_max;
        sub_sample_counter <= sub_sample_counter + 1; 
    end
    
end

// generate output sample clk @ 96KHz
// divide mclk 49.152MHz by 512 to create 96000Hz
always @ (posedge clk) begin
    if (!run) begin
        dout_en <= 1'b0;
        sample_out_count <= 0;
    end
    else if (sample_out_count == 10'h1ff) begin      // divide by 512
        sample_out_count <= 0;
        dout_en <= 1'b1;
    end
    else begin
        sample_out_count <= sample_out_count + 1;
        dout_en <= 1'b0;
    end
end



// Interpolatator State Machine
always @ (posedge clk) begin
    case (interp_cnt)
        0: begin
            mult_en <= 1'b0;
            dout_valid <= 1'b0;
            if (dout_en) begin
                interp_cnt <= 1;
                sub_sample_coef[1] <= sub_sample_counter;
                // prevent a negative number
                if (sub_sample_max > sub_sample_counter)
                    sub_sample_coef[0] <= sub_sample_max - sub_sample_counter; 
                else
                    sub_sample_coef[0] <= 0;
            end
            else begin
                interp_cnt <= 0;
                sub_sample_coef <= sub_sample_coef;
            end
        end
            
        1: begin
            interp_cnt <= 2;
            mult_en <= 1'b0;
            dout_valid <= 1'b0;
            l_mult_din <= l_snd_data[0];
            r_mult_din <= r_snd_data[0];
            l_mult_coef <= sub_sample_coef[0];
            r_mult_coef <= sub_sample_coef[0];
            dout_valid <= 1'b0;
        end
        
        2: begin
            interp_cnt <= 3;
            mult_en <= 1'b1;
            dout_valid <= 1'b0;
            l_mult_din <= l_snd_data[1];
            r_mult_din <= r_snd_data[1];
            l_mult_coef <= sub_sample_coef[1];
            r_mult_coef <= sub_sample_coef[1];
            
        end    
        3: begin
            interp_cnt <= 4;
            mult_en <= 1'b1;
            dout_valid <= 1'b0;
            l_dout[0] <= l_mult_dout;
            r_dout[0] <= r_mult_dout;
        end
        4: begin
            interp_cnt <= 5;
            mult_en <= 1'b0;
            dout_valid <= 1'b0;
            l_dout[1] <= l_mult_dout;
            r_dout[1] <= r_mult_dout;
        end         
        5: begin
            interp_cnt <= 0;
            mult_en <= 1'b0;
            dout_valid <= 1'b1;            
            l_data_out <= l_dout[0] + l_dout[1];
            r_data_out <= r_dout[0] + r_dout[1];
        end
        default: begin
            mult_en <= 1'b0;
            dout_valid <= 1'b1;
            interp_cnt <= 0;
            sub_sample_coef <= sub_sample_coef;
        end
    endcase
end
                
                

fir_tap_multiply l_interp_mult (
    .CLK    (clk),                  // input wire CLK
    .CE     (mult_en),           // input wire CE
    .SCLR   (reset_n),              // input wire SCLR
    .B      (l_mult_din),             // input wire [23 : 0] B
    .A      (l_mult_coef),         // input wire [15 : 0] A
    .P      (l_mult_dout)             // output wire [39 : 0] P);
 );
   
fir_tap_multiply r_interp_mult (
    .CLK    (clk),                  // input wire CLK
    .CE     (mult_en),           // input wire CE
    .SCLR   (reset_n),              // input wire SCLR
    .B      (r_mult_din),             // input wire [23 : 0] B
    .A      (r_mult_coef),         // input wire [15 : 0] A
    .P      (r_mult_dout)             // output wire [39 : 0] P);
 );
   


endmodule
