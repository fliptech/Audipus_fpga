`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2021 04:45:47 PM
// Design Name: 
// Module Name: StepperMotorDrive
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


module StepperMotorDrive(
    input clk,
    input motor_en,
    input reverse,
    input [7:0] motor_interval,
    output reg [3:0] step_drv
);

reg interval_stb;
reg [7:0] interval_count;

always @ (posedge clk) begin
    if (motor_en) begin
        if (interval_count <= motor_interval) begin
            interval_count <= 0;
            interval_stb <= 1'b1;
        end
        else begin
            interval_count <= interval_count + 1;
            interval_stb <= 1'b0;
        end
    end
    else begin
        interval_count <= 0;
        interval_stb <= 1'b0;
    end
end            

always @ (posedge clk) begin
    if (motor_en) begin
        if (interval_stb) begin
            if (reverse)
                step_drv <= step_drv - 1;
            else
                step_drv <= step_drv + 1;
        end
        else
            step_drv <= step_drv;
    end
    else
        step_drv <= 0;
end

endmodule
