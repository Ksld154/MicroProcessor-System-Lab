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
    eor r0, r1      // X = X XOR Y
    b cntones       // Go to cntones

cntones:
    // Loop
    cbz r0, return  // If(X == 0) Go to return
    and r4, r0, #1  // r4 = X AND 1
    add r3, r4      // r3 += r4
    lsr r0, #1      // r4 = r4 >> 1 (r4 = r4 / 2)
    b cntones       // Go to cntones again

return:
    bx lr           // Return to main where it calls bl

main:
    ldr r0, =X      // r0 stores the "value" of "X"
    ldr r1, =Y      // r1 stores the "value" of "Y"
    ldr r2, =result // r2 stores the "address" of "result"
    ldr r3, [r2]    // Initiate r3 as 0 (value of "result")
    bl hamm         // Go to hamm and store return address
    str r3, [r2]    // Store the final value of r3 to *r2 (*r2 = result = r3)

L: b L
