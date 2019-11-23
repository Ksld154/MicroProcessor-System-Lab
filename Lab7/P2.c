#include "stm32l476xx.h"

#define PAD_SIZE 4

int key_col = 0, key_row = 0;
int key_value[PAD_SIZE][PAD_SIZE] = {
    {1,  2,  3,  10},
    {4,  5,  6,  11},
    {7,  8,  9,  12},
    {15, 0, 14,  13}
};

void GPIO_init() {
    RCC->AHB2ENR &= ~RCC_AHB2ENR_GPIOAEN;
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;

    GPIOA->MODER &= ~GPIO_MODER_MODE5;
    GPIOA->MODER |= GPIO_MODER_MODE5_0;

    GPIOA->OSPEEDR &= ~GPIO_OSPEEDER_OSPEEDR5;
    GPIOA->OSPEEDR |= GPIO_OSPEEDER_OSPEEDR5_1;

    GPIOA->ODR |= GPIO_ODR_OD5;
};

void keypad_init(){
    RCC->AHB2ENR &= ~(RCC_AHB2ENR_GPIOBEN | RCC_AHB2ENR_GPIOCEN);
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN | RCC_AHB2ENR_GPIOCEN;
    // PB5-PB8: input mode
    // Set PB5-PB8 to 0b00 00 00 00 (input mode)
    GPIOB->MODER &= 0xFFFC03FF;
    GPIOA->MODER |= 0x0;

    // Set PB5-PB8 to 0b10 10 10 10 (pull-down)
    GPIOB->PUPDR &= 0xFFFC03FF;
    GPIOB->PUPDR |= 0x2A800;

    // Set PB5-PB8 to 0b10 10 10 10 (high speed)
    GPIOB->OSPEEDR &= 0xFFFC03FF;
    GPIOB->OSPEEDR |= 0x2A800;

    // PC5-PC8: output mode
    // Set PC5-PC8 to 0b01 01 01 01 (output mode)
    GPIOC->MODER &= 0xFFFC03FF;
    GPIOC->MODER |= 0x15400;

    // Set PC5-PC8 to 0b10 10 10 10 (high speed)
    GPIOC->OSPEEDR &= 0xFFFC03FF;
    GPIOC->OSPEEDR |= 0x2A800;
}

void Timer_init(){
    //​TODO​: Initialize timer
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM2EN;
    TIM2->CR1 &= ~(TIM_CR1_CEN);
    TIM2->PSC = 39999U;
    TIM2->ARR = 49U;
    TIM2->EGR = TIM_EGR_UG;
}

void Timer_start(){
    //​TODO​: start timer
    TIM2->CR1 |= TIM_CR1_CEN;
    TIM2->SR &= ~(TIM_SR_UIF);
}

void NVIC_config(){
    // EXTI9_5_IRQn = 23
    NVIC->IP[23] = 0x10;
    NVIC->ICPR[0] = 0x00800000;
    NVIC->ICER[0] = 0x00800000;
    NVIC->ISER[0] = 0x00800000;
}

void EXTI_config(){
    RCC->APB2ENR = 0x1;
    SYSCFG->EXTICR[1] = SYSCFG_EXTICR2_EXTI5_PB | SYSCFG_EXTICR2_EXTI6_PB | SYSCFG_EXTICR2_EXTI7_PB;
    SYSCFG->EXTICR[2] = SYSCFG_EXTICR3_EXTI8_PB;
    EXTI->IMR1 |= EXTI_IMR1_IM5 | EXTI_IMR1_IM6 | EXTI_IMR1_IM7 | EXTI_IMR1_IM8;
    EXTI->RTSR1 |= EXTI_RTSR1_RT5 | EXTI_RTSR1_RT6 | EXTI_RTSR1_RT7 | EXTI_RTSR1_RT8;
    EXTI->PR1 |= EXTI_PR1_PIF5 | EXTI_PR1_PIF6 | EXTI_PR1_PIF7 | EXTI_PR1_PIF8;
}

void EXTI9_5_IRQHandler(){
    NVIC->ICPR[0] = 0x00800000;
    EXTI->PR1 |= EXTI_PR1_PIF5 | EXTI_PR1_PIF6 | EXTI_PR1_PIF7 | EXTI_PR1_PIF8;
    for(key_row = 0; key_row < 4; key_row++){
        int row_output = ((GPIOB->IDR) >> (key_row+5)) & 0x1;
        if(row_output != 0 && key_value[key_row][key_col] != 0){
            Timer_start();
            int cnt = 0;
            while(cnt != key_value[key_row][key_col]*2){
                if(TIM2->SR & 0x01){
                    GPIOA->ODR = (GPIOA->ODR ^ GPIO_ODR_OD5);
                    TIM2->SR &= ~(TIM_SR_UIF);
                    cnt++;
                }
            }
            TIM2->CR1 &= ~(TIM_CR1_CEN);
            TIM2->SR &= ~(TIM_SR_UIF);
        }
    }
}

void keypad_scan(){
    // PC5-PC8: keypad input  X (col0-col3)
    // PB5-PB8: keypad output Y (row0-row3)
    while(1){
    	key_col = 0, key_row = 0;
        for(key_col = 0; key_col < 4; key_col++){
            // send 0b1 to target column pin(PC5-PC8)
            GPIOC->BRR = 0xF << 5;
            GPIOC->BSRR = (0x1 << (key_col+5));
        }
    }
}

int main() {
    Timer_init();
    NVIC_config();
    EXTI_config();
    GPIO_init();
    keypad_init();
    keypad_scan();
}
