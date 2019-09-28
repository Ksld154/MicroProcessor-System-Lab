.syntax unified
.cpu cortex-m4
.thumb

.data
    arr1: .byte 0x19, 0x34, 0x14, 0x32, 0x52, 0x23, 0x61, 0x29
    .equ len1, .-arr1
    arr2: .byte 0x18, 0x17, 0x33, 0x16, 0xFA, 0x20, 0x55, 0xAC
    .equ len2, .-arr2
.text
.global main

sub_loop:
    add r4, r3, #1
    sub r5, r1, r2
    cmp r3, r5
    beq do_sort
    ldrb r6, [r0, r3]
    ldrb r7, [r0, r4]
    cmp r6, r7
    bgt swap
    add r3, #1
    b sub_loop

do_sort:
    //TODO
    cmp r2, r1
    beq return
    add r2, #1
    mov r3, #0
    b sub_loop

swap:
    strb r6, [r0, r4]
    strb r7, [r0, r3]
    b sub_loop

return:
    bx lr

main:
    ldr r0, =arr1
    ldr r1, =len1
    mov r2, #0
    bl do_sort
    ldr r0, =arr2
    ldr r1, =len2
    mov r2, #0
    bl do_sort

L: b L
