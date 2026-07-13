#include "xparameters.h"
#include "xiicps.h"
#include "xi2srx.h"
#include "xi2stx.h"
#include "xuartps.h"
#include "xil_printf.h"
#include "sleep.h"
#include <xstatus.h>
#include <xuartps_hw.h>
#include "stdio.h"

#define SSM2603_ADDR            0x1A
#define GPIO_CH1_DATA_REG       0x00
#define GPIO_CH2_DATA_REG       0x08

typedef enum {
    EFFECT_REVERB,
    EFFECT_ECHO,
    EFFECT_OVERDRIVE
} EffectID;

typedef enum {
    PARAM_1, // Mapeado para o Bloco A - Canal 1
    PARAM_2, // Mapeado para o Bloco A - Canal 2
    PARAM_3  // Mapeado para o Bloco B - Canal 1
} ParamID;

XIicPs iicInstance;
XI2s_Rx i2sRxInstance;
XI2s_Tx i2sTxInstance;

char read_uart() {
    char c;
    while(!XUartPs_IsReceiveData(XPAR_UART1_BASEADDR));
    c = XUartPs_ReadReg(XPAR_UART1_BASEADDR, XUARTPS_FIFO_OFFSET);
    //xil_printf("%c\n", c); 
    return c;
}

u32 read_uart_number() {
    u32 result = 0;
    char c;

    while(1) {
        while(!XUartPs_IsReceiveData(XPAR_UART1_BASEADDR));
        c = XUartPs_ReadReg(XPAR_UART1_BASEADDR, XUARTPS_FIFO_OFFSET);

        if (c == '\r' || c == '\n') {
            xil_printf("%c", c);
            break;
        }

        if (c >= '0' && c <= '9') {
            //xil_printf("%c", c); // Mostra o número na tela
            result = (result * 10) + (c - '0');
        }
    }

    return result;
}

int initIIC() {
    int stt;
    XIicPs_Config *iicConfig;
    xil_printf("[I2C] Iniciando processo...\n");

    iicConfig = XIicPs_LookupConfig(XPAR_XIICPS_0_BASEADDR);
    if(iicConfig == NULL) return XST_FAILURE;

    stt = XIicPs_CfgInitialize(&iicInstance, iicConfig, iicConfig->BaseAddress);
    if(stt == XST_FAILURE) return stt;

    stt = XIicPs_SelfTest(&iicInstance);
    if(stt == XST_FAILURE) return stt;

    stt = XIicPs_SetSClk(&iicInstance, 100000);
    if(stt == XST_FAILURE) return stt;

    xil_printf("[I2C] Online\n");
    return XST_SUCCESS;
}

int initI2Srx() {
    int stt;
    XI2srx_Config *i2sRxConfig;
    xil_printf("[I2S Rx] Iniciando processo...\n");

    i2sRxConfig = XI2s_Rx_LookupConfig(XPAR_XI2SRX_0_BASEADDR);
    if(i2sRxConfig == NULL) return XST_FAILURE;

    stt = XI2s_Rx_CfgInitialize(&i2sRxInstance, i2sRxConfig, i2sRxConfig->BaseAddress);
    if(stt == XST_FAILURE) return stt;

    stt = XI2s_Rx_SelfTest(&i2sRxInstance);
    if(stt == XST_FAILURE) return stt;

    XI2s_Rx_SetSclkOutDiv(&i2sRxInstance, 12288000, 48000);

    XI2s_Rx_Enable(&i2sRxInstance, 0x01);

    xil_printf("[I2S Rx] Online\n");
    return XST_SUCCESS;
}

int initI2Stx() {
    int stt;
    XI2stx_Config *i2sTxConfig;
    xil_printf("[I2S Tx] Iniciando processo...\n");

    i2sTxConfig = XI2s_Tx_LookupConfig(XPAR_XI2STX_0_BASEADDR);
    if(i2sTxConfig == NULL) return XST_FAILURE;

    stt = XI2s_Tx_CfgInitialize(&i2sTxInstance, i2sTxConfig, i2sTxConfig->BaseAddress);
    if(stt == XST_FAILURE) return stt;

    stt = XI2s_Tx_SelfTest(&i2sTxInstance);
    if(stt == XST_FAILURE) return stt;

    XI2s_Tx_Enable(&i2sTxInstance, 0x01);

    xil_printf("[I2S Tx] Online\n");
    return XST_SUCCESS;
}

int writeSSM2603(u8 regAddr, u16 regData) {
    int stt;
    u8 Buffer[2];

    //xil_printf("configurando - Adrr:%02X | Data: %04X...\n", regAddr, regData);

    Buffer[0] = (regAddr << 1 | ((regData >> 8) & 0x01));
    Buffer[1] = regData & 0xFF;

    stt = XIicPs_MasterSendPolled(&iicInstance, Buffer, 2, SSM2603_ADDR);
    if(stt == XST_FAILURE) return stt;

    while (XIicPs_BusIsBusy(&iicInstance));

    //xil_printf("sucesso!\n");

    return XST_SUCCESS;
}

int configSSM2603() {
    int stt;
    xil_printf("[SSM2603] Iniciando processo...\n");
    
    // 1.
    stt = writeSSM2603(0x06, 0x0010); if(stt == XST_FAILURE) return stt;

    // 2.
    stt = writeSSM2603(0x00, 0x0017); if(stt == XST_FAILURE) return stt;
    stt = writeSSM2603(0x01, 0x0017); if(stt == XST_FAILURE) return stt;
    stt = writeSSM2603(0x02, 0x0079); if(stt == XST_FAILURE) return stt;
    stt = writeSSM2603(0x03, 0x0079); if(stt == XST_FAILURE) return stt;
    stt = writeSSM2603(0x04, 0x000A); if(stt == XST_FAILURE) return stt;
    stt = writeSSM2603(0x05, 0x0000); if(stt == XST_FAILURE) return stt;
    stt = writeSSM2603(0x07, 0x000A); if(stt == XST_FAILURE) return stt;

    // 3.
    sleep(1);

    // 4.
    stt = writeSSM2603(0x09, 0x0001); if(stt == XST_FAILURE) return stt;

    // 5.
    stt = writeSSM2603(0x06, 0x0000); if(stt == XST_FAILURE) return stt;

    xil_printf("[SSM2603] Online\n");
    return XST_SUCCESS;
}

void set_effect(EffectID effect, ParamID param, u32 value) {
    u32 base_addr_a = 0;
    u32 base_addr_b = 0;

    switch (effect) {
        case EFFECT_ECHO:
            base_addr_a = XPAR_AXI_GPIO_0_BASEADDR;
            base_addr_b = XPAR_AXI_GPIO_1_BASEADDR;
            break;
        case EFFECT_REVERB:
            base_addr_a = XPAR_AXI_GPIO_2_BASEADDR;
            base_addr_b = XPAR_AXI_GPIO_3_BASEADDR;
            break;
        case EFFECT_OVERDRIVE:
            base_addr_a = XPAR_AXI_GPIO_4_BASEADDR;
            base_addr_b = XPAR_AXI_GPIO_5_BASEADDR;
            break;
    }

    switch (param) {
        case PARAM_1:
            // Bloco A - Canal 1
            Xil_Out32(base_addr_a + GPIO_CH1_DATA_REG, value);
            break;
        case PARAM_2:
            // Bloco A - Canal 2
            Xil_Out32(base_addr_a + GPIO_CH2_DATA_REG, value);
            break;
        case PARAM_3:
            // Bloco B - Canal 1
            Xil_Out32(base_addr_b + GPIO_CH1_DATA_REG, value);
            break;
    }
}

void config_effect() {
    EffectID effect;
    //ParamID param;
    u32 value;
    char aux;

    xil_printf("Qual efeito voce quer modificar?\n");
    xil_printf(" 1 - Echo\n");
    xil_printf(" 2 - Reverb\n");
    xil_printf(" 3 - Overdrive\n");
    xil_printf("Sua escolha: ");

    aux = read_uart();
    switch(aux) {
        case '1': effect = EFFECT_ECHO; break;
        case '2': effect = EFFECT_REVERB; break;
        case '3': effect = EFFECT_OVERDRIVE; break;
        default: 
            xil_printf("[ERRO] Opcao invalida. Cancelando...\n"); 
            return;
    }

    if(effect == EFFECT_ECHO) {
        xil_printf(" delay | feedback | dry\n");
        xil_printf("\n[ Delay ] Digite o novo valor: ");
        value = read_uart_number();
        set_effect(effect, 0, value);
        xil_printf("\n[ Feedback ] Digite o novo valor: ");
        value = read_uart_number();
        set_effect(effect, 1, value);
        xil_printf("\n[ Dry ] Digite o novo valor: ");
        value = read_uart_number();
        set_effect(effect, 2, value);
    }

    if(effect == EFFECT_REVERB) {
        xil_printf(" pre_delay | decay | dry\n");
        xil_printf("\n[ Pre Delay ] Digite o novo valor: ");
        value = read_uart_number();
        set_effect(effect, 0, value);
        xil_printf("\n[ Decay ] Digite o novo valor: ");
        value = read_uart_number();
        set_effect(effect, 1, value);
        xil_printf("\n[ Dry ] Digite o novo valor: ");
        value = read_uart_number();
        set_effect(effect, 2, value);
    }

    if(effect == EFFECT_OVERDRIVE) {
        xil_printf(" drive | threshold | tone\n");
        xil_printf("\n[ Drive ] Digite o novo valor: ");
        value = read_uart_number();
        set_effect(effect, 0, value);
        xil_printf("\n[ Threshold ] Digite o novo valor: ");
        value = read_uart_number();
        set_effect(effect, 1, value);
        xil_printf("\n[ Tone ] Digite o novo valor: ");
        value = read_uart_number();
        set_effect(effect, 2, value);
    }

    //xil_printf("[SUCESSO] Valor %d aplicado ao hardware!\n", value);
}

void initEffects() {
    // atraso
    set_effect(EFFECT_ECHO, 0, 32000);
    set_effect(EFFECT_ECHO, 1, 16000);
    set_effect(EFFECT_ECHO, 2, 16000);

    // distorção
    set_effect(EFFECT_REVERB, 0, 8000);
    set_effect(EFFECT_REVERB, 1, 16000);
    set_effect(EFFECT_REVERB, 2, 16000);

    // reverb
    set_effect(EFFECT_OVERDRIVE, 0, 10);
    set_effect(EFFECT_OVERDRIVE, 1, 4194303);
    set_effect(EFFECT_OVERDRIVE, 2, 16000);
}

void inputVolumeControl() {
    u32 val;
    xil_printf("\nVolume in (hex): ");
    scanf("%x", &val);
    writeSSM2603(0x00, (u16)val);
    writeSSM2603(0x01, (u16)val);
    xil_printf("\nVolume atualizado!\n");
}

void outputVolumeControl() {
    u32 val;
    xil_printf("\nVolume out (hex): ");
    scanf("%x", &val);
    writeSSM2603(0x02, (u16)val);
    writeSSM2603(0x03, (u16)val);
    xil_printf("\nVolume atualizado!\n");
}

void bypassMode() {
    xil_printf("\nEntrando bypass mode...\n");

    writeSSM2603(0x00, 0x0017);
    writeSSM2603(0x01, 0x0017);
    writeSSM2603(0x04, 0x000A);
}

void LineInMode() {
    xil_printf("\nEntrando modo line in...\n");

    writeSSM2603(0x00, 0x017);
    writeSSM2603(0x01, 0x017);
    writeSSM2603(0x04, 0x0012);
}

void MicrofoneMode() {
    xil_printf("\nEntrando modo microfone...\n");

    writeSSM2603(0x00, 0x0127);
    writeSSM2603(0x01, 0x0127);
    writeSSM2603(0x04, 0x0015);
}

int main() {
    xil_printf("[sys] Inicializando o sistema...\n");
    if(initIIC() != XST_SUCCESS) {xil_printf("ERROR: I2C falhou\n"); return -1;}
    if(configSSM2603() != XST_SUCCESS) {xil_printf("ERROR: SSM2603 falhou\n"); return -1;}
    if(initI2Srx() != XST_SUCCESS) {xil_printf("ERROR: I2S Receiver falhou\n"); return -1;}
    if(initI2Stx() != XST_SUCCESS) {xil_printf("ERROR: I2C Transmiter falhou\n"); return -1;}

    initEffects();
    xil_printf("[sys] Modo bypass ativado...\n");
    xil_printf("[sys] Master: I2SRx...");
    xil_printf("[sys] Slaves: SSM2603, I2STx...\n");
    xil_printf("[sys] Configurado!\n");

    xil_printf("[sys] Bem vindo!\n");
    xil_printf("aperte I para alterar volume de entrada\n");
    xil_printf("aperte O para alterar volume de saída\n");
    xil_printf("aperte B para entrar em modo bypass\n");
    xil_printf("aperte L para entrar no modo line in\n");
    xil_printf("aperte M para entrar no modo microfone\n");
    xil_printf("aperte E para alterar os efeitos\n");

    while (1) {
        if(XUartPs_IsReceiveData(XPAR_UART1_BASEADDR)) {
            char input = inbyte();
            if(input == 'i') {
                inputVolumeControl();
            } else if(input == 'o') {
                outputVolumeControl();
            } else if(input == 'b') {
                bypassMode();
            } else if(input == 'l') {
                LineInMode();
            } else if(input == 'm') {
                MicrofoneMode();
            } else if(input == 'e') {
                config_effect();
            } else {
                xil_printf("\n");
            }
        }
    }

    return 0;
}