.syntax unified
.cpu cortex-m4
.thumb


.data 
    result: .word 0  // initialize an int32 with value 0

.text 
.global main
.equ N, 100




fib:
    cbz R0, success_Return   // if n == 0, then return to main 
    adds R3, R1, R2          // f[k] = f[k-2] + f[k-1]
    bvs fail_Overflow
    movs R1, R2              // f[k-2] = f[k-1]
    movs R2, R3              // f[k-1] = f[k]
    subs R0, R0, #1          // n--
    b fib


checkN:
    cmp R0, #100            // N > 100
    bgt fail_OutOfRange
    cmp R0, #1              // N < 1
    blt fail_OutOfRange
    cmp R0, #2              // N <= 2  (N == 1 or N == 2)
    bls success_FirstTwoIndex

    subs R0, #2 
    bx lr  // return to main

fail_OutOfRange:         // ans = -1
    movs R4, #0
    subs R4, 1
    b L  // Return to L

fail_Overflow:           // ans = -2
    movs R4, #0
    subs R4, 2
    b L 

success_FirstTwoIndex:   // ans = 1 
    movs R4, #1
    b L

success_Return:
    movs R4, R3
    bx lr  // Return to main where it calls bl

main:
    movs R0, N
    movs R1, #1      // R1 is initialized as 1, stands for fib(1)
    movs R2, #1      // R2 is initialized as 1, stands for fib(2)
    
    ldr R3, =result  // R3 stores the "address" of "result"
    ldr R4, [R3]     // R4 is initialized as 0 (value of "result")
    bl checkN
    bl fib

L: b L
