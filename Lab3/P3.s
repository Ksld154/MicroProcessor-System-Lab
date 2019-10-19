.syntax unified
.cpu cortex-m4
.thumb

.data
    leds: .byte 0b0000
    password: .byte 0b1111

.text
    .global main
    //For LED
    .equ RCC_AHB2ENR, 0x4002104C
    .equ GPIOA_MODER, 0x48000000
    .equ GPIOA_OTYPER, 0x48000004
    .equ GPIOA_OSPEEDR, 0x48000008
    .equ GPIOA_PUPDR, 0x4800000C
    .equ GPIOA_ODR, 0x48000014
    .equ ONE, 140000
    //For button
    .equ GPIOC_MODER  , 0x48000800
    .equ GPIOC_OTYPER ,	0x48000804
    .equ GPIOC_OSPEEDR,	0x48000808
    .equ GPIOC_PUPDR  ,	0x4800080c
    .equ GPIOC_IDR    , 0x48000810

main:
    BL      GPIO_init
    LDR     R0, =leds
    BL      DisplayLED
    B       CHECKPRESS

CHECKPRESS:
    LDR     R4, [R9]
    LSR     R4, R4, #13
    AND     R4, R4, 0x1

    CMP     R4, #0  //Pressed => 0 (because of pull-up input)
    IT      EQ
    ADDEQ   R5, #1

    CMP     R4, #1
    IT      EQ
    MOVEQ   R5, #0

    CMP     R5, #500
    BNE     CHECKPRESS

    B       CHECKPWD

BLINKTHRICE:
    BL      BLINK
    BL      BLINK
    BL      BLINK
    B       CHECKPRESS

BLINKONCE:
    BL      BLINK
    B       CHECKPRESS

BLINK:
    MOV     R4, LR
    MOVS    R1, 0xF
    STRB    R1, [R0]
    BL      DisplayLED
    LDR     R3, =ONE
    BL      Delay
    MOVS    R1, 0x0
    STRB    R1, [R0]
    BL      DisplayLED
    LDR     R3, =ONE
    BL      Delay
    MOV     LR, R4

    BX      LR

CHECKPWD:
    LDR     R1, =password
    LDR     R2, [R1]
    LDR     R3, [R9]
    MVN     R3, R3
    LSR     R3, R3, #5
    AND     R3, R3, 0xF

    CMP     R2, R3
    BEQ     BLINKTHRICE
    CMP     R2, R3
    BNE     BLINKONCE

GPIO_init:
//TODO: Initial LED GPIO pins as output
    MOVS    R0, 0x5
    LDR     R1, =RCC_AHB2ENR
    STR     R0, [R1]

    //GPIOA
    MOVS    R0, 0x15400
    LDR     R1, =GPIOA_MODER
    LDR     R2, [R1]
    AND     R2, 0xFFFC03FF
    ORRS    R2, R2, R0
    STR     R2, [R1]

    MOVS    R0, 0x2A800
    LDR     R1, =GPIOA_OSPEEDR
    STRH    R0, [R1]

    //GPIOC
    LDR     R1, =GPIOC_MODER
    LDR     R2, [R1]
    AND     R2, 0xFFFC03FF
    AND     R2, 0xF3FFFFFF
    STR     R2,	[R1]

    LDR     R1, =GPIOC_PUPDR
    LDR     R2, [R1]
    AND     R2, 0xF3FFFFFF
    AND     R2, 0xFFFC03FF
    MOV     R0, 0x4000000
    ORRS    R2, R2, R0
    MOV     R0, 0x15400
    ORRS    R2, R2, R0
    LDR     R2, [R1]

    LDR     R8, =GPIOA_ODR
    LDR     R9, =GPIOC_IDR

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
