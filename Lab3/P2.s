.syntax unified
.cpu cortex-m4
.thumb

.data
    leds: .byte 0

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
    MOVS    R1, #1
    LDR     R0, =leds
    STRB    R1, [R0]
    BL      DisplayLED
    LDR     R3, =ONE
    MOV     R5, #0
    MOV     R6, #0
    BL      Delay
    B       Loop

Loop:
//TODO: Write the display pattern into leds variable
//R0 = Address of leds
//R6 = { 0(keep going), 1(stop) }
//R7 = { 0(go left), 1(go right) }
//R8 = output
//R9 = input
    GOLEFT:
        MOV     R7, #0
        CMP     R6, #1
        BEQ     STOP
        LDR     R1, [R0]
        LSL     R2, R1, #1
        CMP     R1, #1
        IT      EQ
        ADDEQ   R2, #1
        AND     R2, 0xF
        STRB    R2, [R0]
        BL      DisplayLED
        LDR     R3, =ONE
        BL      Delay

        CMP     R2, 0x8
        BNE     GOLEFT
    GORIGHT:
        MOV     R7, #1
        CMP     R6, #1
        BEQ     STOP
        LDR     R1, [R0]
        LSR     R2, R1, #1
        CMP     R1, #8
        IT      EQ
        ADDEQ   R2, #8
        AND     R2, 0xF
        STRB    R2, [R0]
        BL      DisplayLED
        LDR     R3, =ONE
        BL      Delay

        CMP     R2, 0x1
        BNE     GORIGHT

    B       Loop

STOP:
    LDR     R3, =ONE
    BL      Delay
    CMP     R6, #1
    BEQ     STOP

    CMP     R7, #0
    BEQ     GOLEFT
    CMP     R7, #1
    BEQ     GORIGHT


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
    AND     R2, 0xF3FFFFFF
    STR     R2,	[R1]

    MOVS    R0, 0x4000000
    LDR     R1, =GPIOC_PUPDR
    AND     R2, 0xF3FFFFFF
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
    B       CHECKPRESS

    CHECKDONE:
        CMP     R3, 0
        BNE     Delay
        BX      LR

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
    BNE     CHECKDONE
    EOR     R6, #1

    B       CHECKDONE
