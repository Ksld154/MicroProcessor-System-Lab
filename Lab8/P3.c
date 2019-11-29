#include <stdio.h>
#include <string.h>
#include "stm32l476xx.h"

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

int main(void){
    GPIO_Init();
    USART1_Init();
    while(1){
        char cmd[150] = {};
        int i = 0;
        UART_Transmit(">", 1);
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
        if(i == 0){
            continue;
        }else if(!strcmp(cmd, "showid")){
            UART_Transmit("0516220\r\n", 9);
        }else if(!strcmp(cmd, "light")){
            // TO DO
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
