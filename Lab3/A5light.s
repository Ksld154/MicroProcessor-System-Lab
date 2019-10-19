.syntax unified
.cpu cortex-m4
.thumb

.text
.global main

.equ RCC_AHB2ENR,   0x4002104C
.equ GPIOA_MODER,   0x48000000
.equ GPIOA_OTYPER,  0x48000004
.equ GPIOA_OSPEEDR, 0x48000008
.equ GPIOA_PUPDR,   0x4800000C
.equ GPIOA_ODR,     0x48000014
.equ ONE_SECOND,    400000   

main:
    
    @ Turn on RCC_AHB2ENR
    MOVS R0, 0x1
    LDR  R1, =RCC_AHB2ENR
    STR  R0, [R1]


    MOVS R0, 0x0400         @ 0x0400 means MODE5 = 0b01 (output mode)
    LDR  R1, =GPIOA_MODER
    LDR  R2, [R1]
    AND  R2, #0xFFFFF3FF    @ mask MODE5 (set MODE5 to 0b00)
    ORRS R2, R2, R0         @ set MODE5 to 0b01(output mode)
    STR  R2, [R1]           @ write to IO register

    MOVS R0, 0x0800
    LDR  R1, =GPIOA_OSPEEDR
    STRH R0, [R1]             @ write 16-bit data to IO register

    LDR  R1, =GPIOA_ODR

    
L1: 

    @ turn on A5 LED
    LDR  R3, =ONE_SECOND
    MOVS R0, #(1<<5)
    STRH R0, [R1]
    BL Delay

    @ turn off A5 LED
    LDR  R3, =ONE_SECOND
    MOVS R0, 0x0
    STRH R0, [R1]
    BL Delay

    B L1

Delay:
    //TODO: Write a delay 1 sec function
    SUB     R3, R3, #1
    CMP     R3, 0
    BNE     Delay
    BX      LR   