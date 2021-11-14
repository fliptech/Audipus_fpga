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
//  Interpolation formular: InterpValue = snd_data[1]*(maxCnt - smplCnt) + snd_data[0]*(smplCnt)
//                          InterpValue = snd_data[1]*(sub_sample_count - intrp_sub_sample) + snd_data[0]*intrp_sub_sample
//
//
//                           InterpValue
//                               V
//                      X--------|--------------X               >> time, X = input sample points
//               snd_data[1]                snd_data[0]         >> V = 96KHz sample points
//                      |<--a--->|
//                      |<------- maxCnt -------|
//////////////////////////////////////////////////////////////////////////////////
//
//      


module LinearInterpolator(
    input           clk,
    input           reset_n,
    input           run,
    input           din_en,
    input[1:0]      out_sel,
    input [23:0]    l_data_in,
    input [23:0]    r_data_in,
    output          l_dout_valid,
    output          r_dout_valid,
    output [23:0]   l_data_out,
    output [23:0]   r_data_out,
    // for test
    output [15:0]       test_data 
);


reg [2:0]   interp_state;
reg [23:0]  l_snd_data[1:0];
reg [23:0]  r_snd_data[1:0];
reg [23:0]   l_intrp_data[1:0];
reg [23:0]   r_intrp_data[1:0];
//reg [10:0]   intrp_coef[1:0];
reg [10:0]  mult_coef;
reg         mult_en, dout_en, coef_sub_en, adder_en, div_en;
// reg [2:0]   interp_cnt;
reg [23:0]  l_mult_din, r_mult_din;
reg [34:0]  l_mult_dout, r_mult_dout;
reg [32:0]  l_dout_A,  l_dout_B;
reg [32:0]  r_dout_A,  r_dout_B;
reg [10:0]   input_max_sample_count, input_sample_count, input_sample_counter; 
reg [10:0]   coef_sub_sample; 
reg [10:0]   sample_96KHz_count;
reg [10:0]   interp_sub_result;
reg [10:0]   interp_test_reg;

wire [33:0] l_accum_out, r_accum_out;
wire [47:0] l_div_out, r_div_out;
wire        l_div_valid, r_div_valid;

/// Output Assignments \\\
assign  l_data_out = l_div_out[31:8];
assign  r_data_out = r_div_out[31:8];
assign  l_dout_valid = l_div_valid;
assign  r_dout_valid = r_div_valid;

/* /// for test \\\
assign  r_data_out =    (out_sel == 0) ? r_div_out[47:24] :     // test view [47:37]
                        (out_sel == 1) ? r_div_out[36:13] :     // test view [36:26]     
                        (out_sel == 2) ? r_div_out[26:3] :      // test view [26:16]
                        0;
*/

parameter sample_96KHz_max = 11'h1ff;      // divide by 512 for 96KHz (programmabe later?)



// generate System sample clk @ 96KHz
// divide mclk 49.152MHz by sample_96KHz_max (512) to create 96000Hz
always @ (posedge clk) begin
    if (!run) begin
        dout_en <= 1'b0;
        sample_96KHz_count <= 0;
        input_sample_count <= 0;
    end
    else if (sample_96KHz_count == sample_96KHz_max) begin
        sample_96KHz_count <= 0;
        dout_en <= 1'b1;
        input_sample_count <= input_sample_counter;     // hold count value at the 96KHz sample
    end
    else begin
        sample_96KHz_count <= sample_96KHz_count + 1;
        dout_en <= 1'b0;
        input_sample_count <= input_sample_count;
    end
end

// Capture Input Data
// access 2 consecutive samples (l & r) and sub_sample count between the 2 samples
// get coefficient from sub sample count
always @ (posedge clk) begin
    if(din_en) begin              // strobe, start/end of a sample
        r_snd_data[0] <= r_data_in;
        r_snd_data[1] <= r_snd_data[0];
        l_snd_data[0] <= l_data_in;
        l_snd_data[1] <= l_snd_data[0];
        input_sample_counter <= 0;
        input_max_sample_count <= input_sample_counter;
    end
    else begin
        r_snd_data <= r_snd_data;
        l_snd_data <= l_snd_data;
        input_sample_counter <= input_sample_counter + 1;        
        input_max_sample_count <= input_max_sample_count;
    end
end


/* (Barrel shift and) Hold Input Data if State Machine Active
always @ (posedge clk) begin
// barrel shifter
        case (input_max_sample_count[10:7]) 
            4'b0010, 4'b0001, 4'b000: begin     // range: 0 to 0x17f  -> 0 to 383
                // shift 2 <<
                intrp_input_count <= {input_sample_count[8:0], 2'b00};          
                intrp_input_max_count <= {input_max_sample_count[8:0], 2'b00}; 
            end
            4'b0101, 4'b0100, 4'b0011: begin     // range: 0x180 to 0x2ff  -> 384 to 767
                // shift 1 <<
                intrp_input_count <= {input_sample_count[9:0], 1'b0}; 
                intrp_input_max_count <= {1'b0, input_max_sample_count[9:0], 1'b0}; 
            end
            default: begin                      // range: 0x300 to 0x7ff  -> 768 to 2047  
                // no shift
                intrp_input_count <= input_sample_count; 
                intrp_input_max_count <= input_max_sample_count; 
            end
        endcase
///
    end
    else begin
        l_intrp_data <= l_intrp_data;
        r_intrp_data <= r_intrp_data;
        intrp_input_max_count <= intrp_input_max_count;
    end
end
*/   

// Interpolatator State Machine
always @ (posedge clk) begin
//    interp_test_reg <= {fifo_A_full, fifo_B_full, fifo_A_empty, fifo_B_empty, coef_A_wr, coef_switch, next_coef, fifo_B_rd_en, fifo_B_wr_en, fifo_A_rd_en, fifo_A_wr_en};
    case (interp_state)
        3'h0: begin                        // idle
            mult_en <= 1'b0;
            coef_sub_en <= 1'b1;       // subtractor left enabled
            adder_en <= 1'b0;
            div_en <= 1'b0;
            
            if (dout_en) begin          // move out of idle  
                interp_state <= 3'h1;
                coef_sub_sample <= input_sample_counter;
                l_intrp_data[0] <= l_snd_data[0];
                l_intrp_data[1] <= l_snd_data[1];
                r_intrp_data[0] <= r_snd_data[0];
                r_intrp_data[1] <= r_snd_data[1];
                interp_test_reg <= input_sample_counter;    // = coef_sub_sample (a)
            end
            else begin
                interp_state <= 3'h0;
                
                coef_sub_sample <= coef_sub_sample;               
                l_intrp_data <= l_intrp_data;
                r_intrp_data <= r_intrp_data;
                
                interp_test_reg <= r_data_in[23:13];
//                interp_test_reg <= intrp_input_max_count;
            end
        end
        3'h1: begin
            interp_state <= 3'h2;
            coef_sub_en <= 1'b0;        // disable subtractor
            mult_en <= 1'b1;            // enable mult_en
            adder_en <= 1'b0;
            div_en <= 1'b0;

            l_mult_din <= l_intrp_data[0];
            r_mult_din <= r_intrp_data[0];
            mult_coef <= coef_sub_sample;         // mult_coef <= current input sample position:  a
                
            coef_sub_sample <= coef_sub_sample;               
            l_intrp_data <= l_intrp_data;
            r_intrp_data <= r_intrp_data;
            
            interp_test_reg <= r_intrp_data[0][23:13];
        end
            
        3'h2: begin
            interp_state <= 3'h3;
            coef_sub_en <= 1'b0;
            mult_en <= 1'b1;            // enable mult_en
            adder_en <= 1'b0;
            div_en <= 1'b0;

            coef_sub_sample <= coef_sub_sample;               
            l_mult_din <= l_intrp_data[1];
            r_mult_din <= r_intrp_data[1];
            mult_coef <= interp_sub_result;             // mult_coef <= subtracter result:  1 - a             
                
            l_intrp_data <= l_intrp_data;
            r_intrp_data <= r_intrp_data;
            
            interp_test_reg <= interp_sub_result;
                                   
        end       
        3'h3: begin             
            interp_state <= 3'h4;
            mult_en <= 1'b0;
            coef_sub_en <= 1'b0;
            adder_en <= 1'b0;
            div_en <= 1'b0;
             
            l_dout_B <= l_mult_dout[34:2];
            r_dout_B <= r_mult_dout[34:2];
            l_dout_A <= l_dout_A; 
            r_dout_A <= r_dout_A; 
                
            coef_sub_sample <= coef_sub_sample;               
            l_intrp_data <= l_intrp_data;
            r_intrp_data <= r_intrp_data;
            
            interp_test_reg <= r_mult_dout[34:24];        // result = d[1] x (1 - a)
        end
        3'h4: begin                     
            interp_state <= 3'h5;
            mult_en <= 1'b0;
            coef_sub_en <= 1'b0;
            adder_en <= 1'b1;
            div_en <= 1'b0;
            
            l_dout_A <= l_mult_dout[34:2];
            r_dout_A <= r_mult_dout[34:2];
            l_dout_B <= l_dout_B; 
            r_dout_B <= r_dout_B; 
                
            coef_sub_sample <= coef_sub_sample;               
            l_intrp_data <= l_intrp_data;
            r_intrp_data <= r_intrp_data;
            
            interp_test_reg <= r_mult_dout[34:24];      // result = d[0] x a
        end         
        3'h5: begin
            interp_state <= 3'h6;
            mult_en <= 1'b0;
            coef_sub_en <= 1'b0;
            adder_en <= 1'b0;
             
            if (r_divisor_ready && r_dividend_ready && l_divisor_ready && l_dividend_ready) begin
                interp_state <= 3'h6;
                div_en <= 1'b1;
             end
             else begin
                interp_state <= 3'h5;
                div_en <= 1'b0;
             end
            
            l_dout_A <= l_dout_A; 
            r_dout_A <= r_dout_A; 
            l_dout_B <= l_dout_B; 
            r_dout_B <= r_dout_B; 
                
            coef_sub_sample <= coef_sub_sample;               
            l_intrp_data <= l_intrp_data;
            r_intrp_data <= r_intrp_data;
            
            interp_test_reg <= r_intrp_data[1][23:13];           
        end
        3'h6: begin
            interp_state <= 3'h7;
            mult_en <= 1'b0;
            coef_sub_en <= 1'b0;
            adder_en <= 1'b0;
            div_en <= 1'b0;
                
            coef_sub_sample <= coef_sub_sample;               
            l_intrp_data <= l_intrp_data;
            r_intrp_data <= r_intrp_data;
            
            interp_test_reg <= r_accum_out[33:23];           
        end
        3'h7: begin
            
            mult_en <= 1'b0;
            coef_sub_en <= 1'b0;
            adder_en <= 1'b0;
                 
            coef_sub_sample <= coef_sub_sample;               
            l_intrp_data <= l_intrp_data;
            r_intrp_data <= r_intrp_data;
            
            if (r_div_valid) begin
                interp_state <= 3'h0;
                interp_test_reg <= r_data_out[23:13]; 
            end
            else begin
                interp_state <= 3'h7;
                interp_test_reg <= r_accum_out[33:23]; 
            end              
        end
        default: begin
            mult_en <= 1'b0;
            coef_sub_en <= 1'b0;       // disable subtractor
            adder_en <= 1'b0;
            div_en <= 1'b0;
            interp_state <= 3'h0;
                
            coef_sub_sample <= coef_sub_sample;               
            l_intrp_data <= l_intrp_data;
            r_intrp_data <= r_intrp_data;
            
            interp_test_reg <= 11'h7ff;
        end
    endcase
end
                

interpolator_subtractor l_interp_sub (
    .A            (input_max_sample_count), // input wire [10 : 0] A
    .B            (coef_sub_sample),        // input wire [10 : 0] B
    .CLK          (clk),                    // input wire CLK
    .CE           (coef_sub_en),            // input wire CE
    .S            (interp_sub_result)           // output wire [10 : 0] S
);

                

interp_mult l_interp_mult (
    .CLK    (clk),              // input wire CLK
    .CE     (mult_en),          // input wire CE
    .A      (l_mult_din),       // input wire [23 : 0] A signed
    .B      (mult_coef),        // input wire [10 : 0] B
    .P      (l_mult_dout)       // output wire [34 : 0] P);
 );
   
interp_mult r_interp_mult (
    .CLK    (clk),              // input wire CLK
    .CE     (mult_en),          // input wire CE
    .A      (r_mult_din),       // input wire [23 : 0] A signed
    .B      (mult_coef),        // input wire [10 : 0] B
    .P      (r_mult_dout)       // output wire [34 : 0] P);
 );
   
Interpolator_adder l_interp_add (
  .A            (l_dout_A),            // input wire [32 : 0] A
  .B            (l_dout_B),            // input wire [32 : 0] B
  .CLK          (clk),                  // input wire CLK
  .CE           (adder_en),             // input wire CE
  .S            (l_accum_out)            // output wire [33 : 0] S
);

Interpolator_adder r_interp_add (
  .A            (r_dout_A),            // input wire [32 : 0] A
  .B            (r_dout_B),            // input wire [32 : 0] B
  .CLK          (clk),                  // input wire CLK
  .CE           (adder_en),               // input wire CE
  .S            (r_accum_out)            // output wire [33 : 0] S
);

// Quotient = Dividend / Divisor
// Output = interpolator_data / input_max_sample_count
// right
interpolationScaler_divider r_interp_divider (
    .aclk                   (clk),                                  // input
    .s_axis_divisor_tvalid  (div_en),                               // input
    .s_axis_divisor_tready  (r_divisor_ready),                      // output
    .s_axis_divisor_tdata   ({5'b00000, input_max_sample_count}),   // input[15 : 0], bit 11 is the sign bit
    .s_axis_dividend_tvalid (div_en),                               // input
    .s_axis_dividend_tready (r_dividend_ready),                     // output
    .s_axis_dividend_tdata  (r_accum_out[33:2]),                    // input[31 : 0] s_axis_dividend_tdata
    .m_axis_dout_tvalid     (r_div_valid),                          // output
    .m_axis_dout_tdata      (r_div_out)                            // output[47 : 0]; 43:12 data, 11:0 fraction
);
// left
interpolationScaler_divider l_interp_divider (
    .aclk                   (clk),                                  // input
    .s_axis_divisor_tvalid  (div_en),                               // input
    .s_axis_divisor_tready  (l_divisor_ready),                      // output
    .s_axis_divisor_tdata   ({5'b00000, input_max_sample_count}),   // input[15 : 0], bit 11 is the sign bit
    .s_axis_dividend_tvalid (div_en),                               // input
    .s_axis_dividend_tready (l_dividend_ready),                     // output
    .s_axis_dividend_tdata  (l_accum_out[33:2]),                    // input[31 : 0] s_axis_dividend_tdata
    .m_axis_dout_tvalid     (l_div_valid),                          // output
    .m_axis_dout_tdata      (l_div_out)                            // output[47 : 0]; 43:12 data, 11:0 fraction
);

//      TEST

assign test_data[4:0] =     {interp_state, din_en, dout_en};
assign test_data[15:5] =    interp_test_reg;


endmodule
