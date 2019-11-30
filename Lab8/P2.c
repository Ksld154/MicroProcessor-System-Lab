#include <stdio.h>
#include <string.h>
#include "stm32l476xx.h"

double resistor = 0;

void GPIO_Init(void){
    // AHB2
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOCEN;
    // PA9, PA10
    GPIOA->MODER   &= 0b11111111110000111111111111111111;
    GPIOA->MODER   |= 0b00000000001010000000000000000000;
    GPIOA->OSPEEDR &= 0b11111111110000111111111111111111;
    GPIOA->OTYPER  &= 0b11111111111111111111100111111111;
    // AF7
    GPIOA->AFR[1] = (GPIOA->AFR[1] & 0xFFFFF00F) | 0x00000770;
    // PC13
    GPIOC->MODER   &= 0b11110011111111111111111111111111;
    GPIOC->OSPEEDR &= 0b11110011111111111111111111111111;
    GPIOC->OSPEEDR |= 0b00000100000000000000000000000000;
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
        char msg[100] = {};
        if((!(GPIOC->IDR >> 13)) & 0x1){
            sprintf(msg, "%f\r\n", resistor);
            UART_Transmit(msg, strlen(msg));
            while((!(GPIOC->IDR >> 13)) & 0x1);
        }
    }
    return 0;
}
