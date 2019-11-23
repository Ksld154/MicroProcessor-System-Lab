#include <stdio.h>
#include <stdlib.h>
#include "stm32l476xx.h"

#define PAD_SIZE 4

int cntdown = 1;
uint32_t key_value[PAD_SIZE][PAD_SIZE] = {
    {1,  2,  3,  10},
    {4,  5,  6,  11},
    {7,  8,  9,  12},
    {15, 0, 14,  13}
};

void SystemClock_Config() {
    // Set System Clock
    // Reset Clock Configure Register
    RCC->CFGR   &= 0x00000000;
    // Enable HSI16 clock in Control Register
    RCC->CR     &= ~RCC_CR_HSION;
    while((RCC->CR & RCC_CR_HSIRDY) == 1);
    RCC->CR     |= RCC_CR_HSION;
    while((RCC->CR & RCC_CR_HSIRDY) == 0);
    // 16MHZ -> 1MHZ
    RCC->CFGR   |= RCC_CFGR_HPRE_DIV16;
    // Set SYSCLK to HSI16
    RCC->CFGR   |= RCC_CFGR_SW_HSI;
    while((RCC->CFGR & RCC_CFGR_SWS_HSI) != RCC_CFGR_SWS_HSI);
}

void keypad_init(){
    // using GPIO_A, GPIO_B, GPIO_C
    RCC->AHB2ENR = 0x7;
    // PB5-PB8: input mode
    // Set PB5-PB8 to 0b00 00 00 00 (input mode)
    GPIOB->MODER &= 0xFFFC033F;
    // Set PB3 to 0b10 (AF mode)
    GPIOB->MODER |= 0x80;
    // Set PB5-PB8 to 0b10 10 10 10 (pull-down)
    GPIOB->PUPDR &= 0xFFFC03FF;
    GPIOB->PUPDR |= 0x2A800;
    // Set PB5-PB8 to 0b10 10 10 10 (high speed)
    GPIOB->OSPEEDR &= 0xFFFC03FF;
    GPIOB->OSPEEDR |= 0x2A800;
    // PC5-PC8: output mode
    // Set PC13 to 0b00 (input mode)
    GPIOC->MODER &= 0xF3FC03FF;
    // Set PC5-PC8 to 0b01 01 01 01 (output mode)
    GPIOC->MODER |= 0x15400;
    // Set PC5-PC8 to 0b10 10 10 10 (high speed)
    GPIOC->OSPEEDR &= 0xFFFC03FF;
    GPIOC->OSPEEDR |= 0x2A800;
}

void GPIO_init_AF(){
    //TODO: Initial GPIO pin as alternate function for buzzer. You can choose to use C or assembly to finish this function.
    GPIOB->AFR[0] &= ~(GPIO_AFRL_AFSEL3);//AFR[0] LOW
    GPIOB->AFR[0] |= GPIO_AFRL_AFSEL3_0;//PB3
}

void Timer_init(){
    //TODO: Initialize timer
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM2EN | RCC_APB1ENR1_TIM3EN;
    TIM2->CR1 &= ~(TIM_CR1_CEN);
    TIM2->PSC = 10U;
    TIM2->ARR = 99U;
    TIM2->EGR = TIM_EGR_UG;
}

void PWM_channel_init(){
    //TODO: Initialize timer PWM channel
    TIM2->CR1 |= TIM_CR1_ARPE;
    //enable output compare
    TIM2->CCER |= TIM_CCER_CC2E;
    TIM2->CCMR1 &= ~(TIM_CCMR1_OC2M);
    TIM2->CCMR1 |= (TIM_CCMR1_OC2M_1 | TIM_CCMR1_OC2M_2);
    TIM2->CCR2 = 0;
}

void SysTick_Handler() {
    TIM2->CCR2 = 50;
    cntdown = 0;
}

char keypad_scan(){
    // PC5-PC8: keypad input  X (col0-col3)
    // PB5-PB8: keypad output Y (row0-row3)
    int key_row = 0;
    int key_col = 0;
    while(1){
        for(key_row = 0; key_row < 4; key_row++){
            for(key_col = 0; key_col < 4; key_col++){
                // send 0b1 to target column pin(PC5-PC8)
                GPIOC->BRR = 0xF << 5;
                GPIOC->BSRR = (0x1 << (key_col+5));

                // get keypad output value
                int row_output = ((GPIOB->IDR) >> (key_row+5)) & 0x1;    // last 4 bit represent PB5-PB8's input

                // current key is pressed
                if(row_output != 0){
                    if(key_value[key_row][key_col]){
                        SysTick->LOAD = key_value[key_row][key_col]*1000000U-1U;
                        SysTick->VAL = 0;
                        SysTick->CTRL |= 0x7;
                        while(cntdown);
                        SysTick->CTRL = 0;
                        SysTick->VAL = 0;
                    }
                    else{
                        TIM2->CCR2 = 50;
                    }
                    while(1){
                        if((GPIOC->IDR >> 13) ^ 0x1){
                            TIM2->CCR2 = 0;
                            cntdown = 1;
                            break;
                        }
                    }
                }
            }
        }
    }
}

int main(){
    SystemClock_Config();
    keypad_init();
    GPIO_init_AF();
    Timer_init();
    PWM_channel_init();
    TIM2->CR1 |= TIM_CR1_CEN;
    //TODO: Scan the keypad and use PWM to send the corresponding frequency square wave to buzzer.
    keypad_scan();
}
