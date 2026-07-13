`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2026 01:21:00 AM
// Design Name: 
// Module Name: comb_filter
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


module comb_filter #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 24,
    parameter MAX_SAMPLES = 48000
)(
    input  wire aclk,
    input  wire valid,
    input  wire signed [DATA_WIDTH-1:0] audio_in,
    input  wire [ADDR_WIDTH-1:0] delay_time,
    input  wire signed [ADDR_WIDTH-1:0] feedback, // 0 a 100%
    output wire signed [DATA_WIDTH-1:0] audio_out
);

    (* ram_style = "block" *) 
    reg signed [DATA_WIDTH-1:0] buffer [0:MAX_SAMPLES-1];
    reg [ADDR_WIDTH-1:0] write_ptr = 0;
    wire [ADDR_WIDTH-1:0] read_ptr;
    reg signed [DATA_WIDTH-1:0] delay_out = 0;
    
    assign read_ptr = (write_ptr >= delay_time) ? (write_ptr - delay_time) : (MAX_SAMPLES - delay_time + write_ptr);
    
    wire signed [39:0] fb_mult = delay_out * $signed(feedback);
    wire signed [DATA_WIDTH-1:0] fb_path = fb_mult / 100;
    
    wire signed [DATA_WIDTH-1:0] delay_in = audio_in + fb_path;
    
    integer i;
    initial begin
        for (i = 0; i < MAX_SAMPLES; i = i + 1) begin
            buffer[i] = 24'd0;
        end
    end

    always @(posedge aclk) begin
        if (valid) begin
            buffer[write_ptr] <= delay_in;
            delay_out <= buffer[read_ptr];
            
            if (write_ptr >= MAX_SAMPLES - 1)
                write_ptr <= 0;
            else
                write_ptr <= write_ptr + 1;
        end
    end
    
    assign audio_out = delay_out;
endmodule
