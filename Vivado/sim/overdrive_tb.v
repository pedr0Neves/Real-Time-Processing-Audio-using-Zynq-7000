`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/03/2026 12:28:10 AM
// Design Name: 
// Module Name: overdrive_tb
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


module overdrive_tb;
    parameter ADDR_WIDTH = 16;
    parameter DATA_WIDTH = 24;
    parameter AXIS_WIDTH = 32;

    reg aclk;
    reg sw;
    wire led;
    
    reg [ADDR_WIDTH-1:0] drive;
    reg [DATA_WIDTH-1:0] threshold;
    reg [ADDR_WIDTH-1:0] tone;
    //reg [ADDR_WIDTH-1:0] volume;

    // Interface AXI-Stream
    reg [AXIS_WIDTH-1:0] s_axis_tdata;
    reg s_axis_tvalid;
    reg [2:0] s_axis_tid;
    wire s_axis_tready;

    wire [AXIS_WIDTH-1:0] m_axis_tdata;
    wire m_axis_tvalid;
    reg m_axis_tready;
    wire [2:0] m_axis_tid;
    
    wire signed [DATA_WIDTH-1:0] audio_in;
    wire signed [DATA_WIDTH-1:0] audio_out;

    // Instanciação do Módulo Overdrive
    overdrive #(
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
        .m_axis_tid(m_axis_tid),
        .m_axis_tready(m_axis_tready),
        .drive(drive),
        .threshold(threshold),
        .tone(tone),
        //.volume(volume),
        .sw(sw),
        .led(led)
    );

    // Geração do Relógio de 100MHz
    always #5 aclk = ~aclk;

    // ========================================================
    // LÓGICA DE GERAÇÃO DA ONDA SENOIDAL
    // ========================================================
    real PI = 3.14159265358979323846;
    real freq = 1000.0;     // Frequência do Som: 1 kHz
    real fs = 48000.0;      // Taxa de Amostragem: 48 kHz
    real amplitude = 8388607.0; // Volume Máximo em 24 bits (0x7FFFFF)
    real phase_step;
    real current_phase;
    integer sine_integer;
    
    // Extração para visualização no gráfico
    assign audio_in = s_axis_tdata[27:4];
    assign audio_out = m_axis_tdata[27:4];

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
            s_axis_tdata  = 32'd0;
            @(posedge aclk); 
        end
    endtask

    integer i;
    
    initial begin
        aclk = 0;
        sw = 0;
        s_axis_tdata = 0;
        s_axis_tvalid = 0;
        s_axis_tid = 0;
        m_axis_tready = 1;
        
        current_phase = 0.0;
        phase_step = (2.0 * PI * freq) / fs;
        
        drive = 16'd0;
        tone = 16'd0;
        //volume = 16'd0;
        threshold = 24'd0;
        
        $display("[TB] Efeito: Overdrive");
        $display("[TB] Iniciando teste...");
        #100;
        
        $display("[TB] Configurando effeito...");
        
        $display("[TB] Aplicando ganho: x15..");
        drive = 10;
        $display("[TB] Ganho OK!");
        
        $display("[TB] Aplicando tone: 50..");
        threshold = 24'h3FFFFF;
        $display("[TB] Tone OK!");
        
        $display("[TB] Aplicando volume: 575..");
        tone = 16000;
        $display("[TB] Volume OK!");
        
        $display("[TB] Enviando Onda Senoidal...");
        for (i = 0; i < 48; i = i + 1) begin
            sine_integer = $rtoi(amplitude * $sin(current_phase));
            send_audio_sample(sine_integer);
            current_phase = current_phase + phase_step;
        end
        
        $display("[TB] A ativar o OVERDRIVE...");
        sw = 1;
        
        $display("[TB] Enviando Onda Senoidal...");
        // Envia 144 amostras (3 ciclos completos) para observar a onda cortada
        for (i = 0; i < 144; i = i + 1) begin
            sine_integer = $rtoi(amplitude * $sin(current_phase));
            send_audio_sample(sine_integer);
            current_phase = current_phase + phase_step;
        end

        #100;
        $finish;
    end
endmodule
