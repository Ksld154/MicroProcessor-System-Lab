.syntax unified
.cpu cortex-m4
.thumb

.data
    leds: .byte 0

.text
    .global main

    .equ RCC_AHB2ENR, 0x4002104C
    .equ GPIOA_MODER, 0x48000000
    .equ GPIOA_OTYPER, 0x48000004
    .equ GPIOA_OSPEEDR, 0x48000008
    .equ GPIOA_PUPDR, 0x4800000C
    .equ GPIOA_ODR, 0x48000014
    .equ ONE, 400000

main:
    BL      GPIO_init
    MOVS    R1, #1
    LDR     R0, =leds
    STRB    R1, [R0]
    BL      DisplayLED
    LDR     R3, =ONE
    BL      Delay
    B       Loop

Loop:
//TODO: Write the display pattern into leds variable
//R0 = Address of leds
//R8 = output
    GOLEFT:
        LDR     R1, [R0]
        LSL     R2, R1, #1
        CMP     R1, #1
        IT		EQ
        ADDEQ   R2, #1
        AND     R2, 0xF
        STRB    R2, [R0]
        BL      DisplayLED
        LDR     R3, =ONE
        BL      Delay

        CMP     R2, 0x8
        BNE     GOLEFT
    GORIGHT:
        LDR     R1, [R0]
        LSR     R2, R1, #1
        CMP     R1, #8
        IT		EQ
        ADDEQ   R2, #8
        AND     R2, 0xF
        STRB    R2, [R0]
        BL      DisplayLED
        LDR     R3, =ONE
        BL      Delay

        CMP     R2, 0x1
        BNE     GORIGHT

    B       Loop

GPIO_init:
//TODO: Initial LED GPIO pins as output
    MOVS    R0, 0x1
    LDR     R1, =RCC_AHB2ENR
    STR     R0, [R1]

    MOVS    R0, 0x15400
    LDR     R1, =GPIOA_MODER
    LDR     R2, [R1]
    AND     R2, 0xFFFC03FF
    ORRS    R2, R2, R0
    STR     R2, [R1]

    MOVS    R0, 0x2A800
    LDR     R1, =GPIOA_OSPEEDR
    STRH    R0, [R1]

    LDR     R8, =GPIOA_ODR

    BX      LR

DisplayLED:
//TODO: Display LED by leds
    LDR     R7, [R0]
    LSL     R7, #5
    MVN     R7, R7
    STRH    R7, [R8]
    BX      LR

Delay:
//TODO: Write a delay 1 sec function
    SUB     R3, R3, #1
    CMP     R3, 0
    BNE     Delay
    BX      LR
