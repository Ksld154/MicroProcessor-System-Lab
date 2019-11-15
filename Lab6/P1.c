#include <stdio.h>
#include <stdlib.h>
#include "stm32l476xx.h"

void GPIO_init();
int  push_button();
void SystemClock_Config(int clock_speed_type);
void busy_waiting(int val);

int already_pressed_flag = 0;  // record the button is already pressed or not


int main(){
    int clock_state = 1;
    SystemClock_Config(clock_state);
    
    GPIO_init();
    GPIOC->BRR = 0b1;  // turn off the light first
    
    while (1){
        
        // make LED light
        GPIOC->BSRR = 0b1;

        // iterate EVERY 1/100 time unit
        for(int i = 1; i < 100; i++){
            
            // check whether the button is pressed EVERY 1/100 time unit
            int pressed = push_button();
            if(pressed && !already_pressed_flag){
                already_pressed_flag = 1;
                clock_state = clock_state==5 ? 1:clock_state+1;  // update clock cycle
                SystemClock_Config(clock_state);
            }

            busy_waiting(2000);  // wait 4/100s at 1MHz
        }

        // make LED dark
        GPIOC->BRR = 0b1;
        for(int i = 1; i < 100; i++){

            int pressed = push_button();
            if(pressed && !already_pressed_flag){
                already_pressed_flag = 1;
                clock_state = clock_state==5 ? 1:clock_state+1;
                SystemClock_Config(clock_state);
            }
            busy_waiting(2000);
        }
    }
    
    return 0;
}


void SystemClock_Config(int clock_speed_type){

    RCC->CFGR  = 0x00000000;                       // reset CFGR
    RCC->CR   &= 0xFEFFFFFF;                       // DISABLE PLL
    while((RCC->CR & RCC_CR_PLLRDY) == 1);         // busy waiting until PLL is disabled

    RCC->PLLCFGR  = RCC_PLLCFGR_PLLSRC_MSI;        // After PLL is disabled, SELECT MSI as PLL's clock source
    RCC->PLLCFGR |= RCC_PLLCFGR_PLLREN;            // ENABLE PLLCLK output

    /* Setup PLLN, PLLM, PLLR */
    int PLL_N = 1;
    int PLL_M = 1;
    int PLL_R = 1;
    if(clock_speed_type == 1){
        PLL_N = 1;
        PLL_M = 4;
        PLL_R = 1;
    }else if(clock_speed_type == 2){
        PLL_N = 6;
        PLL_M = 4;
        PLL_R = 1;
    }else if(clock_speed_type == 3){
        PLL_N = 10;
        PLL_M = 4;
        PLL_R = 1;
    }else if(clock_speed_type == 4){
        PLL_N = 16;
        PLL_M = 4;
        PLL_R = 1;
    }else if(clock_speed_type == 5){
        PLL_N = 40;
        PLL_M = 4;
        PLL_R = 1;
    }

    RCC->PLLCFGR |= PLL_N << 8;
    RCC->PLLCFGR |= PLL_M << 4;
    RCC->PLLCFGR |= PLL_R << 25;
    
    RCC->CR |= RCC_CR_PLLON;                 // ENABLE PLL as clock source
    while((RCC->CR & RCC_CR_PLLRDY) == 0);   // busy waiting until PLL is ready to be clock source(ENABLED)

    RCC->CFGR |= RCC_CFGR_SW_PLL;                                   // ENABLE PLL as System clock
    while ((RCC->CFGR & RCC_CFGR_SWS_PLL) != RCC_CFGR_SWS_PLL);     // busy waiting until PLL is ready to be System clock 
}


void GPIO_init(){
    
    // Enable AHB2 clock
	RCC->AHB2ENR = 0b00000000000000000000000000000111; // A, B, C

	// PC0  - output(LED)
	// PC13 - input (button)
	GPIOC->MODER =		0b11110011111111111111111111111101;
	GPIOC->OSPEEDR = 	0b00001000000000000000000000000010;
	GPIOC->PUPDR =		0b00000000000000000000000000000010; //PC0: pull-down => when pressed, IDR == 1
}


int push_button(){
    
    int is_pressed = 0;
    int debounce_cnt = 0;

    while(1){
    
        // is pressed(might in bouncing stage)
        // => do NOT RETURN
        if((GPIOC->IDR & (1<<13)) >> 13 == 0b0){
            debounce_cnt++;
        }

        // pressed enough long (for debouncing)
        // => The button REALLY being PRESSED
        // => return PRESSED
        if(debounce_cnt >= 500){
            debounce_cnt = 0;
            is_pressed = 1;    
            break;
        }
        
        // not pressed, or bounced back
        // => cleanup the counter, and return NOT PRESSED
        if ((GPIOC->IDR & (1<<13)) >> 13 == 0b1){
            debounce_cnt = 0;
            is_pressed = 0;
            already_pressed_flag = 0;
            break;
        }
    }
    
    return is_pressed;
}


// wait
void busy_waiting(int val){

    for(int i = val; i > 0; i--){};

    return;
}
