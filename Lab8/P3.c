#include <stdio.h>
#include <string.h>
#include "stm32l476xx.h"

double resistor = 0;
int counter = 0, enable = 0;

void GPIO_Init(void){
    // AHB2
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOCEN;
    // PA9, PA10
    GPIOA->MODER   &= 0b11111111110000111111001111111111;
    GPIOA->MODER   |= 0b00000000001010000000010000000000;
    GPIOA->OSPEEDR &= 0b11111111110000111111111111111111;
    GPIOA->OSPEEDR |= 0b00000000000000000000010000000000;
    GPIOA->OTYPER  &= 0b11111111111111111111100111111111;
    // AF7
    GPIOA->AFR[1] = (GPIOA->AFR[1] & 0xFFFFF00F) | 0x00000770;
}

void USART1_Init(void){
    // APB2
    RCC->APB2ENR |= RCC_APB2ENR_USART1EN;
    // Word length, Parity selection, Parity control enable, Transmitter enable, Receiver enable, Oversampling mode
    USART1->CR1  = (USART1->CR1 & ~(USART_CR1_M | USART_CR1_PS | USART_CR1_PCE | USART_CR1_TE | USART_CR1_RE | USART_CR1_OVER8)) | (USART_CR1_TE | USART_CR1_RE);
    // STOP bits, LIN mode enable, Clock enable
    USART1->CR2  = (USART1->CR2 & ~(USART_CR2_STOP | USART_CR2_LINEN | USART_CR2_CLKEN)) | (0x0);
    // RTS enable, CTS enable, One sample bit method enable, Smartcard mode enable, Half-duplex selection, IrDA mode enable
    USART1->CR3  = (USART1->CR3 & ~(USART_CR3_RTSE | USART_CR3_CTSE | USART_CR3_ONEBIT | USART_CR3_SCEN | USART_CR3_HDSEL | USART_CR3_IREN)) | (0x0);
    // USARTDIV
    USART1->BRR  = (USART1->BRR & 0xFFFF) | (4000000L/9600L);
    // USART enable
    USART1->CR1  |= USART_CR1_UE;
}

void ADC1_Init(){
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOCEN;
    RCC->AHB2ENR |= RCC_AHB2ENR_ADCEN;
    GPIOC->MODER |= 0b11; // analog mode
    GPIOC->ASCR |= 1; // connect analog switch to ADC input
    ADC1->CFGR &= ~ADC_CFGR_RES; // 12-bit resolution
    ADC1->CFGR &= ~ADC_CFGR_CONT; // disable continuous conversion
    ADC1->CFGR &= ~ADC_CFGR_ALIGN; // right align
    ADC123_COMMON->CCR &= ~ADC_CCR_DUAL; // independent mode
    ADC123_COMMON->CCR &= ~ADC_CCR_CKMODE; // clock mode: hclk / 1
    ADC123_COMMON->CCR |= ADC_CCR_CKMODE;
    ADC123_COMMON->CCR &= ~ADC_CCR_PRESC; // prescaler: div 1
    ADC123_COMMON->CCR &= ~ADC_CCR_MDMA; // disable dma
    ADC123_COMMON->CCR &= ~ADC_CCR_DELAY; // delay: 5 adc clk cycle
    ADC123_COMMON->CCR |= ADC_CCR_DELAY_3;
    ADC1->SQR1 &= ~(ADC_SQR1_SQ1 << 6); // channel: 1, rank: 1
    ADC1->SQR1 |= (1 << 6);
    ADC1->SMPR1 &= ~(ADC_SMPR1_SMP0 << 3); // adc clock cycle: 12.5
    ADC1->SMPR1 |= (2 << 3);
    ADC1->CR &= ~ADC_CR_DEEPPWD; // turn off power
    ADC1->CR |= ADC_CR_ADVREGEN; // enable adc voltage regulator
    for (int i = 0; i <= 1000; ++i); // wait for regulator start up
    ADC1->IER |= ADC_IER_EOCIE; // enable end of conversion interrupt
    NVIC_EnableIRQ(ADC1_2_IRQn);
    ADC1->CR |= ADC_CR_ADEN; // enable adc
    while (!(ADC1->ISR & ADC_ISR_ADRDY)); // wait for adc start up
    ADC1->CR |= ADC_CR_ADSTART;
}

void ADC1_2_IRQHandler(){
    while (!(ADC1->ISR & ADC_ISR_EOC)); // wait for conversion complete
    int convertdata = ADC1->DR;
    float voltage = (float) convertdata / 4096.0f * 3.3f;
    resistor = (3300.0f - 1000.0f * voltage) / voltage;
}

int UART_Transmit(char *arr, uint32_t size){
    int sent = 0;
    for(int i = 0; i < size; ++i){
        while(!(USART1->ISR & USART_ISR_TXE));
        USART1->TDR = (*arr & 0xFF);
        sent++;
        arr++;
    }
    while(!(USART1->ISR & USART_ISR_TC));
    return sent;
}

void SysTick_Handler(){
    ADC1->CR |= ADC_CR_ADSTART;
    if(enable == 1 && counter == 50){
        char msg[100] = {};
        sprintf(msg, "%f\r\n", resistor);
        UART_Transmit(msg, strlen(msg));
    }
    if(counter < 50) counter++;
    else counter = 0;
}

int recv_input(char *cmd, int quitflag){
    int i = 0;
    if(quitflag == 0){
        for(i = 0; i < 150; i++){
            while(!(USART1->ISR & USART_ISR_RXNE));
            cmd[i] = (USART1->RDR & 0x1FF);
            if(cmd[i] == '\n' || cmd[i] == '\r'){
                UART_Transmit("\r\n", 2);
                cmd[i] = '\0';
                break;
            }else if(cmd[i] == 127){
                if(i){
                    UART_Transmit(&cmd[i], 1);
                    cmd[i] = '\0';
                    i--;
                }
                i--;
            }else{
                UART_Transmit(&cmd[i], 1);
            }
        }
        return i;
    }else{
        while(!(USART1->ISR & USART_ISR_RXNE));
        cmd[0] = (USART1->RDR & 0x1FF);
        if(cmd[0] == 'q'){
            return 1;
        }else{
            return 0;
        }
    }
}

int main(void){
    SCB->CPACR |= (0xF << 20); // enable floating point process unit
    GPIO_Init();
    USART1_Init();
    ADC1_Init();
    SysTick->LOAD   = 39999;
    SysTick->VAL    = 0;
    SysTick->CTRL   |= 0x7;
    while(1){
        char cmd[150] = {};
        UART_Transmit(">", 1);
        int len = recv_input(&cmd, 0);
        if(len == 0){
            continue;
        }else if(!strcmp(cmd, "showid")){
            UART_Transmit("0516220\r\n", 9);
        }else if(!strcmp(cmd, "light")){
            char msg[100] = {}, cmd2[5] = {};
            sprintf(msg, "%f\r\n", resistor);
            UART_Transmit(msg, strlen(msg));
            counter = 0;
            enable = 1;
            while(1){
                int quit = recv_input(&cmd2, 1);
                if(quit){
                    enable = 0;
                    break;
                }
            }
        }else if(!strcmp(cmd, "led on")){
            GPIOA->ODR = 0b100000;
        }else if(!strcmp(cmd, "led off")){
            GPIOA->ODR = 0b000000;
        }else{
            UART_Transmit("Unknown command\r\n", 17);
        }
    }
    return 0;
}
