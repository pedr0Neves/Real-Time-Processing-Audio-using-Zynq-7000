`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/22/2026 02:01:13 AM
// Design Name: 
// Module Name: overdrive
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


module overdrive #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 24,
    parameter AXIS_WIDTH = 32
)(
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axis:m_axis" *)
    input wire  aclk,
    
    // slave AXI-Stream
    input wire  [AXIS_WIDTH-1:0] s_axis_tdata,
    input wire  s_axis_tvalid,
    input wire  [2:0] s_axis_tid,
    output wire s_axis_tready,
    
    // master AXI-Stream
    output wire [AXIS_WIDTH-1:0] m_axis_tdata,
    output wire m_axis_tvalid,
    output wire [2:0] m_axis_tid,
    input wire  m_axis_tready,
    
    input wire [ADDR_WIDTH-1:0] drive,
    input wire [DATA_WIDTH-1:0] threshold,
    input wire [ADDR_WIDTH-1:0] tone,   
    //input wire [ADDR_WIDTH-1:0] volume,
    
    input  wire sw,
    output wire led
);  
    wire signed [DATA_WIDTH-1:0] audio_in;
    wire    p_bit_in;
    wire    v_bit_in;
    wire    u_bit_in;
    wire    c_bit_in;
    wire    [3:0] preamble_in;
    wire    [DATA_WIDTH-1:0] audio_out;
    wire    p_bit_out;
    wire    v_bit_out;
    wire    u_bit_out;
    wire    c_bit_out;
    wire    [3:0] preamble_out;
    
    assign p_bit_in = s_axis_tdata[31];
    assign c_bit_in = s_axis_tdata[30];
    assign u_bit_in = s_axis_tdata[29];
    assign v_bit_in = s_axis_tdata[28];
    assign audio_in = s_axis_tdata[27:4];
    assign preamble_in = s_axis_tdata[3:0];
    
    wire signed [39:0] driven_audio = audio_in * $signed(drive);
    
    //localparam signed [DATA_WIDTH-1:0] THRESHOLD_POS = 24'h3FFFFF; 
    //localparam signed [DATA_WIDTH-1:0] THRESHOLD_NEG = 24'hC00000;
    wire signed [DATA_WIDTH-1:0] threshold_pos = $signed(threshold);
    wire signed [DATA_WIDTH-1:0] threshold_neg = -$signed(threshold);
    
    reg signed [DATA_WIDTH-1:0] clipped_audio;
    
    always @* begin
        if (driven_audio > threshold_pos) begin
            clipped_audio = threshold_pos;
        end
        else if (driven_audio < threshold_neg) begin
            clipped_audio = threshold_neg;
        end
        else begin
            clipped_audio = driven_audio[DATA_WIDTH-1:0];
        end
    end
    
    reg signed [DATA_WIDTH-1:0] tone_filter_reg = 0;
    
    wire signed [39:0] tone_mult = clipped_audio * $signed(tone) + tone_filter_reg * $signed(16'd32768 - tone);
    wire signed [DATA_WIDTH-1:0] tone_sum = tone_mult >>> 15;
    
    always @(posedge aclk) begin
        if (s_axis_tvalid && m_axis_tready) begin
            tone_filter_reg <= tone_sum;
        end
    end
    
    wire signed [DATA_WIDTH-1:0] final_audio = tone_filter_reg;
    
    assign led = sw;
    
    assign p_bit_out = c_bit_out ^ v_bit_out ^ u_bit_out ^ (^audio_out);
    assign c_bit_out = p_bit_in;
    assign u_bit_out = u_bit_in;
    assign v_bit_out = v_bit_in;
    assign audio_out = (sw) ? final_audio : audio_in;
    assign preamble_out = preamble_in;
    
    assign m_axis_tvalid = s_axis_tvalid;
    assign s_axis_tready = m_axis_tready;
    assign m_axis_tid = s_axis_tid;
    assign m_axis_tdata = {p_bit_out, c_bit_out, u_bit_out, v_bit_out, audio_out, preamble_out};
endmodule
