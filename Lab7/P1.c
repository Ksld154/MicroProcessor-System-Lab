#include "stm32l476xx.h"

void GPIO_init() {
    RCC->AHB2ENR &= ~RCC_AHB2ENR_GPIOAEN;
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;

    GPIOA->MODER &= ~GPIO_MODER_MODE5;
    GPIOA->MODER |= GPIO_MODER_MODE5_0;

    GPIOA->OSPEEDR &= ~GPIO_OSPEEDER_OSPEEDR5;
    GPIOA->OSPEEDR |= GPIO_OSPEEDER_OSPEEDR5_1;
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

    // Set SysTick
    // Interrupt every 3000000 cycles (3 secs) (Counter will count down from 2999999 to 0, and then reload to 2999999)
    SysTick->LOAD   = 2999999;
    // Reset SysTick counter
    SysTick->VAL    = 0;
    // Set processor clock as clock source, assert exception when counting down to 0, and enable SysTick counter
    SysTick->CTRL   |= 0x7;
}

void SysTick_Handler() {
    // PA5 = ~PA5
    GPIOA->ODR      = (GPIOA->ODR ^ GPIO_ODR_OD5);
}

int main() {
    SystemClock_Config();
    GPIO_init();
    while (1);
}
