`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/22/2026 04:08:55 PM
// Design Name: 
// Module Name: reverb
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


module reverb #(
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
    
    input wire [ADDR_WIDTH-1:0] pre_delay,
    input wire [ADDR_WIDTH-1:0] decay,  
    input wire [ADDR_WIDTH-1:0] dry_wet,
    
    input  wire sw,
    output wire led
);
    
    wire signed [DATA_WIDTH-1:0] fb_path_1;
    wire signed [DATA_WIDTH-1:0] fb_path_2;
    wire signed [DATA_WIDTH-1:0] fb_path_3;
    wire signed [DATA_WIDTH-1:0] fb_path_4;
    wire signed [DATA_WIDTH-1:0] delay_out_g_1;
    wire signed [DATA_WIDTH-1:0] audio_in_g_1;
    wire signed [DATA_WIDTH-1:0] delay_out_g_2;
    wire signed [DATA_WIDTH-1:0] audio_in_g_2;
    wire signed [DATA_WIDTH-1:0] mix_reverb;
    wire signed [DATA_WIDTH-1:0] mixed_sample;
    
    wire signed [39:0] fb_mult_1;
    wire signed [39:0] fb_mult_2;
    wire signed [39:0] fb_mult_3;
    wire signed [39:0] fb_mult_4;
    wire signed [39:0] delay_out_mult_1;
    wire signed [39:0] audio_in_mult_1;
    wire signed [39:0] delay_out_mult_2; 
    wire signed [39:0] audio_in_mult_2;
    wire signed [39:0] dry_mult;
    wire signed [39:0] wet_mult;
    wire signed [39:0] mix_sum;
    
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
    
    assign  c_bit_in = s_axis_tdata[30];
    assign  u_bit_in = s_axis_tdata[29];
    assign  v_bit_in = s_axis_tdata[28];
    assign  audio_in = s_axis_tdata[27:4];
    assign  preamble_in = s_axis_tdata[3:0];
    
    /*
    localparam ADDR_BUF1_WIDTH = 12;
    localparam ADDR_BUF2_WIDTH = 11;
    localparam ADDR_BUF3_WIDTH = 9;
    localparam DELAY_1 = 16'd1423;
    localparam DELAY_2 = 16'd1601;
    localparam DELAY_3 = 16'd1733;
    localparam DELAY_4 = 16'd1907;
    localparam DELAY_AP_1 = 16'd227;
    localparam DELAY_AP_2 = 16'd331;
    localparam GAIN = 16'd22936;
    */
    // Aumentamos o tamanho das memórias para suportar as novas distâncias
    localparam ADDR_BUF1_WIDTH = 13; // Pre-delay (até 8192 amostras)
    localparam ADDR_BUF2_WIDTH = 13; // Comb Filters (até 4096 amostras)
    localparam ADDR_BUF3_WIDTH = 10; // All-pass Filters (até 1024 amostras)
    /*
    // Novos números primos para simular uma sala enorme e evitar ecos "metálicos"
    localparam DELAY_1 = 16'd3607; // ~75 ms
    localparam DELAY_2 = 16'd4153; // ~86 ms
    localparam DELAY_3 = 16'd4783; // ~99 ms
    localparam DELAY_4 = 16'd5501; // ~114 ms
    */
    localparam DELAY_1 = 16'd3607; 
    localparam DELAY_2 = 16'd3881; 
    localparam DELAY_3 = 16'd4001; 
    localparam DELAY_4 = 16'd4093;
    
    // Filtros All-Pass para a difusão do som (mantém o reverb denso)
    localparam DELAY_AP_1 = 16'd439;
    localparam DELAY_AP_2 = 16'd211;
    localparam GAIN = 16'd22936;
    
    // Pre-delay
    (* ram_style = "block" *) 
    reg         [DATA_WIDTH-1:0] delay_buffer [0:2**ADDR_BUF1_WIDTH-1];
    reg         [ADDR_BUF1_WIDTH-1:0] write_ptr;
    wire        [ADDR_BUF1_WIDTH-1:0] read_ptr;
    wire signed [DATA_WIDTH-1:0] delay_in;
    reg  signed [DATA_WIDTH-1:0] delay_out;
    
    assign read_ptr = (write_ptr >= pre_delay) ? (write_ptr - pre_delay) : (2**ADDR_BUF1_WIDTH - pre_delay + write_ptr);
    always @(posedge aclk) begin 
        if (s_axis_tvalid && m_axis_tready) begin
            if (s_axis_tid == 3'd0) begin
                delay_buffer[write_ptr] <= delay_in;
                delay_out <= delay_buffer[read_ptr];
                
                if(write_ptr >= 2**ADDR_BUF1_WIDTH-1) begin
                    write_ptr <= 0;
                end else begin
                    write_ptr <= write_ptr + 1;
                end
            end
        end
    end
    
    assign delay_in = audio_in;
    
    // Com filter 1
    (* ram_style = "block" *) 
    reg         [DATA_WIDTH-1:0] delay_buffer_1 [0:2**ADDR_BUF2_WIDTH-1];
    reg         [ADDR_BUF2_WIDTH-1:0] write_ptr_1;
    wire        [ADDR_BUF2_WIDTH-1:0] read_ptr_1;
    wire signed [DATA_WIDTH-1:0] delay_in_1;
    reg  signed [DATA_WIDTH-1:0] delay_out_1;
    
    assign read_ptr_1 = (write_ptr_1 >= DELAY_1) ? (write_ptr_1 - DELAY_1) : (2**ADDR_BUF2_WIDTH - DELAY_1 + write_ptr_1);
    always @(posedge aclk) begin 
        if (s_axis_tvalid && m_axis_tready) begin
            if (s_axis_tid == 3'd0) begin
                delay_buffer_1[write_ptr_1] <= delay_in_1;
                delay_out_1 <= delay_buffer_1[read_ptr_1];
            
                if (write_ptr_1 >= 2**ADDR_BUF2_WIDTH - 1) begin
                    write_ptr_1 <= 0;
                end else begin
                    write_ptr_1 <= write_ptr_1 + 1;
                end
            end
        end
    end
    
    assign delay_in_1 = delay_out + fb_path_1;
    assign fb_mult_1 = delay_out_1 * $signed(decay);
    assign fb_path_1 = fb_mult_1 >>> 15;
    
    // Comn filter 2
    (* ram_style = "block" *) 
    reg         [DATA_WIDTH-1:0] delay_buffer_2 [0:2**ADDR_BUF2_WIDTH-1];
    reg         [ADDR_BUF2_WIDTH-1:0] write_ptr_2;
    wire        [ADDR_BUF2_WIDTH-1:0] read_ptr_2;
    wire signed [DATA_WIDTH-1:0] delay_in_2;
    reg  signed [DATA_WIDTH-1:0] delay_out_2;
    
    assign read_ptr_2 = (write_ptr_2 >= DELAY_2) ? (write_ptr_2 - DELAY_2) : (2**ADDR_BUF2_WIDTH - DELAY_2 + write_ptr_2);
    always @(posedge aclk) begin 
        if (s_axis_tvalid && m_axis_tready) begin
            if (s_axis_tid == 3'd0) begin
                delay_buffer_2[write_ptr_2] <= delay_in_2;
                delay_out_2 <= delay_buffer_2[read_ptr_2];
            
                if (write_ptr_2 >= 2**ADDR_BUF2_WIDTH - 1) begin
                    write_ptr_2 <= 0;
                end else begin
                    write_ptr_2 <= write_ptr_2 + 1;
                end
            end
        end
    end
    
    assign delay_in_2 = delay_out + fb_path_2;
    assign fb_mult_2 = delay_out_2 * $signed(decay);
    assign fb_path_2 = fb_mult_2 >>> 15;
    
    // Comb filter 3
    (* ram_style = "block" *) 
    reg         [DATA_WIDTH-1:0] delay_buffer_3 [0:2**ADDR_BUF2_WIDTH-1];
    reg         [ADDR_BUF2_WIDTH-1:0] write_ptr_3;
    wire        [ADDR_BUF2_WIDTH-1:0] read_ptr_3;
    wire signed [DATA_WIDTH-1:0] delay_in_3;
    reg  signed [DATA_WIDTH-1:0] delay_out_3;
    
    assign read_ptr_3 = (write_ptr_3 >= DELAY_3) ? (write_ptr_3 - DELAY_3) : (2**ADDR_BUF2_WIDTH - DELAY_3 + write_ptr_3);
    always @(posedge aclk) begin 
        if (s_axis_tvalid && m_axis_tready) begin
            if (s_axis_tid == 3'd0) begin
                delay_buffer_3[write_ptr_3] <= delay_in_3;
                delay_out_3 <= delay_buffer_3[read_ptr_3];
            
                if (write_ptr_3 >= 2**ADDR_BUF2_WIDTH - 1) begin
                    write_ptr_3 <= 0;
                end else begin
                    write_ptr_3 <= write_ptr_3 + 1;
                end
            end
        end
    end
    
    assign delay_in_3 = delay_out + fb_path_3;
    assign fb_mult_3 = delay_out_3 * $signed(decay);
    assign fb_path_3 = fb_mult_3 >>> 15;
    
    // Comb filter 4
    (* ram_style = "block" *) 
    reg         [DATA_WIDTH-1:0] delay_buffer_4 [0:2**ADDR_BUF2_WIDTH-1];
    reg         [ADDR_BUF2_WIDTH-1:0] write_ptr_4;
    wire        [ADDR_BUF2_WIDTH-1:0] read_ptr_4;
    wire signed [DATA_WIDTH-1:0] delay_in_4;
    reg  signed [DATA_WIDTH-1:0] delay_out_4;
    
    assign read_ptr_4 = (write_ptr_4 >= DELAY_4) ? (write_ptr_4 - DELAY_4) : (2**ADDR_BUF2_WIDTH - DELAY_4 + write_ptr_4);
    always @(posedge aclk) begin 
        if (s_axis_tvalid && m_axis_tready) begin
            if (s_axis_tid == 3'd0) begin
                delay_buffer_4[write_ptr_4] <= delay_in_4;
                delay_out_4 <= delay_buffer_4[read_ptr_4];
            
                if (write_ptr_4 >= 2**ADDR_BUF2_WIDTH - 1) begin
                    write_ptr_4 <= 0;
                end else begin
                    write_ptr_4 <= write_ptr_4 + 1;
                end
            end
        end
    end
    
    assign delay_in_4 = delay_out + fb_path_4;
    assign fb_mult_4 = delay_out_4 * $signed(decay);
    assign fb_path_4 = fb_mult_4 >>> 15;
    
    assign mix_reverb = (fb_path_1 >>> 1) + (fb_path_2 >>> 1) + (fb_path_3 >>> 1) + (fb_path_4 >>> 1);
    
    // primeiro filtro all pass
    (* ram_style = "distributed" *) 
    reg         [DATA_WIDTH-1:0] delay_buffer_ap_1 [0:2**ADDR_BUF3_WIDTH-1];
    reg         [ADDR_BUF3_WIDTH-1:0] write_ptr_ap_1;
    wire        [ADDR_BUF3_WIDTH-1:0] read_ptr_ap_1;
    wire signed [DATA_WIDTH-1:0] delay_in_ap_1;
    reg  signed [DATA_WIDTH-1:0] delay_out_ap_1;
    wire signed [DATA_WIDTH-1:0] audio_out_ap_1;
    
    assign read_ptr_ap_1 = (write_ptr_ap_1 >= DELAY_AP_1) ? (write_ptr_ap_1 - DELAY_AP_1) : (2**ADDR_BUF3_WIDTH - DELAY_AP_1 + write_ptr_ap_1);
    always @(posedge aclk) begin
        if (s_axis_tvalid && m_axis_tready) begin
            if (s_axis_tid == 3'd0) begin
                delay_buffer_ap_1[write_ptr_ap_1] <= delay_in_ap_1;
                delay_out_ap_1 <= delay_buffer_ap_1[read_ptr_ap_1];
                
                if (write_ptr_ap_1 >= 2**ADDR_BUF3_WIDTH - 1) begin
                    write_ptr_ap_1 <= 0;
                end else begin
                    write_ptr_ap_1 <= write_ptr_ap_1 + 1;
                end
            end
        end
    end
    
    assign delay_out_mult_1 = delay_out_ap_1 * $signed(GAIN);
    assign delay_out_g_1 = delay_out_mult_1 >>> 15;
    
    assign audio_in_mult_1  = mix_reverb * $signed(GAIN);
    assign audio_in_g_1  = audio_in_mult_1 >>> 15;
    
    assign delay_in_ap_1 = mix_reverb + delay_out_g_1;
    assign audio_out_ap_1 = delay_out_ap_1 - audio_in_g_1;
    
    // segundo filtro all pass
    (* ram_style = "distributed" *) 
    reg         [DATA_WIDTH-1:0] delay_buffer_ap_2 [0:2**ADDR_BUF3_WIDTH-1];
    reg         [ADDR_BUF3_WIDTH-1:0] write_ptr_ap_2;
    wire        [ADDR_BUF3_WIDTH-1:0] read_ptr_ap_2;
    wire signed [DATA_WIDTH-1:0] delay_in_ap_2;
    reg  signed [DATA_WIDTH-1:0] delay_out_ap_2;
    wire signed [DATA_WIDTH-1:0] audio_out_ap_2;
    
    assign read_ptr_ap_2 = (write_ptr_ap_2 >= DELAY_AP_2) ? (write_ptr_ap_2 - DELAY_AP_2) : (2**ADDR_BUF3_WIDTH - DELAY_AP_2 + write_ptr_ap_2);
    always @(posedge aclk) begin
        if (s_axis_tvalid && m_axis_tready) begin
            if (s_axis_tid == 3'd0) begin
                delay_buffer_ap_2[write_ptr_ap_2] <= delay_in_ap_2;
                delay_out_ap_2 <= delay_buffer_ap_2[read_ptr_ap_2];
                
                if (write_ptr_ap_2 >= 2**ADDR_BUF3_WIDTH - 1)
                    write_ptr_ap_2 <= 0;
                else
                    write_ptr_ap_2 <= write_ptr_ap_2 + 1;
            end
        end
    end
    
    assign delay_out_mult_2 = delay_out_ap_2 * $signed(GAIN);
    assign delay_out_g_2 = delay_out_mult_2 >>> 15;
    
    assign audio_in_mult_2  = audio_out_ap_1 * $signed(GAIN);
    assign audio_in_g_2  = audio_in_mult_2 >>> 15;
    
    assign delay_in_ap_2 = audio_out_ap_1 + delay_out_g_2;
    assign audio_out_ap_2 = delay_out_ap_2 - audio_in_g_2;
    
    assign dry_mult = audio_in * $signed(16'd32766 - dry_wet);
    assign wet_mult = audio_out_ap_2 * $signed(dry_wet);
    assign mix_sum = dry_mult + wet_mult;
    assign mixed_sample = mix_sum >>> 15;
    
    integer i;
    initial begin
        write_ptr = 0;
        delay_out = 0;
        
        write_ptr_1 = 0;
        delay_out_1 = 0;
        write_ptr_2 = 0;
        delay_out_2 = 0;
        write_ptr_3 = 0;
        delay_out_3 = 0;
        write_ptr_4 = 0;
        delay_out_4 = 0;
        
        write_ptr_ap_1 = 0;
        delay_out_ap_1 = 0;
        write_ptr_ap_2 = 0;
        delay_out_ap_2 = 0;
        
        for(i = 0; i < 2**ADDR_BUF1_WIDTH; i = i+1) begin
            delay_buffer[i] = 24'd0;
            if(i < 2**ADDR_BUF2_WIDTH) begin 
                delay_buffer_1[i] = 24'd0;
                delay_buffer_2[i] = 24'd0;
                delay_buffer_3[i] = 24'd0;
                delay_buffer_4[i] = 24'd0;
            end
            if(i < 2**ADDR_BUF3_WIDTH) begin
                delay_buffer_ap_1[i] = 24'd0;
                delay_buffer_ap_2[i] = 24'd0;
            end
        end
    end
    
    
    assign led = sw;
    
    assign p_bit_out = c_bit_out ^ v_bit_out ^ u_bit_out ^ (^audio_out);
    assign c_bit_out = c_bit_in;
    assign u_bit_out = u_bit_in;
    assign v_bit_out = v_bit_in;
    assign audio_out = (sw) ? mixed_sample : audio_in;
    assign preamble_out = preamble_in;
    
    
    assign m_axis_tid = s_axis_tid; 
    assign m_axis_tdata = {p_bit_out, c_bit_out, u_bit_out, v_bit_out, audio_out, preamble_out};
    assign m_axis_tvalid = s_axis_tvalid;
    assign s_axis_tready = m_axis_tready;
endmodule
