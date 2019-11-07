.syntax unified
.cpu cortex-m4
.thumb

.text
    .global GPIO_init
    
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

GPIO_init:
    //TODO: Initialize three GPIO pins as output for max7219 DIN, CS and CLK
    
    // use A5 ~ A7
    // Enable AHB clock for using GPIO bus
    PUSH    {R0, R1, LR}

    MOVS    R0, 0x1           // 0x1 means using GPIO_A 
    LDR     R1, =RCC_AHB2ENR
    STR     R0, [R1]
    
    MOVS    R0, 0x5400       // 0x5400 means MODE5~MODE7 = 0b01 (output mode)
    LDR     R1, =GPIOA_MODER
    LDR     R2, [R1]
    AND     R2, 0xFFFF03FF   // mask MODE5~MODE7 = 0b00 first
    ORRS    R2, R2, R0
    STR     R2, [R1]         // set MODE5~MODE7 to output mode, and write to IO memory

    MOVS    R0, 0xA800      
    LDR     R1, =GPIOA_OSPEEDR
    STRH    R0, [R1]         // high speed mode for OSPEED5~OSPEED7

    POP     {R0, R1, LR}
    BX LR