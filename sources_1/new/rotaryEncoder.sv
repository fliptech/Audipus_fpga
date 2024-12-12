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
    input encoder_sw,
    output reg          enc_state_change_stb,   // encoder state has changed
    output reg          clockwise,              // rotation direction
    output              click,                  // state machine's state all 1's (a click)
    output              switch,                 // switched pressed
    // below for test
    output [1:0]        test_cnt,
    output reg          enc_sw_value,           // debounced switch value
    output reg [1:0]    enc_value               // debounced encoder value => [B,A]
);

    reg [15:0]   clk_scaler;
    reg [3:0]   enc_reg_A, enc_reg_B, enc_reg_sw;
    
     
    assign clkwise = clockwise;
    assign test_cnt = clk_scaler[1:0];

//  Encoder sampler and debouncer
    always @ (posedge clk) begin
        if (clk_scaler == CLK_SCALER_VALUE) begin   // creates encoder sample strobe @ main_clk/CLK_SCALER_VALUE (3KHz)
            clk_scaler <= 0;
            enc_reg_A[0] <= encoder_A;
            enc_reg_B[0] <= encoder_B;
            enc_reg_sw <= encoder_sw;
            enc_reg_A[3:1] <=  enc_reg_A[2:0];      // shift left
            enc_reg_B[3:1] <=  enc_reg_B[2:0];      // shift left
            enc_reg_sw[3:1] <=  enc_reg_sw[2:0];    // shift left
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
            if (enc_reg_sw == 4'h0) begin // sw is 0x0
                enc_sw_value <= 1'b0;
            end    
            if (enc_reg_sw == 4'hf) begin // sw is 0xf
                enc_sw_value <= 1'b1;
            end
        end     
        else begin   
            clk_scaler <= clk_scaler + 1;
            enc_reg_A <= enc_reg_A;
            enc_reg_B <= enc_reg_B;
            enc_value <= enc_value;
            enc_sw_value <= enc_sw_value;
        end 
     end // always
     
// clockwise            enc_value(BA) = {00, 01, 11, 10}        
// counter clockwise    enc_value(BA) = {00, 10, 11, 01}  

typedef enum reg [1:0] {zero, between_01, one, between_10} EncoderState;

EncoderState    encoder_state;
reg[1:0]        enc_value_dly;
reg             state_change_stb;
reg             enc_sw_value_dly;

//cpu bits assignments
assign click = (encoder_state == one);  
assign switch = enc_sw_value; 

// Encoder State Machine      
always @ (posedge clk) begin

    enc_value_dly <= enc_value;
    enc_sw_value_dly <= enc_sw_value;
    
    if (enc_value_dly != enc_value) begin
                
        enc_state_change_stb <= 1'b1;         // strobe when a change in encoder states   

        case (encoder_state) 
            zero: begin
                if (enc_value == 'b01) begin
                    clockwise <= 1'b1;
                    encoder_state <= between_01;
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
    end // if
    
    else if (enc_sw_value_dly != enc_sw_value) begin
        enc_state_change_stb <= 1'b1;
        clockwise <= clockwise;
        encoder_state <= encoder_state;
    end // else if
    
    else begin
        enc_state_change_stb <= 1'b0;       // clear strobe
        clockwise <= clockwise;
        encoder_state <= encoder_state;
    end  // else                  

end   // end always            

                      
endmodule
