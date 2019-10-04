

# MPSL Lab1

0516215 林亮穎
0516220 李元毓


## Table of Contents

[TOC]

## 1. What - 實驗步驟
- **1-1 Hamming Distance**
    
- **1-2 Fibonacci Numbers**

- **1-3 Hamming Distance**


## 2. How 實驗要怎麼做

- **2-1 Hamming Distance**
    
- **2-2 Fibonacci Numbers**
  - **C Code**
    ``` C=
    int fib(int n){

        // N is outof range
        if(n < 1 || n > 100){
            return -1;
        }

        // first two item in fibonacci series
        if(n == 1 || n == 2){
            return 1;
        }

        // fibonacci calculation
        n -= 2;
        while(n > 0){
            res = f1 + f2;
            if(overflow(res)){
                return -2;
            }

            f1 = f2;
            f2 = res;
            n--;
        }
        return res;
    }
    ```
  - **C code Description**
    上面是一段簡單的C code，可計算出費氏數列第n項。
    針對被傳進來的n，會依序進行以下判定：
       ```
        1. 若N不在題目容許範圍內(1~100)， 則回傳-1
        2. 若N=1或N=2，直接回傳1
       ``` 
    若以上條件都未滿足，就直接進行費氏數列的計算，
    計算途中若是overflow，則回傳-2
    
  - **Assembly Code**
    ```assembly= 
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
        cmp R0, #100
        bgt fail_OutOfRange
        cmp R0, #1
        blt fail_OutOfRange
        cmp R0, #2
        bls success_FirstTwoIndex

        subs R0, #2 
        bx lr

    fail_OutOfRange:
        movs R4, #0
        subs R4, 1
        b L  // Return to L

    fail_Overflow:
        movs R4, #0
        subs R4, 2
        b L  // Return to L

    success_FirstTwoIndex:
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
    ```
  - **Assembly Code Descriptiotn**

- **2-3 Hamming Distance**




## 3. Feedback 實驗心得或建議
```sequence
Alice->Bob: Hello Bob, how are you?
Note right of Bob: Bob thinks
Bob-->Alice: I am good thanks!
Note left of Alice: Alice responds
Alice->Bob: Where have you been?
```

> Read more about sequence-diagrams here: http://bramp.github.io/js-sequence-diagrams/


###### tags: `Templates` `Documentation`
