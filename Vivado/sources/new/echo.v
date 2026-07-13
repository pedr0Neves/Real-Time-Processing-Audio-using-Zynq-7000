`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/19/2026 10:53:50 AM
// Design Name: 
// Module Name: echo
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


module echo #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 24,
    parameter AXIS_WIDTH = 32,
    parameter MAX_SAMPLES = 48000
)(
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axis:m_axis" *)
    input wire  aclk,
    
    // slave AXI-Stream
    input  wire [AXIS_WIDTH-1:0] s_axis_tdata,
    input  wire s_axis_tvalid,
    input  wire [2:0] s_axis_tid,
    output wire  s_axis_tready,
    
    // master AXI-Stream
    output wire [AXIS_WIDTH-1:0] m_axis_tdata,
    output wire m_axis_tvalid,
    input  wire m_axis_tready,
    output wire [2:0] m_axis_tid,
    
    input wire [ADDR_WIDTH-1:0] delay_time, 
    input wire [ADDR_WIDTH-1:0] feedback,   
    input wire [ADDR_WIDTH-1:0] dry_wet,     
    
    input  wire sw,
    output wire led
);
    // bloco de sinais referente a um comb filter
    (* ram_style = "block" *) 
    reg         [DATA_WIDTH-1:0] delay_buffer [0:2**(ADDR_WIDTH-1)-1];
    reg         [ADDR_WIDTH-1:0] write_ptr;
    wire        [ADDR_WIDTH-1:0] read_ptr;
    wire signed [DATA_WIDTH-1:0] delay_in;
    reg  signed [DATA_WIDTH-1:0] delay_out;
    
    wire signed [DATA_WIDTH-1:0] fb_path;
    wire signed [DATA_WIDTH-1:0] dry_wet_path;                                     
    wire signed [DATA_WIDTH-1:0] mixed_sample;
    
    wire signed [39:0] fb_mult;
    wire signed [39:0] dry_mult;
    wire signed [39:0] wet_mult;
    wire signed [39:0] mix_sum;
    
    wire signed [DATA_WIDTH-1:0] audio_in;
    wire p_bit_in;
    wire v_bit_in;
    wire u_bit_in;
    wire c_bit_in;
    wire [3:0] preamble_in;
    wire [DATA_WIDTH-1:0] audio_out;
    wire p_bit_out;
    wire v_bit_out;
    wire u_bit_out;
    wire c_bit_out;
    wire [3:0] preamble_out;
    
    integer i;
    initial begin
        write_ptr = 0;
        delay_out = 0;
        for (i = 0; i < 2**(ADDR_WIDTH-1); i = i + 1) begin
            delay_buffer[i] = 24'd0;
        end
    end
    
    assign p_bit_in = s_axis_tdata[31];
    assign c_bit_in = s_axis_tdata[30];
    assign u_bit_in = s_axis_tdata[29];
    assign v_bit_in = s_axis_tdata[28];
    assign audio_in = s_axis_tdata[27:4];
    assign preamble_in = s_axis_tdata[3:0];
	
    assign read_ptr = (write_ptr >= delay_time) ? (write_ptr - delay_time) : (2**(ADDR_WIDTH-1) - delay_time + write_ptr);
	always @(posedge aclk) begin 
        if (s_axis_tvalid && m_axis_tready) begin
                if(s_axis_tid == 3'd0) begin
                    delay_buffer[write_ptr] <= delay_in;
                    delay_out <= delay_buffer[read_ptr];
                
                    if (write_ptr >= 2**(ADDR_WIDTH-1) - 1) begin
                        write_ptr <= 0;
                    end else begin
                        write_ptr <= write_ptr + 1;
                    end
            end
        end
    end
    
	assign delay_in = audio_in + fb_path; 
    assign fb_mult = delay_out * $signed(feedback);
    assign fb_path = fb_mult >>> 15;
    
    assign dry_mult = audio_in * $signed(16'd32767 - dry_wet);
    assign wet_mult = delay_out * $signed(dry_wet);
    assign mix_sum = dry_mult + wet_mult;
	
	assign mixed_sample = mix_sum >>> 15;
	
    assign led = sw;
    
    assign p_bit_out = c_bit_out ^ v_bit_out ^ u_bit_out ^ (^audio_out);
    assign c_bit_out = c_bit_in;
    assign u_bit_out = u_bit_in;
    assign v_bit_out = v_bit_in;
    assign audio_out = (sw) ? mixed_sample: audio_in;
    assign preamble_out = preamble_in;
    
    assign m_axis_tid = s_axis_tid; 
    assign m_axis_tdata = {p_bit_out, c_bit_out, u_bit_out, v_bit_out, audio_out, preamble_out};
    assign m_axis_tvalid = s_axis_tvalid;
    assign s_axis_tready = m_axis_tready;
endmodule
