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
    LDR     R0, =leds   @ R0: address of leds
    STRB    R1, [R0]    @ R1: value of leds
    BL      DisplayLED
    LDR     R3, =ONE
    BL      Delay
    B       Loop

Loop:
//TODO: Write the display pattern into leds variable
//R0 = Address of leds
//R8 = output

// R1: index of current lighten leds
// R2: index of next leds
    
    @ A5 -> A8 (0001(1) -> 0011(3) -> 0110(6) -> 1100(12) -> 1000(8))
    GOLEFT: 
        LDR     R1, [R0]
        LSL     R2, R1, #1
        CMP     R1, #1     // when 0001(1) -> 0011(3)
        IT		EQ
        ADDEQ   R2, #1
        
        AND     R2, 0xF     // Mask upper bits to be all 0s, because when 01100(12) -> 11000, 
                            // we need to discard the highest bit to make it become 1000(8)
        STRB    R2, [R0]    // Save the index of next led, for later iteration
        BL      DisplayLED  // Lighten next led
        LDR     R3, =ONE
        BL      Delay       // Delay one second

        CMP     R2, 0x8     // if leftmost light is on, then go RIGHT
        BNE     GOLEFT
    
    // A8 -> A5
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

    // Enable AHB clock for using GPIO bus   
    MOVS    R0, 0x1           // 0x1 means using GPIO_A 
    LDR     R1, =RCC_AHB2ENR
    STR     R0, [R1]

    
    MOVS    R0, 0x15400      // 0x15400 means MODE5~MODE8 = 0b01 (output mode)
    LDR     R1, =GPIOA_MODER
    LDR     R2, [R1]
    AND     R2, 0xFFFC03FF   // mask MODE5~MODE8 = 0b00 first
    ORRS    R2, R2, R0
    STR     R2, [R1]         // set MODE5~MODE8 to output mode, and write to IO memory

    MOVS    R0, 0x2A800      
    LDR     R1, =GPIOA_OSPEEDR
    STRH    R0, [R1]         // high speed mode for OSPEED5~OSPEED8

    LDR     R8, =GPIOA_ODR

    BX      LR

DisplayLED:
    //TODO: Display LED by leds
    
    // R7: Current lighten leds
    // R8: Address of GPIOA's output register

    LDR     R7, [R0]   
    LSL     R7, #5     // R7 *= 32 because we are using A5~A8
    MVN     R7, R7     // R7 =  ~R7 because the led is "ACTIVE LOW", lighten when it's output register is 0
    STRH    R7, [R8]
    BX      LR

Delay:
    //TODO: Write a delay 1 sec function
    SUB     R3, R3, #1
    CMP     R3, 0
    BNE     Delay
    BX      LR
