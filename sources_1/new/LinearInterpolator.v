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
    input           l_din_en,      // ignore and just use r_din_en for both channels
    input           r_din_en,
    input [23:0]    l_data_in,
    input [23:0]    r_data_in,
    input [10:0]     sub_sample_cnt,
    output reg      dout_valid,
    output [33:0]   l_data_out,
    output [33:0]   r_data_out,
    // for test
    input [1:0]         test_d_select,
    output [15:0]       test_data 
);


reg [2:0]   interp_state;
reg [23:0]  l_snd_data[1:0];
reg [23:0]  r_snd_data[1:0];
reg [23:0]   l_intrp_data[1:0];
reg [23:0]   r_intrp_data[1:0];
//reg [10:0]   intrp_coef[1:0];
reg [10:0]  mult_coef;
reg         mult_en, dout_en, coef_sub_en, adder_en;
// reg [2:0]   interp_cnt;
reg [23:0]  l_mult_din, r_mult_din;
reg [34:0]  l_mult_dout, r_mult_dout;
reg [32:0]  l_dout_A,  l_dout_B;
reg [32:0]  r_dout_A,  r_dout_B;
reg [10:0]   input_max_sample_count, input_sample_count, input_sample_counter; 
reg [10:0]   snd_sample_count, snd_sample_max_count; 
reg [10:0]   intrp_input_max_count, sample_96KHz_count;
reg [10:0]   interp_sub_result;
reg [10:0]   interp_test_reg;


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
    if(r_din_en) begin              // strobe, start/end of a sample
        r_snd_data[0] <= r_data_in;
        r_snd_data[1] <= r_snd_data[0];
        l_snd_data[0] <= l_data_in;
        l_snd_data[1] <= l_snd_data[0];
        input_sample_counter <= 0;
        input_max_sample_count <= input_sample_counter;
        coef_switch <= !coef_switch;
    end
    else begin
        r_snd_data <= r_snd_data;
        l_snd_data <= l_snd_data;
        input_sample_counter <= input_sample_counter + 1;        
        input_max_sample_count <= input_max_sample_count;
        coef_switch <= coef_switch; 
    end
end
/*
always @ (posedge clk) begin
    if (coef_A_wr) begin
        fifo_A_wr_en <= dout_en;
        fifo_A_rd_en <= 1'b0;
        fifo_B_wr_en <= 1'b0;
        fifo_B_rd_en <= coef_rd_en;
    end
    else begin
        fifo_A_wr_en <= 1'b0;
        fifo_A_rd_en <= coef_rd_en;
        fifo_B_wr_en <= dout_en;
        fifo_B_rd_en <= 1'b0;
    end
 */
reg coef_A_wr, coef_switch, next_coef;
 
wire fifo_A_wr_en = coef_A_wr ? dout_en : 1'b0;
wire fifo_B_wr_en = !coef_A_wr ? dout_en : 1'b0;
wire fifo_A_rd_en = !coef_A_wr ? next_coef : 1'b0;
wire fifo_B_rd_en = coef_A_wr ? next_coef : 1'b0;
wire sample_fifo_empty = coef_A_wr ? fifo_A_empty : fifo_B_empty;
wire sample_fifo_full = coef_A_wr ? fifo_A_full : fifo_B_full;
wire [10:0] coef_sub_sample = coef_A_wr ? fifo_A_dout : fifo_B_dout;
            
 sample_count_fifo  smpl_cnt_fifo_A (
    .clk        (clk),      // input wire clk
    .srst       (~reset_n),    // input wire srst
    .din        (input_sample_count),      // input wire [10 : 0] din
    .wr_en      (fifo_A_wr_en),  // input wire wr_en
    .rd_en      (fifo_A_rd_en),  // input wire rd_en
    .dout       (fifo_A_dout),    // output wire [10 : 0] dout
    .full       (fifo_A_full),    // output wire full
    .empty      (fifo_A_empty)  // output wire empty
);
           
 sample_count_fifo  smpl_cnt_fifo_B (
    .clk        (clk),      // input wire clk
    .srst       (~reset_n),    // input wire srst
    .din        (input_sample_count),      // input wire [10 : 0] din
    .wr_en      (fifo_B_wr_en),  // input wire wr_en
    .rd_en      (fifo_B_rd_en),  // input wire rd_en
    .dout       (fifo_B_dout),    // output wire [10 : 0] dout
    .full       (fifo_B_full),    // output wire full
    .empty      (fifo_B_empty)  // output wire empty
);
           
 
/*         
parameter SmpRate_192KHz = 6'hff;   //   256
parameter SmpRate_96KHz = 6'h1ff;   //   512
parameter SmpRate_48KHz = 6'h3ff;   //  1024
parameter SmpRate_44_1KHz = 6'h45a; //  1115 -> 0x458
parameter SmpRate_88_2KHz = 6'h22c; //   557
*/

// (Barrel shift and) Hold Input Data if State Machine Active
always @ (posedge clk) begin
    if((interp_state == 0) && !dout_en) begin               
//    if(interp_state) begin               
        l_intrp_data[0] <= l_snd_data[0];
        l_intrp_data[1] <= l_snd_data[1];
        r_intrp_data[0] <= r_snd_data[0];
        r_intrp_data[1] <= r_snd_data[1];

        intrp_input_max_count <= snd_sample_max_count; 
        coef_A_wr <= coef_switch;
/*
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
*/
    end
    else begin
        l_intrp_data <= l_intrp_data;
        r_intrp_data <= r_intrp_data;
        intrp_input_max_count <= intrp_input_max_count;
        coef_A_wr <= coef_A_wr;
    end
end

    

// Interpolatator State Machine
always @ (posedge clk) begin
    case (interp_state)
        3'h0: begin                        // idle
            mult_en <= 1'b0;
            coef_sub_en <= 1'b1;       // subtractor left enabled
            adder_en <= 1'b0;
            dout_valid <= 1'b0;
            next_coef <= 1'b0;
            
            if (dout_en) begin          // move out of idle  
                interp_state <= 3'h1;
                interp_test_reg <= coef_sub_sample;
            end
            else begin
                interp_state <= 3'h0;
                interp_test_reg <= r_data_in[23:13];
//                interp_test_reg <= intrp_input_max_count;
            end
        end
        3'h1: begin
            interp_state <= 3'h2;
            coef_sub_en <= 1'b0;        // disable subtractor
            mult_en <= 1'b1;            // enable mult_en
            adder_en <= 1'b0;
            dout_valid <= 1'b0;
            next_coef <= 1'b0;

            l_mult_din <= l_intrp_data[1];
            r_mult_din <= r_intrp_data[1];
            mult_coef <= interp_sub_result;             // mult_coef <= subtracter result:  1 - a 
            interp_test_reg <= interp_sub_result;
        end
            
        3'h2: begin
            interp_state <= 3'h3;
            coef_sub_en <= 1'b0;
            mult_en <= 1'b1;            // enable mult_en
            adder_en <= 1'b0;
            dout_valid <= 1'b0;
            next_coef <= 1'b0;
            
            l_mult_din <= l_intrp_data[0];
            r_mult_din <= r_intrp_data[0];
            mult_coef <= coef_sub_sample;         // mult_coef <= current input sample position:  a
                                    
            interp_test_reg <= r_intrp_data[0][23:13];
        end       
        3'h3: begin             
            interp_state <= 3'h4;
            mult_en <= 1'b0;
            coef_sub_en <= 1'b0;
            adder_en <= 1'b0;
            dout_valid <= 1'b0;
            next_coef <= 1'b0;
            
            l_dout_B <= l_mult_dout[34:2];
            r_dout_B <= r_mult_dout[34:2];
            l_dout_A <= l_dout_A; 
            r_dout_A <= r_dout_A; 
            
            interp_test_reg <= r_mult_dout[34:24];        // result = d[1] x (1 - a)
        end
        3'h4: begin                     
            interp_state <= 3'h5;
            mult_en <= 1'b0;
            coef_sub_en <= 1'b0;
            adder_en <= 1'b1;
            dout_valid <= 1'b0;         // enable dout_vaild
            next_coef <= 1'b0;
            
            l_dout_A <= l_mult_dout[34:2];
            r_dout_A <= r_mult_dout[34:2];
            l_dout_B <= l_dout_B; 
            r_dout_B <= r_dout_B; 
            
            interp_test_reg <= r_mult_dout[34:24];      // result = d[0] x a
        end         
        3'h5: begin
            interp_state <= 3'h6;
            mult_en <= 1'b0;
            coef_sub_en <= 1'b0;
            adder_en <= 1'b0;
            dout_valid <= 1'b1;
            next_coef <= 1'b0;
             
            l_dout_A <= l_dout_A; 
            r_dout_A <= r_dout_A; 
            l_dout_B <= l_dout_B; 
            r_dout_B <= r_dout_B; 

            interp_test_reg <= r_intrp_data[1][23:13];           
        end
        3'h6: begin
            interp_state <= 3'h0;
            mult_en <= 1'b0;
            coef_sub_en <= 1'b0;
            adder_en <= 1'b0;
            dout_valid <= 1'b0;
            next_coef <= 1'b1;
             
            interp_test_reg <= r_data_out[33:23];           
        end
        default: begin
            mult_en <= 1'b0;
            coef_sub_en <= 1'b0;       // disable subtractor
            adder_en <= 1'b0;
            dout_valid <= 1'b0;
            interp_state <= 3'h0;
            interp_test_reg <= 11'h7ff;
        end
    endcase
end
                

interpolator_subtractor l_interp_sub (
    .A            (intrp_input_max_count),  // input wire [10 : 0] A
    .B            (coef_sub_sample),        // input wire [10 : 0] B
    .CLK          (clk),                    // input wire CLK
    .CE           (coef_sub_en),            // input wire CE
    .S            (interp_sub_result)           // output wire [10 : 0] S
);

                

interp_mult l_interp_mult (
    .CLK    (clk),              // input wire CLK
    .CE     (mult_en),          // input wire CE
    .A      (l_mult_din),       // input wire [23 : 0] B
    .B      (mult_coef),        // input wire [10 : 0] A
    .P      (l_mult_dout)       // output wire [34 : 0] P);
 );
   
interp_mult r_interp_mult (
    .CLK    (clk),              // input wire CLK
    .CE     (mult_en),          // input wire CE
    .A      (r_mult_din),       // input wire [23 : 0] B
    .B      (mult_coef),        // input wire [10 : 0] A
    .P      (r_mult_dout)       // output wire [34 : 0] P);
 );
   
Interpolator_adder l_interp_add (
  .A            (l_dout_A),            // input wire [32 : 0] A
  .B            (l_dout_B),            // input wire [32 : 0] B
  .CLK          (clk),                  // input wire CLK
  .CE           (adder_en),             // input wire CE
  .S            (l_data_out)            // output wire [33 : 0] S
);

Interpolator_adder r_interp_add (
  .A            (r_dout_A),            // input wire [32 : 0] A
  .B            (r_dout_B),            // input wire [32 : 0] B
  .CLK          (clk),                  // input wire CLK
  .CE           (adder_en),               // input wire CE
  .S            (r_data_out)            // output wire [33 : 0] S
);


//      TEST


//assign test_data =      (test_d_select == 0) ?  {intrp_coef[1][10:3], intrp_coef[0][10:3]}:

//      SW command:         selectTestOutput

assign test_data[4:0] =     {interp_state, r_din_en, dout_valid};
assign test_data[15:5] =    interp_test_reg;

/*
assign test_data[15:5] =    (test_d_select == 0) ?  intrp_coef[0] :
                            (test_d_select == 1) ?  intrp_coef[1] :
                            (test_d_select == 2) ?  mult_coef :
                                                    intrp_input_max_count;


/*
assign test_data =      (test_d_select == 0) ?  r_data_in[15:0] :
                        (test_d_select == 1) ?  r_data_in[23:8] :
                        (test_d_select == 2) ?  l_data_in[15:0] :
                                                l_data_in[23:8];
*/

endmodule
