`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/22/2026 02:13:16 PM
// Design Name: 
// Module Name: effect_config
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


module effect_config (
    input wire [3:0] sw,
    output reg [3:0] led,
    output reg sw_echo,
    input wire led_echo,
    output reg sw_reverb,
    input wire led_reverb,
    output reg sw_overdrive,
    input wire led_overdrive,
    output wire muten
);
    
    assign muten = sw[0];
    
    always @* begin
        led[0] <= sw[0];
        led[1] <= led_echo;
        led[2] <= led_reverb;
        led[3] <= led_overdrive;
        //led[2] <= 1'b0;
        //led[3] <= 1'b0;
        
        sw_echo <= sw[1];
        sw_reverb <= sw[2];
        sw_overdrive <= sw[3];
    end
    
endmodule
