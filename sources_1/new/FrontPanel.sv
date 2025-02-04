`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2024 03:38:27 PM
// Design Name: 
// Module Name: FrontPanel
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


module FrontPanel(
// Common signals
    input           clk,
// Rotary Encoder    
    input           encoder_A,
    input           encoder_B,
    input           encoder_sw,
// encoder cpu interface
    input           rotary_encoder_rd_stb,
    output reg [7:0] rotary_encoder_reg,
// test
    output [15:0]   test    
 );
 
 reg [7:0]  rotary_enc_reg;
 wire       clkwise;
 wire [1:0] enc_value;
 wire       enc_sw_value;
 
// clockwise            enc_value(BA) = {00, 01, 11, 10}        
// counter clockwise    enc_value(BA) = {00, 10, 11, 01}  
assign test[0] = encoder_A;
assign test[1] = encoder_B;
assign test[3:2] = enc_value;   // sampled, debounced encoder value => [B,A]
assign test[4] = clkwise;       // rotation direction
assign test[5] = enc_sw_value;
assign test[6] =  user_state_change_stb;
assign test[7] =  click; 
assign test[12:8] = rotary_enc_reg[4:0];
assign test[13] =  rotary_encoder_rd_stb;
assign test[14] = rotary_encoder_reg[0];
assign test[15] = rotary_encoder_reg[2];


// clockwise            enc_value(BA) = {00, 01, 11, 10}        
// counter clockwise    enc_value(BA) = {00, 10, 11, 01}  
    
 rotaryEncoder rot_enc ( 
    // inputs  
    .clk                    (clk),
    .encoder_A              (encoder_A),
    .encoder_B              (encoder_B),
    .encoder_sw             (encoder_sw),
    // outputs
    .user_state_change_stb  (user_state_change_stb),     // strobe when enc value state changes
    .clockwise              (clkwise),
    .click                  (click),                    // enc_value of one in sync with enc_state_change_stb
    .switch                 (switch),                   // switch value in sync with enc_state_change_stb
    // below for test
    .test_cnt               (scaler_cnt),
    .enc_sw_value           (enc_sw_value),             // debounced switch value output
    .enc_value              (enc_value)                 // debounced encoder value output[1:0] 
 );
 

 
// rotary cpu interface
//      rotary_enc_reg[0] = click
//      rotary_enc_reg[1] = clkwise
//      rotary_enc_reg[2] = switch
//      rotary_enc_reg[3] = state change
//      rotary_enc_reg[4] = overflow
//      rotary_enc_reg[7:5] = 0

always @ (posedge clk) begin

    rotary_enc_reg[7:5] <= 0;           // spare bits set to zero

    if (user_state_change_stb)  begin       // enc state change occurs
        rotary_enc_reg[3] <= 1'b1;          // set state change bit 
        
//      if click state change when click state change bit is still set
//      or switch state change when switch state change bit is still set
/*        if ((rotary_enc_reg[0] && click) || (rotary_enc_reg[1] && switch))
            rotary_enc_reg[4] <= 1'b1;  // overflow bit set
        else
            rotary_enc_reg[4] <= 1'b0;  // overflow bit disabled 
*/
                   
        rotary_enc_reg[0] <= click;
        rotary_enc_reg[1] <= clkwise;
        rotary_enc_reg[2] <= switch;
    end
    else if (rotary_encoder_rd_stb)  begin 
        rotary_enc_reg[3] <= 1'b0;          // clear state change bit
        rotary_encoder_reg <= rotary_enc_reg;        
    // clear state change & overflow bitafter being read by the cpu
    // transfer encoder data for reading
/*    
        if (rotary_enc_reg[2] && !rotary_encoder_reg[2])         // sw, 1 if positive transition
            rotary_encoder_reg[2] <= 1'b1;
        else if (rotary_enc_reg[0] && !rotary_encoder_reg[0])    // click, 1 if positive transition
            rotary_encoder_reg[0] <= 1'b1;
        else begin
            rotary_encoder_reg[0] <= 1'b0;
            rotary_encoder_reg[2] <= 1'b0;       
        end
                
        rotary_encoder_reg[1] <= rotary_enc_reg[1];
*/        
    end
    else begin
       rotary_enc_reg <= rotary_enc_reg; 
       rotary_encoder_reg <= rotary_encoder_reg;
    end
end
    
endmodule
