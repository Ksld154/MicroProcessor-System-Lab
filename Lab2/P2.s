.syntax unified
.cpu cortex-m4
.thumb


.data
    result: .word 0
    max_size: .word 0
    user_stack_bottom: .zero 512
    .equ stk_size, .-user_stack_bottom


.text
    .global main
    m: .word 0x5E
    n: .word 0x60
    @ m: .word 0x01
    @ n: .word 0x01
    
    main:
        LDR  SP, =user_stack_bottom
        ADDS SP, stk_size
        LDR  R1, =m
        LDR  R2, =n
        LDR  R0, [R1]  // R0: value of m
        LDR  R1, [R2]  // R1: value of n
        MOV  R6, #0    // R6: occurance of both a and b are even
        MOV  R7, #0    // R7: maximum stack size

        @ MOV  R10, R0
        @ MOV  R11, R1
        @ PUSH {R10}
        @ PUSH {R11}
        PUSH  {R0, R1}
        ADDS  R7, #2

        BL GCD

        LSL  R2, R6

        @ BL GCD_get_value

        LDR  R8, =max_size
        LDR  R9, =result
        STR  R7, [R8]
        STR  R2, [R9]

        B program_end


    GCD:
        @ TODO: Implement your GCD function
         
        // R0: m
        // R1: n
        // R2: result = gcd(m, n)

        POP   {R11}            // R11: n
        POP   {R10}            // R10: m
        SUBS  R7, #2
        MOVS R0, R10
        MOVS R1, R11
        @ LDR R0, [SP]      // R0: m   
        @ LDR R1, [SP, #4]  // R1: n
        
        @ PUSH  {R0, R1}
        PUSH  {LR}
        ADDS  R7, #1

        CMP   R0, #0
        ITTT  EQ
        MOVEQ R2, R1
        POPEQ {R10}
        BXEQ LR

        CMP   R1, #0
        ITTT  EQ
        MOVEQ R2, R0
        POPEQ {R10}
        BXEQ LR

        @ both a and b are even => return 2*gcd(a>>1, b>>1)
        AND   R3, R0, #1  // R3 == 1, means that a is ODD      
        AND   R4, R1, #1  // R4 == 1, means that b is ODD
        ORR   R5, R3, R4  // R5: a & b (R5==1 means that AT LEAST a or b is ODD)
        
        CMP   R5, #0      //     i.e. R5==0 means that BOTH a and b is EVEN
        BEQ   both_even
        
        CMP   R3, #0
        BEQ   b_odd
        CMP   R4, #0
        BEQ   a_odd

        CMP   R0, R1
        BGE   a_bigger
        BLT   b_bigger

        BX LR
    
        both_even:
            LSR   R0, #1
            LSR   R1, #1
            ADD   R6, #1

            B gcd_recursive_call
            @ PUSH {R0, R1}
            @ PUSH {LR}  
            @ BL GCD
            @ POP  {LR}
            @ POP  {R0, R1}
            @ BX LR
        
        b_odd:
            LSR   R0, #1
            
            B gcd_recursive_call
            @ PUSH  {R0, R1}
            @ PUSH  {LR}
            @ BL GCD
            @ POP   {LR}
            @ POP   {R0, R1}
            @ BX LR
        
        a_odd:
            LSR   R1, #1
            
            B gcd_recursive_call
            @ PUSH  {R0, R1}
            @ PUSH  {LR}
            @ BL GCD
            @ POP   {LR}
            @ POP   {R0, R1}
            @ BX LR


        a_bigger:
            SUB   R0, R0, R1     // m = m - n
            B gcd_recursive_call

        b_bigger:
            SUB   R0, R1, R0     // m = n - m
            B gcd_recursive_call
        
        gcd_recursive_call:
            MOVS R10, R0
            MOVS R11, R1
            PUSH  {R10, R11}
            @ PUSH  {R11}
            ADDS  R7, #2
            BL GCD
            POP   {LR}
            BX LR

    GCD_get_value:
        LSL  R2, R6
        BX LR 

    program_end:
        B program_end