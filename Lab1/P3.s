.syntax unified
.cpu cortex-m4
.thumb

.data
    arr1: .byte 0x19, 0x34, 0x14, 0x32, 0x52, 0x23, 0x61, 0x29
    .equ len1, .-arr1   // len1 store arr1's length. (The dot in ".-arr1" means current address => current address minus arr1's start address = length of arr1 = 8)
    arr2: .byte 0x18, 0x17, 0x33, 0x16, 0xFA, 0x20, 0x55, 0xAC
    .equ len2, .-arr2   // len2 store arr2's length. (The dot in ".-arr2" means current address => current address minus arr2's start address = length of arr2 = 8)
.text
.global main

sub_loop:               // (for j = 0; j < arr.len-i; j++)
    add r4, r3, #1      // r4 = j + 1
    sub r5, r1, r2      // r5 = arr.len - i
    cmp r3, r5          // if(j == (arr.len - i)):
    beq do_sort         //     Go to do_sort
                        // else:
    ldrb r6, [r0, r3]   //     r6 = arr[j]
    ldrb r7, [r0, r4]   //     r7 = arr[j+1]
    cmp r6, r7          //     if (r6 == r7):
    bgt swap            //         Go to swap
                        //     else:
    add r3, #1          //         j += 1
    b sub_loop          //         Go to sub_loop

do_sort:                // (for i = 0; i < arr.len; i++)
    //TODO
    cmp r2, r1          // if(i == arr.len):
    beq return          //     Go to return
                        // else:
    add r2, #1          //     i += 1
    mov r3, #0          //     r3 = 0 (inner loop's j)
    b sub_loop          //     Go to sub_loop

swap:
    strb r6, [r0, r4]   // arr[j+1] = r6
    strb r7, [r0, r3]   // arr[j] = r7
    b sub_loop          // Go to sub_loop

return:
    bx lr

main:
    ldr r0, =arr1       // r0 = arr1's start address
    ldr r1, =len1       // r1 = arr1's length
    mov r2, #0          // r2 = 0 (outer loop's i)
    bl do_sort          // Go to do_sort
    ldr r0, =arr2
    ldr r1, =len2
    mov r2, #0
    bl do_sort

L: b L
