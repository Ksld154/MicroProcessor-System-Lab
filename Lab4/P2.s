.syntax unified
.cpu cortex-m4
.thumb

.data
    student_id: .byte 0, 5, 1, 6, 2, 1, 5 //TODO: put your student id here
    .equ id_len, .-student_id 

.text
    .global main
    
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


main:
    //TODO: display your student id on 7-Seg LED
    BL GPIO_init
    BL MAX7219_init
    BL display_studentId
    B  Program_end



GPIO_init:
    //TODO: Initialize three GPIO pins as output for max7219 DIN, CS and CLK
    
    // use A5 ~ A7
    // Enable AHB clock for using GPIO bus   
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

    BX LR



MAX7219_init:
    //TODO: Initial max7219 registers.

    MOV R9, LR

    LDR r0, =DECODE_MODE
    LDR r1, =0xFF  // Code B (display number 0~9)
    BL MAX7219Send
    
    LDR r0, =#DISPLAY_TEST
    LDR r1, =0x0  // NO display test
    BL MAX7219Send

    LDR r0, =SCAN_LIMIT
    LDR r1, =0x6   // display digit 0~6
    BL MAX7219Send
    
    LDR r0, =INTENSITY
    LDR r1, =0xA   // brightness
    BL MAX7219Send
    
    LDR r0, =SHUTDOWN
    LDR r1, =0x1  // NO shutdown
    BL MAX7219Send

    MOV LR, R9
    BX  LR


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



display_studentId:
    
    //r9=tmp_LR
    MOV     R9, LR

    LDR  R10, =student_id  // address of student_id
    MOV  R11, 0x7          // digit position on LED
    MOV  R8,  #0           // index of student_id

    display_onedigit:

    	MOV     R0, R11
        LDRB    R1, [R10, R8]
        BL      MAX7219Send

        SUB     R11, #1
        ADD     R8, #1
        CMP     R11, 0x0
        BNE     display_onedigit

    MOV     LR, R9
    BX      LR


Program_end:
    B Program_end
