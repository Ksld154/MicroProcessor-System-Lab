#include <stdio.h>
#include <stdlib.h>
#include "stm32l476xx.h"

#define PAD_SIZE 4
#define PIN_START 5

extern void GPIO_init();
extern void max7219_init();
extern void max7219_send(unsigned char address, unsigned char data);

// PA5-PA7: 7-seg
// PB5-PB8: keypad input
// PC5-PC8: keypad output


//TODO: define your gpio pin
// #define X0
// #define X1
// #define X2
// #define X3
// #define Y0
// #define Y1
// #define Y2
// #define Y3
// unsigned int x_pin[4] = {X0, X1, X2, X3};
// unsigned int y_pin[4] = {Y0, Y1, Y2, Y3};

int key_value[PAD_SIZE][PAD_SIZE] = {
    {1,  2,  3,  10},
    {4,  5,  6,  11},
    {7,  8,  9,  12},
    {15, 0, 14,  13}
};



/* TODO: initial keypad gpio pin, X as output and Y as input */
void keypad_init(){
    // using GPIO_A, GPIO_B, GPIO_C
    RCC->AHB2ENR = 0x7;

    // PB5-PB8: input mode
    // Set PB5-PB8 to 0b00 00 00 00 (input mode)
    GPIOB->MODER = 0xFFFC03FF;

    // Set PB5-PB8 to 0b01 01 01 01 (pull-down)
    GPIOB->PUPDR = 0xFFFC03FF;
    GPIOB->PUPDR = GPIOB->PUPDR | 0x2A800;

    // Set PB5-PB8 to 0b10 10 10 10 (high speed)
    GPIOB->OSPEEDR = 0xFFF2A8FF;


    // PC5-PC8: output mode
    // Set PC5-PC8 to 0b01 01 01 01 (output mode)
    GPIOC->MODER = 0xFFFC03FF;
    GPIOC->MODER = GPIOC->MODER | 0x15400;

    // Set PC5-PC8 to 0b10 10 10 10 (high speed)
    GPIOC->OSPEEDR = 0xFFF2A8FF;
}


int display(int data, int num_digs){
    int i;

    if(num_digs > 8) return -1;

    for(i = 1; i <= num_digs; i++){
        max7219_send(i, data % 10);
        data /= 10;
    }
    return 0;
}

int display_nothing(){
    int i;

    for(i = 1; i <= 8; i++){
        max7219_send(i, 0xF);
    }
    return 0;
}

/* TODO: scan keypad value
    return:
    >=0: key pressedvalue
    -1: no keypress
*/
char keypad_scan(){
    // PC5-PC8: keypad input  X (col0-col3)
    // PB5-PB8: keypad output Y (row0-row3)

    int key_row = 0;
    int key_col = 0;
    int pressed_value = -1;

    while(1){
        for(key_row = 0; key_row < 4; key_row++){
            for(key_col = 0; key_col < 4; key_col++){

                // send 0b1 to target column pin(PC5-PC8)
                GPIOC->BRR = 0xF << 5;
                GPIOC->BSRR = (0x1 << (key_col+5));

                // get keypad output value
                int row_output = ((GPIOB->IDR) >> (key_row+5)) & 0x1;    // last 4 bit represent PB5-PB8's input

                // a key is pressed
                if(row_output != 0){
                    pressed_value = key_value[key_row][key_col];
                    if(pressed_value >= 10)
                        display(pressed_value, 2);
                    else
                        display(pressed_value, 1);
                }
                else{
                    GPIOC->BSRR = (0xF << 5);
                    int key_pressed = ((GPIOB->IDR) >> 5) & 0xF;
                    if(key_pressed == 0)
                        display_nothing();
                }
            }
        }
    }
}

int main(){
    GPIO_init();
    max7219_init();
    keypad_init();

    display_nothing();
    keypad_scan();

    return 0;
}
