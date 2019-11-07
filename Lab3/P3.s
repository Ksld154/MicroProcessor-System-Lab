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
// R8 = Address of GPIOA_ODR (control pins' signal in port A)
    LDR     R4, [R9]    // Read signal from all pins in port C
    LSR     R4, R4, #13 // Button is PC13, we only want read it's signal, so we shift 13 bits right
    AND     R4, R4, 0x1 // Make R4 only one bit

    CMP     R4, #0      // Pressed => 0 (because of pull-up input)
    IT      EQ
    ADDEQ   R5, #1      // R5 adds 1 when receiving 0 from button signal (button is pressed)

    CMP     R4, #1      // If receiving 1 from button signal (button is not pressed or it's in button bounce duration)
    IT      EQ
    MOVEQ   R5, #0      // Reset counter (we MUST make sure that we receive 0 from button signal for 500 times CONTINUOUSLY, that is, we can't get 1 in these 500 times, if so, reset counter)

    CMP     R5, #500    // If counter reaches the threshold
    BNE     CHECKPRESS  // If not re-run CHECKPRESS

    B       CHECKPWD    // If so, check the password

BLINKTHRICE:
    BL      BLINK
    BL      BLINK
    BL      BLINK
    B       CHECKPRESS

BLINKONCE:
    BL      BLINK
    B       CHECKPRESS

BLINK:
    MOV     R4, LR      // Store the link register
    
    MOVS    R1, 0xF
    STRB    R1, [R0]    // led = 1111, that is all 4 leds will be displayed
    BL      DisplayLED
    LDR     R3, =ONE
    BL      Delay       // Wait 0.5s
    
    MOVS    R1, 0x0
    STRB    R1, [R0]    // led = 0000, that is all 4 leds will NOT be displayed
    BL      DisplayLED
    LDR     R3, =ONE
    BL      Delay       // Wait 0.5s
    
    MOV     LR, R4      // Load the link register
    BX      LR

CHECKPWD:
    LDR     R1, =password
    LDR     R2, [R1]    // Read the password value that we set in data section
    LDR     R3, [R9]    // Read signal from all pins in port C
    MVN     R3, R3      // Because DIP switch is pull-up, so we will get 0 if the switch is ON and 1 if OFF, thus we need to make R3 = ~R3 to get the correct value
    LSR     R3, R3, #5  // DIP switch is connected to PC5~PC8, so I shift 5 bits right and do logical AND with 0b1111 in next cmd to get PC5~PC8's signal
    AND     R3, R3, 0xF

    CMP     R2, R3
    BEQ     BLINKTHRICE // If DIP switch's value == password, then blink thrice
    CMP     R2, R3
    BNE     BLINKONCE   // else blink once

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

    //GPIOC: C13 => button, C5~C8 => DIP switch
    LDR     R1, =GPIOC_MODER
    LDR     R2, [R1]
    AND     R2, 0xFFFC03FF      // GPIOC_MODE 5~8 = 0b00 00 00 00 => input mode
    AND     R2, 0xF3FFFFFF      // GPIOC_MODE 13 = 0b00 => input mode
    STR     R2,	[R1]

    LDR     R1, =GPIOC_PUPDR
    LDR     R2, [R1]
    AND     R2, 0xF3FFFFFF      // Mask to set pin 13 to 0
    AND     R2, 0xFFFC03FF      // Mask to set pin 5~8 to 0
    MOV     R0, 0x4000000       // Set pin 13 to 0b01 (pull-up)
    ORRS    R2, R2, R0
    MOV     R0, 0x15400         // Set pin 5~8 to 0b01 01 01 01 (pull-up)
    ORRS    R2, R2, R0
    STR     R2, [R1]

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
//TODO: Write a delay 0.5 sec function
    SUB     R3, R3, #1
    CMP     R3, 0
    BNE     Delay
    BX      LR
