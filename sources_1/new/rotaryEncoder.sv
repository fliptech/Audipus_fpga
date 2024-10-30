`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/07/2024 03:38:47 PM
// Design Name: 
// Module Name: rotaryEncoder
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


module rotaryEncoder # (
    parameter CLK_SCALER_VALUE = 16383      // 3KHz shift clk
)(
    input clk,
    input reset,
    input encoder_A,
    input encoder_B,
    output reg          enc_state_change_stb,   // encoder state has changed
    output reg          clockwise,                // rotation direction
    output reg [1:0]    enc_value,              // debounced encoder value => [B,A]
    output [1:0]        encoder_state           // state machine's state (for test)
);

    reg [7:0]   clk_scaler = 0;
    reg [3:0]   enc_reg_A, enc_reg_B;
    
     
    assign clkwise = clockwise;

//  Encoder sampler and debouncer
    always @ (posedge clk) begin
        if (clk_scaler == CLK_SCALER_VALUE) begin   // creates encoder sample strobe @ main_clk/CLK_SCALER_VALUE
            clk_scaler <= 0;
            enc_reg_A[0] <= encoder_A;
            enc_reg_B[0] <= encoder_B;
            enc_reg_A[3:1] <=  enc_reg_A[2:0];      // shift left
            enc_reg_B[3:1] <=  enc_reg_B[2:0];      // shift left
            // compare enc_reg values   
            if (enc_reg_A == 4'h0) begin // A is 0x0
                enc_value[0] <= 1'b0;
            end
            if (enc_reg_B == 4'h0) begin // B is 0x0
                enc_value[1] <= 1'b0;
            end    
            if (enc_reg_A == 4'hf) begin // A is 0xf
                enc_value[0] <= 1'b1;
            end
            if (enc_reg_B == 4'hf) begin // B is 0xf
                enc_value[1] <= 1'b1;
            end    
            else begin
                enc_value <= enc_value;
            end                                    
        end     
        else begin   
            clk_scaler <= clk_scaler + 1;
            enc_reg_A <= enc_reg_A;
            enc_reg_B <= enc_reg_B;
            enc_value <= enc_value;
        end 
     end // always
     
// clockwise            enc_value(BA) = {00, 01, 11, 10}        
// counter clockwise    enc_value(BA) = {00, 10, 11, 01}  

typedef enum reg [1:0] {zero, between_01, one, between_10} EncoderState;

EncoderState    encoder_state, encoder_state_dly;
reg             state_change_stb;

// Encoder State Machine      
always @ (posedge clk) begin

    encoder_state_dly <= encoder_state;
    if (encoder_state_dly != encoder_state) begin   // strobe when a change in encoder states            
        enc_state_change_stb <= 1'b1;
                          
        case (encoder_state) 
            zero: begin
                if (enc_value == 'b01) begin
                    clockwise <= 1'b1;
                    encoder_state <= enc.between_01;
                end             
                else if (enc_value == 'b10) begin
                    clockwise <= 1'b0;
                    encoder_state <= between_10;
                end
            end                 
            between_01: begin
                if (enc_value == 'b11) begin
                    clockwise <= 1'b1;
                    encoder_state <= one;
                end    
                else if (enc_value == 'b00) begin
                    clockwise <= 1'b0;
                    encoder_state <=  zero;
                end             
            end                           
            one: begin
                if (enc_value == 'b10) begin
                    clockwise <= 1'b1;
                    encoder_state <= between_10;
                end    
                else if (enc_value == 'b01) begin
                    clockwise <= 1'b0;
                    encoder_state <=  between_01;
                end             
            end             
            between_10: begin
                if (enc_value == 'b00) begin
                    clockwise <= 1'b1;
                    encoder_state <= zero;
                end    
                else if (enc_value == 'b11) begin
                    clockwise <= 1'b0;
                    encoder_state <=  one;
                end             
            end                           
            default: begin
                clockwise <= clockwise;
                encoder_state <= encoder_state;
            end                
        endcase; 
    end  // end if
    else begin  
        enc_state_change_stb <= 1'b0; 
        clockwise <= clockwise;
        encoder_state <= encoder_state;
    end  // end else
end   // end always            

                      
endmodule
