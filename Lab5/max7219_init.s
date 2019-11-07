.syntax unified
.cpu cortex-m4
.thumb

.text
    .global max7219_init
    
    // for GPIO_A init
    .equ RCC_AHB2ENR,   0x4002104C
    .equ GPIOA_MODER,   0x48000000
    .equ GPIOA_OTYPER,  0x48000004
    .equ GPIOA_OSPEEDR, 0x48000008
    .equ GPIOA_PUPDR,   0x4800000C
    .equ GPIOA_IDR,     0x48000010
    .equ GPIOA_ODR,     0x48000014
    .equ GPIOA_BSRR,    0x48000018
    .equ GPIOA_BRR,     0x48000028

    // for Max7219 register init
    .equ DECODE_MODE,   0x9
    .equ INTENSITY,     0xA
    .equ SCAN_LIMIT,    0xB
    .equ SHUTDOWN,      0xC
    .equ DISPLAY_TEST,  0xF 
    .equ DIN,           0x20 //PA5
    .equ CS,            0x40 //PA6
    .equ CLK,           0x80 //PA7
    
    .equ ONE, 400000

max7219_init:
    //TODO: Initial max7219 registers.

    PUSH    {R0, R1, LR}

    LDR     R0, =DECODE_MODE
    LDR     R1, =0xFF  // Code B (display number 0~9)
    BL      max7219_send
    
    LDR     R0, =DISPLAY_TEST
    LDR     R1, =0x0  // NO display test
    BL      max7219_send

    LDR     R0, =SCAN_LIMIT
    LDR     R1, =0x6   // display digit 0~6
    BL      max7219_send
    
    LDR     R0, =INTENSITY
    LDR     R1, =0xA   // brightness
    BL      max7219_send
    
    LDR     R0, =SHUTDOWN
    LDR     R1, =0x1  // NO shutdown
    BL      max7219_send

    POP     {R0, R1, LR}
    BX      LR