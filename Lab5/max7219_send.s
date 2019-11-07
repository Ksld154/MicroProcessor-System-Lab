.syntax unified
.cpu cortex-m4
.thumb

.text
    .global max7219_send
    
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

max7219_send:
    //input parameter: r0 is ADDRESS , r1 is DATA
    //TODO: Use this function to send a message to max7219
    PUSH    {R0, R1, R2, R3, R4, R5, R6, R7, LR}

    LSL     R0, 8
    ADD     R0, R1
    LDR     R1, =DIN
    LDR     R2, =CS
    LDR     R3, =CLK
    LDR     R4, =GPIOA_BSRR //SEND HIGH WHEN LAST 16 BITS ARE SET 1
    LDR     R5, =GPIOA_BRR //SEND LOW WHEN LAST 16 BITS SET 1
    MOV     R6, 0x8000

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

    POP     {R0, R1, R2, R3, R4, R5, R6, R7, LR}
    BX      LR
