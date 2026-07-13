`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2026 02:00:47 AM
// Design Name: 
// Module Name: reverb_tb
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


module reverb_tb;
    // Parâmetros do barramento
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 24;
    parameter AXIS_WIDTH = 32;

    // Sinais de relógio e controlo
    reg aclk;
    reg sw;
    wire led;
    
    // Parametros de configuração
    reg [ADDR_WIDTH-1:0] decay;
    reg [ADDR_WIDTH-1:0] pre_delay;
    reg [ADDR_WIDTH-1:0] dry_wet;
    
    // Interface Escravo AXI-Stream (Entrada)
    reg [AXIS_WIDTH-1:0] s_axis_tdata;
    reg s_axis_tvalid;
    reg [2:0] s_axis_tid;
    wire s_axis_tready;

    // Interface Mestre AXI-Stream (Saída)
    wire [AXIS_WIDTH-1:0] m_axis_tdata;
    wire m_axis_tvalid;
    reg m_axis_tready;
    wire [2:0] m_axis_tid;
    
    // Sinais para visualização no gráfico (Waveform)
    wire signed [DATA_WIDTH-1:0] audio_in;
    wire signed [DATA_WIDTH-1:0] audio_out;

    assign audio_in = s_axis_tdata[27:4];
    assign audio_out = m_axis_tdata[27:4];

    // Instanciação do Módulo Reverb
    reverb #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .AXIS_WIDTH(AXIS_WIDTH)
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
        .decay(decay),
        .pre_delay(pre_delay),
        .dry_wet(dry_wet),
        .sw(sw),
        .led(led)
    );

    // Geração do Relógio (Período de 10ns = 100MHz)
    always #5 aclk = ~aclk;

    // ========================================================
    // TASK: Envio de Amostras de Áudio com Handshake Seguro
    // ========================================================
    task send_audio_sample;
        input [DATA_WIDTH-1:0] audio_data;
        begin
            @(posedge aclk);
            #1;
            s_axis_tdata  = {4'b0000, audio_data, 4'h0};
            s_axis_tvalid = 1'b1;
            s_axis_tid    = 3'd0;
            
            @(posedge aclk);
            while (!s_axis_tready) begin
                @(posedge aclk);
            end
            
            #1;
            s_axis_tvalid = 1'b0;
            
            @(posedge aclk);
        end
    endtask

    // ========================================================
    // ROTINA DE TESTE (STIMULUS)
    // ========================================================
    integer i;
    
    initial begin
        // 1. Condições Iniciais
        aclk = 0;
        sw = 0; // Inicia em Bypass
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tid = 0;
        m_axis_tready = 1; // O recetor final está sempre pronto
        decay = 16'd0;
        pre_delay = 16'd0;
        dry_wet = 16'd0;
        #100;
        
        $display("[TB] Configurando parametros...");
        decay = 16'd22936;
        pre_delay = 16'd2048;
        dry_wet = 16'd32766;
        
        // 2. Teste em Bypass
        $display("[TB] A testar BYPASS...");
        send_audio_sample(24'h333333);  
        #50;
        
        // 3. Ligar o Reverb
        $display("[TB] Ativando a chave do efeito (sw = 1)...");
        sw = 1'b1;
        #40;

        // Injeta um "Impulso" (um pico máximo de áudio assinalado)
        $display("[TB] Injetando um impulso de áudio...");
        send_audio_sample(24'h7FFFFF); // Pico máximo positivo assinalado
        send_audio_sample(24'h000000);
        send_audio_sample(24'h800000);
        send_audio_sample(24'h000000);
        #20;
        
        // Injeta amostras consecutivas de silêncio para monitorar as repetições do atraso
        $display("[TB] Monitorando as saídas e alimentação do Buffer de Eco...");
        repeat (15000) begin
            send_audio_sample(24'h000000);
        end
        
        $display("[TB] Simulação Concluída.");
        $finish;
    end
endmodule
