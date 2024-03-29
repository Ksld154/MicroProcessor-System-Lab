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
    m: .word 0x01
    n: .word 0x03
    
    main:
        LDR  SP, =user_stack_bottom
        ADDS SP, stk_size
        LDR  R1, =m
        LDR  R2, =n
        LDR  R0, [R1]  // R0: value of m
        LDR  R1, [R2]  // R1: value of n
        MOV  R6, #0    // R6: occurance of both a and b are even
        MOV  R7, #0    // R7: number of current stack items
        MOV  R9, #0    // R9: number of maximum stack items


        PUSH  {R0}
        PUSH  {R1}
        ADDS  R7, #2
        BL update_max_stk_size

        BL GCD

        LSL  R2, R6

        LDR  R8, =max_size
        STR  R9, [R8]
        LDR  R8, =result
        STR  R2, [R8]

        B program_end


    GCD:
        // TODO: Implement your GCD function
         
        // R0: m
        // R1: n
        // R2: result = gcd(m, n)

        POP   {R11}            // R11: n
        POP   {R10}            // R10: m
        SUBS  R7, #2
        MOVS  R0, R10          // R0: m   
        MOVS  R1, R11          // R1: n
        
        PUSH  {LR}
        ADDS  R7, #1

        CMP   R0, #0          // if(m == 0){
        ITTT  EQ              //
        MOVEQ R2, R1          //    result = n;   
        POPEQ {R10}           //    return to main;
        BXEQ LR               // }

        CMP   R1, #0          // if(n == 0) {
        ITTT  EQ              // 
        MOVEQ R2, R0          //    result = m;   
        POPEQ {R10}           //    return to main
        BXEQ LR               // }

        
        
        AND   R3, R0, #1  // R3 == 1, means that a is ODD      
        AND   R4, R1, #1  // R4 == 1, means that b is ODD
        ORR   R5, R3, R4  // R5: a & b (R5 == 1, means that AT LEAST a is ODD or b is ODD)
        
        CMP   R5, #0      // CASE1: R5 == 0, means that BOTH a and b is EVEN
        BEQ   both_even   //        => return 2*gcd(a>>1, b>>1)
        
        CMP   R3, #0      // CASE2: R3 == 0, means that a is EVEN and b is ODD
        BEQ   b_odd                
        CMP   R4, #0      // CASE3: R4 == 0, means that a is ODD  and b is EVEN
        BEQ   a_odd

        CMP   R0, R1      // CASE4: both a and b are ODD
        BGE   a_bigger
        BLT   b_bigger

        BX LR
    
        both_even:
            LSR   R0, #1          // m /= 2
            LSR   R1, #1          // n /= 2
            ADD   R6, #1          // R6: occurance of both a and b are even, this means how many times we need to multiply 2
                                  //     to get the GCD result at main function.
            B gcd_recursive_call
        
        b_odd:
            LSR   R0, #1          // m /= 2
            B gcd_recursive_call  // return gcd(m/2, n)
        
        a_odd:
            LSR   R1, #1          // n /= 2
            B gcd_recursive_call  //return gcd(m, n/2)


        a_bigger:
            SUB   R0, R0, R1      // m = m - n
            B gcd_recursive_call  // return gcd(m-n, n) 

        b_bigger:
            MOVS  R8, R0         // tmp = m
            SUB   R0, R1, R0     // m' = n - m
            MOVS  R1, R8         // n' = tmp
            B gcd_recursive_call // return gcd(n-m, m)
        
        gcd_recursive_call:
            MOVS R10, R0
            MOVS R11, R1
            PUSH {R10}
            PUSH {R11}
            ADD  R7, #2
            BL update_max_stk_size
            BL GCD
            POP  {LR}
            BX LR

        update_max_stk_size:
            CMP R7, R9
            IT  GT
            MOVGT R9, R7
            BX LR

program_end:
    B program_end