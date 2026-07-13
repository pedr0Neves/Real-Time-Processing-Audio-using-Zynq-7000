`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/02/2026 11:49:23 AM
// Design Name: 
// Module Name: echo_tb
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

module echo_tb;
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 24;
    parameter AXIS_WIDTH = 32;
    parameter MAX_SAMPLES = 100;
    
    reg aclk;

    // Interface Slave AXI-Stream (Entrada)
    reg [AXIS_WIDTH-1:0] s_axis_tdata;
    reg s_axis_tvalid;
    reg [2:0] s_axis_tid;
    wire s_axis_tready;

    // Interface Master AXI-Stream (Saída)
    wire [AXIS_WIDTH-1:0] m_axis_tdata;
    wire m_axis_tvalid;
    reg m_axis_tready;
    wire [2:0] m_axis_tid;

    reg sw;
    wire led;
    
    reg [ADDR_WIDTH-1:0] delay_time;
    reg [ADDR_WIDTH-1:0] feedback;
    reg [ADDR_WIDTH-1:0] dry_wet;
   
    wire [DATA_WIDTH-1:0] audio_in;
    wire [DATA_WIDTH-1:0] audio_out;

    echo #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .AXIS_WIDTH(AXIS_WIDTH),
        .MAX_SAMPLES(MAX_SAMPLES)
    ) uut (
        .aclk(aclk),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tid(s_axis_tid),
        .s_axis_tready(s_axis_tready),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tid(m_axis_tid),
        .delay_time(delay_time),
        .feedback(feedback),
        .dry_wet(dry_wet),
        .sw(sw),
        .led(led)
    );
    assign audio_in = s_axis_tdata[27:4];
    assign audio_out = m_axis_tdata[27:4];

    always #5 aclk = ~aclk;

    task send_audio_sample;
        input [DATA_WIDTH-1:0] audio_data;
        input [2:0] channel_id;
        begin
            @(posedge aclk);
            #1;
            s_axis_tdata  = {4'b0000, audio_data, 4'b0000};
            s_axis_tvalid = 1'b1;
            s_axis_tid    = channel_id;
            
            @(posedge aclk);
            while (!s_axis_tready) begin
                @(posedge aclk);
            end
            #1;
            s_axis_tvalid = 1'b0;
        end
    endtask

    initial begin
        aclk = 1'b0;
        s_axis_tdata = 32'd0;
        s_axis_tvalid = 1'b0;
        s_axis_tid = 3'd0;
        m_axis_tready = 1'b1;
        
        sw = 1'b0;
        delay_time = 16'd0;
        feedback = 16'd0;
        dry_wet = 16'd0;

        $display("[TB] Efeito: Echo");
        $display("[TB] Iniciando teste...");
        #100;
        
        $display("[TB] Configurando effeito...");
        
        $display("[TB] Aplicando delay: 1s..");
        delay_time = 100;
        $display("[TB] Delay OK!");
        
        $display("[TB] Aplicando feedback: 100..");
        feedback = 16'd16383;
        $display("[TB] Feedback OK!");
        
        $display("[TB] Aplicando dry-wet: 50..");
        dry_wet = 16'd16383;
        $display("[TB] Dry-wet OK!");
        
        $display("[TB] Ativando a efeito...");
        #20;
        sw = 1'b1;
        #20;
        
        $display("[TB] Injetando um impulso de áudio...");
        send_audio_sample(24'h000000, 3'd0);
        send_audio_sample(24'h7FFFFF, 3'd0);
        send_audio_sample(24'h000000, 3'd0);
        send_audio_sample(24'h800000, 3'd0);
        send_audio_sample(24'h000000, 3'd0);
        
        $display("[TB] Monitorando as saídas e alimentação do Buffer de Eco...");
        repeat (500) begin send_audio_sample(24'h000000, 3'd0); end

        $display("[TB] Simulação finalizada com sucesso!");
        $finish;
    end
endmodule
