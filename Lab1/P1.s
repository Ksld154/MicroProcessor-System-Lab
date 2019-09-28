.syntax unified
.cpu cortex-m4
.thumb

.data
    result: .byte 0

.text
.global main
.equ X, 0x55AA
.equ Y, 0xAA55

hamm:
//TODO
    eor R0, R1  // X = X XOR Y
    b cntones   // Go to cntones

cntones:
//Loop
    cbz R0, return  // If(X == 0) Go to return
    and R4, R0, #1  // R4 = X AND 1
    add R3, R4      // R3 += R4
    lsr R0, #1      // R4 = R4 >> 1 (R4 = R4 / 2)
    b cntones       // Go to cntones again

return:
    bx lr  // Return to main where it calls bl

main:
    ldr R0, =X       // R0 stores the "value" of "X"
    ldr R1, =Y       // R1 stores the "value" of "Y"
    ldr R2, =result  // R2 stores the "address" of "result"
    ldr R3, [R2]     // Initiate R3 as 0 (value of "result")
    bl hamm          // Go to hamm and store return address
    str R3, [R2]     // Store the final value of R3 to *R2 (*R2 = result = R3)

L: b L
