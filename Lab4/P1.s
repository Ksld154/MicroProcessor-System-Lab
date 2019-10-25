.syntax unified
.cpu cortex-m4
.thumb

.data
    arr: .byte 0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B, 0x77, 0x1F, 0x4E, 0x3D, 0x4F, 0x47 //TODO: put 0 to F 7-Seg LED pattern here
.text
    .global main

    .equ RCC_AHB2ENR  , 0x4002104C
    .equ GPIOA_MODER  , 0x48000000
    .equ GPIOA_OTYPER , 0x48000004
    .equ GPIOA_OSPEEDR, 0x48000008
    .equ GPIOA_PUPDR  , 0x4800000C
    .equ GPIOA_BSRR   , 0x48000018
    .equ GPIOA_BRR    , 0x48000028
    .equ DIN          , 0x20 //PA5
    .equ CS           , 0x40 //PA6
    .equ CLK          , 0x80 //PA7
    .equ DECODE       , 0x9
    .equ INTENSITY    , 0xA
    .equ SCAN_LIMIT   , 0xB
    .equ SHUT_DOWN    , 0xC
    .equ DISPLAY_TEST , 0xF
    .equ ONE          , 600000

main:
    BL      GPIO_init
    BL      max7219_init

loop:
    BL      Display0toF
    B       loop

GPIO_init:
//TODO: Initialize three GPIO pins as output for max7219 DIN, CS and CLK
    MOVS    R0, 0x1
    LDR     R1, =RCC_AHB2ENR
    STR     R0, [R1]

    MOVS    R0, 0x5400
    LDR     R1, =GPIOA_MODER
    LDR     R2, [R1]
    AND     R2, 0xFFFF03FF
    ORRS    R2, R2, R0
    STR     R2, [R1]

    MOVS    R0, 0xA800
    LDR     R1, =GPIOA_OSPEEDR
    STRH    R0, [R1]

    BX      LR

Display0toF:
//TODO: Display 0 to F at first digit on 7-SEG LED. Display one per second
//r8=counter
//r9=tmp_LR
    MOV     R8, 0x0
    MOV     R9, LR

    Accumulate:
    	MOV     R0, 0x1
        LDR     R3, =arr
        LDRB    R1, [R3, R8]
        BL      MAX7219Send

        LDR     R4, =ONE
        BL      Delay

        ADD     R8, #1
        CMP     R8, 0x10
        BNE     Accumulate

    MOV     LR, R9
    BX      LR

MAX7219Send:
//input parameter: r0 is ADDRESS , r1 is DATA
//TODO: Use this function to send a message to max7219
    LSL     R0, 8
    ADD     R0, R1
    LDR     R1, =DIN
    LDR     R2, =CS
    LDR     R3, =CLK
    LDR     R4, =GPIOA_BSRR //SEND HIGH WHEN LAST 16 BITS ARE SET 1
    LDR     R5, =GPIOA_BRR //SEND LOW WHEN LAST 16 BITS SET 1
    MOV     R6, 0x1000

    InnerLoop:
        STR     R3, [R5] //CLK->LOW
        AND     R7, R0, R6
        STR     R1, [R5] //DIN->LOW
        CMP     R7, 0
        BEQ     AfterSetDIN
        STR     R1, [R4] //DIN->HIGH

        AfterSetDIN:
            STR     R3, [R4] //CLK->HIGH
            LSR     R6, 1
            CMP     R6, 0
            BNE     InnerLoop
    STR     R2, [R5]
    STR     R2, [R4]
    BX      LR

max7219_init:
//TODO: Initialize max7219 registers
    MOV     R9, LR

    LDR     R0, =DECODE
    LDR     R1, =0x0 //NO DECODE
    BL      MAX7219Send

    LDR     R0, =INTENSITY
    LDR     R1, =0xD //LED BRIGHTNESS(MIN:0 MAX:F)
    BL      MAX7219Send

    LDR     R0, =SCAN_LIMIT
    LDR     R1, =0x0 //ONLY THE 0 DIGIT
    BL      MAX7219Send

    LDR     R0, =SHUT_DOWN
    LDR     R1, =0x1 //NO SHUTDOWN
    BL      MAX7219Send

    LDR     R0, =DISPLAY_TEST
    LDR     R1, =0x0 //NO DISPLAY TEST
    BL      MAX7219Send

    MOV     LR, R9
    BX      LR

Delay:
//TODO: Write a delay 1sec function
    SUB     R4, #1
    CMP     R4, 0
    BNE     Delay
    BX      LR
