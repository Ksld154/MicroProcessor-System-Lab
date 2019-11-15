#include "stm32l476xx.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
// You can use your way to store TIME_SEC. Maybe it is `int` or `float` or any you want
#define TIME_SEC 12.70

extern void GPIO_init();
extern void max7219_init();
extern void max7219_send(unsigned char address, unsigned char data);

void Timer_init(TIM_TypeDef *timer){
    //​TODO​: Initialize timer
    RCC->APB1ENR1 |= RCC_APB1ENR1_TIM2EN;
    TIM2->CR1 &= ~(TIM_CR1_CEN);
    TIM2->PSC = 39999U;
    TIM2->ARR = 99U;
    TIM2->EGR = TIM_EGR_UG;
}

void Timer_start(TIM_TypeDef *timer){
    //​TODO​: start timer and show the time on the 7-SEG LED.
    TIM2->CR1 |= TIM_CR1_CEN;
    TIM2->SR &= ~(TIM_SR_UIF);
}

int display(int data, int num_digs){
    if(num_digs > 8) return -1;
    for(int i = 1; i <= num_digs; i++){
        if(i == 3)
            max7219_send(i, (data % 10) | 0x80);
        else
            max7219_send(i, data % 10);
        data /= 10;
    }
    return 0;
}

int numDigitsOfTime(uint32_t time){
    int digit_cnt = 0;
    while(time != 0){
        digit_cnt++;
        time /= 10;
    }
    if(digit_cnt < 3) return 3;
    else return digit_cnt;
}

int clear7seg(){
    for(int i = 1; i <= 8; i++){
        max7219_send(i, 0xF);
    }
    return 0;
}

int main(){
    GPIO_init();
    max7219_init();
    clear7seg();
    Timer_init(TIM2);
    Timer_start(TIM2);

    uint32_t time = 0;
    uint32_t millisec = 0;
    uint32_t sec = 0;

    while(1){
        //​TODO​: Polling the timer count and do lab requirements
        if(TIME_SEC < 0.01 || TIME_SEC > 10000.00){
            display(0, 3);
        }
        millisec = TIM2->CNT;
        time = sec * 100 + millisec;
        if(time == (TIME_SEC * 100)){
            display(time, numDigitsOfTime(time));
            while(1);
        }
        millisec = TIM2->CNT;
        time = sec * 100 + millisec;
        display(time, numDigitsOfTime(time));
        millisec = TIM2->CNT;
        time = sec * 100 + millisec;
        if(TIM2->SR & 0x01){
            sec++;
            TIM2->SR &= ~(TIM_SR_UIF);
        }
        millisec = TIM2->CNT;
        time = sec * 100 + millisec;
        display(time, numDigitsOfTime(time));
    }
    return 0;
}
