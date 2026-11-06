# Processamento de Áudio em Tempo Real

## Sumário
- [Visão Geral](#visão-geral)
- [Funcionalidades](#funcionalidades)
- [Tecnologias](#tecnologias)
  -  [HDL|Linguagem](#hdl|linguagem)
  -  [Software](#software)
  -  [Hardware](#hardware)
- [Instalação](#instalação)
- [Utilização](#utilização)

## Visão Geral

Esse projeto tem como proposta desenvolver um sistema de processamento de áudio em tempo real utilizando FPGA. Com objetivo de explorar uma forma eficiente de processamento de sinais diretamente em Hardware, buscando baixa latência e eficiencia energetica. 

Foi desenvolvido um sistema utilizando a placa de desenvolvimento Zybo, baseada no SoC Zynq-7000, a qual integra um ARM Cortex-A9 Dual Core em conjunto com FPGA da família Artix-7. No total foram desenvolvidos três módulos de processamento em RTL: Atraso(Delay), Reverberação(Reverb) e Saturação(Overdrive).

O projeto foi desenvolvido utilizando as ferramentas AMD Vivado Design Suite e AMD Vitis. O Vivado foi utilizado para descrição e integração do hardware, simulação, síntese e implementação do circuito digital. Já o Vitis foi utilizado para o desenvolvimento da aplicação embarcada responsável pelo controle do sistema.

## Funcionalidades
-  Aquisição e reprodução de áudio por meio do codec SSM2603.
-  Comunicação digital de áudio utilizando o protocolo I2S.
-  Integração de múltiplos módulos RTL em uma única arquitetura de hardware.
-  Configuração e controle dos efeitos por meio de BareMetal embarcado em C.
-  Ativação e desativação independente dos efeitos por meio das chaves físicas da placa.

## Tecnologias

### HDL|Linguagem
-  Verilog
-  C

### Software
-  AMD Vivado Design Suite
-  XSim (Vivado Simulator)
-  AMD Vitis
-  GNU Octave

### Hardware
-  **Placa:** Diligent Zybo
-  **SoC:** Xilinx Zynq-7000
-  **Codec de áudio:** SSM2603

## Instalação


## Utilização
