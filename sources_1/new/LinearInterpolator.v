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
//
// Additional Comments:
//  Interpolation formular: InterpValue = snd_data[0]*(maxCnt - smplCnt) + snd_data[1]*(smplCnt)
//
//                           InterpValue
//                               V
//                      X--------|--------------X               >> time
//               snd_data[0]                snd_data[1] 
//                      |<--a--->|
//                      |<------- maxCnt -------|
//////////////////////////////////////////////////////////////////////////////////


module LinearInterpolator(
    input           clk,
    input           reset_n,
    input           run,
    input           l_din_en,      // ignore and just use r_din_en for both channels
    input           r_din_en,
    input [23:0]    l_data_in,
    input [23:0]    r_data_in,
    input [9:0]     sub_sample_cnt,
    output reg      dout_valid,
    output [33:0]   l_data_out,
    output [33:0]   r_data_out,
    // for test
    output reg [2:0]   interp_cnt,
    input [1:0]     test_d_select,
    output [15:0]    test_data 
);

reg [1:0]   l_snd_data[23:0];
reg [1:0]   r_snd_data[23:0];
reg [9:0]   mult_coef;
reg [1:0]   sub_sample_coef[9:0];
reg         din_en, din_temp, mult_en, dout_en, coef_sub_en, adder_en;
// reg [2:0]   interp_cnt;
reg [23:0]  l_mult_din, r_mult_din;
reg [33:0]  l_mult_dout, r_mult_dout;
reg [1:0]   l_dout[32:0];
reg [1:0]   r_dout[32:0];
reg [9:0]   sample_out_count, sub_sample_cnt_coef;
reg [10:0]  sub_sample_result;


parameter sub_sample_max = 10'h1ff;      // divide by 512 (programmabe later?)

// generate din_en, make sure din_en stays low and waits till state machine is inactive
always @ (posedge clk) begin
    if (r_din_en) begin                 // r_din_en is a strobe
        if (interp_cnt != 0) begin      // if state machine active
            din_temp <= 1'b1;
            din_en <= 1'b0;
        end
        else begin                      // if state machine idle
            din_en <= 1'b1;
            din_temp <= 1'b0;
        end
    end
    else begin  // if !r_din_en
        if (din_temp) begin
            if (interp_cnt == 0) begin  // if state machine idle
                din_en <= 1'b1;
                din_temp <= 1'b0;
            end
            else begin                  // if state machine active
                din_temp <= din_temp;
                din_en <= 1'b0;
            end
        end
        else begin  // if din_temp = 0
            din_temp <= 1'b0;
            din_en <= 1'b0;
        end
    end
end
            

// access 2 consecutive samples (l & r)
// get coefficient from sub sample count
always @ (posedge clk) begin
    if (din_en) begin
        r_snd_data[0] <= r_data_in;
        r_snd_data[1] <= r_snd_data[0];
        l_snd_data[0] <= l_data_in;
        l_snd_data[1] <= l_snd_data[0];
        sub_sample_cnt_coef <= sub_sample_cnt;
    end
    else begin
        r_snd_data <= r_snd_data;
        l_snd_data <= l_snd_data;
        sub_sample_cnt_coef <= sub_sample_cnt_coef; 
    end
    
end


// generate output sample clk @ 96KHz
// divide mclk 49.152MHz by 512 to create 96000Hz
always @ (posedge clk) begin
    if (!run) begin
        dout_en <= 1'b0;
        sample_out_count <= 0;
    end
    else if (sample_out_count == sub_sample_max) begin
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
            sub_sample_coef <= sub_sample_coef;
            
            if (dout_en) begin  
                interp_cnt <= 1;
                coef_sub_en <= 1;
            end
            else begin
                interp_cnt <= 0;
                coef_sub_en <= 0;
            end
        end
        1: begin
            interp_cnt <= 2;
            mult_en <= 1'b0;
            dout_valid <= 1'b0;
            // prevent a negative number
            if (sub_sample_result[10]) begin // if the result is negative
                sub_sample_coef[0] <= 0;
                sub_sample_coef[1] <= sub_sample_max;
            end
            else begin
                sub_sample_coef[0] <= sub_sample_result[9:0];   // 1 - a 
                sub_sample_coef[1] <= sub_sample_cnt_coef;      // a
            end
        end
            
        2: begin
            interp_cnt <= 3;
            mult_en <= 1'b0;
            dout_valid <= 1'b0;
            l_mult_din <= l_snd_data[0];
            r_mult_din <= r_snd_data[0];
            mult_coef <= sub_sample_coef[0];
        end
        
        3: begin
            interp_cnt <= 4;
            mult_en <= 1'b1;
            dout_valid <= 1'b0;
            l_mult_din <= l_snd_data[1];
            r_mult_din <= r_snd_data[1];
            mult_coef <= sub_sample_coef[1];
           
        end    
        4: begin
            interp_cnt <= 5;
            mult_en <= 1'b1;
            dout_valid <= 1'b0;
            l_dout[0] <= l_mult_dout[33:1];
            r_dout[0] <= r_mult_dout[33:1];
        end
        5: begin
            interp_cnt <= 6;
            mult_en <= 1'b0;
            adder_en <= 1'b1;
            dout_valid <= 1'b0;
            l_dout[1] <= l_mult_dout[33:1];
            r_dout[1] <= r_mult_dout[33:1];
        end         
        6: begin
            interp_cnt <= 0;
            mult_en <= 1'b0;
            adder_en <= 1'b0;
            dout_valid <= 1'b1;            
        end
        default: begin
            mult_en <= 1'b0;
            adder_en <= 1'b0;
            dout_valid <= 1'b0;
            interp_cnt <= 0;
            sub_sample_coef <= sub_sample_coef;
        end
    endcase
end
                

interpolator_subtractor l_interp_sub (
    .A            (sub_sample_max),         // input wire [9 : 0] A
    .B            (sub_sample_cnt_coef),    // input wire [9 : 0] B
    .CLK          (clk),                    // input wire CLK
    .CE           (coef_sub_en),            // input wire CE
    .S            (sub_sample_result)       // output wire [10 : 0] S
);

                

interp_mult l_interp_mult (
    .CLK    (clk),              // input wire CLK
    .CE     (mult_en),          // input wire CE
    .A      (l_mult_din),       // input wire [23 : 0] B
    .B      (mult_coef),        // input wire [9 : 0] A
    .P      (l_mult_dout)       // output wire [33 : 0] P);
 );
   
interp_mult r_interp_mult (
    .CLK    (clk),              // input wire CLK
    .CE     (mult_en),          // input wire CE
    .A      (r_mult_din),       // input wire [23 : 0] B
    .B      (mult_coef),        // input wire [9 : 0] A
    .P      (r_mult_dout)       // output wire [33 : 0] P);
 );
   
Interpolator_adder l_interp_add (
  .A            (l_dout[0]),            // input wire [32 : 0] A
  .B            (l_dout[1]),            // input wire [32 : 0] B
  .CLK          (clk),                  // input wire CLK
  .CE           (add_en),               // input wire CE
  .S            (l_data_out)            // output wire [33 : 0] S
);

Interpolator_adder r_interp_add (
  .A            (r_dout[0]),            // input wire [32 : 0] A
  .B            (r_dout[1]),            // input wire [32 : 0] B
  .CLK          (clk),                  // input wire CLK
  .CE           (add_en),               // input wire CE
  .S            (r_data_out)            // output wire [33 : 0] S
);


//      TEST


assign test_data =      (test_d_select == 0) ?  r_data_in[15:0] :
                        (test_d_select == 1) ?  r_data_in[23:8] :
                        (test_d_select == 2) ?  l_data_in[15:0] :
                                                l_data_in[23:8];

endmodule
