.syntax unified
.cpu cortex-m4
.thumb


.data
    user_stack_bottom: .zero 128
    .equ stk_size, .-user_stack_bottom
    expr_result: .word 0

.text
    .global main
    postfix_expr: .asciz "-100 10 20 + - 10 +" //ans: -120
    //postfix_expr: .asciz "2 3 1 + + 9 -" //ans: -3
    
    main:
        // TODO: Setup stack pointer to end of user_stack and calculate the
        // expression using PUSH, POP operators, and store the result into expr_result

        LDR  R0, =postfix_expr            // save postfix_expr's address into R0
        LDR  R9, =expr_result
        LDR  SP, =user_stack_bottom   
        ADDS SP, stk_size                 // SP(R13): The highest memory address of the user_stack 
        B evaluate_postfix


evaluate_postfix:
    
    BL strlen
    // R0: base address of postfix_expr
    // R1: return the length of postfix_expr
    // R2: int i = 0
    // R3: expr[i]

    MOVS R2, #0
    MOVS R10, #-1
    
    eval_ScanLoop:                  // for(i = 0; i < strlen(expr); i++)
        CMP  R2, R1                 //     if(i >= strlen(expr)) exit_loop
        BGE  show_result

        LDRB R3, [R0, R2]           //     R3: expr[i]

        CMP  R3, #32                //     if (s[i] == ' ')
        BEQ  eval_isSpace           //         then do nothing, i++
        CMP  R3, #48                //     else if (s[i] is digit)
        BGE  eval_isDigit           //         get the integer value
        CMP  R3, #43                //     else if (s[i] == '+')
        BEQ  eval_plus              //         do add operation
        CMP  R3, #45                //     else if (s[i] == '-')
        BEQ  eval_minus             //         NOT SURE it's (1)sign bit or (2) subtract operation

        eval_isSpace:
            ADDS R2, #1
            B eval_ScanLoop
        
        eval_isDigit:
            BL atoi
            CMP  R2, R1            // check expr[i] doesn't exceed it's boundary
            BLT  eval_ScanLoop
        
        eval_plus:
            BL operation_plus
            ADDS R2, #1
            B eval_ScanLoop
        
        eval_minus:
            @ expr[i] == '-' 
            @ Might be (1)sign bit or (2) MINUS operation
            ADDS R2, R2, #1
            LDRB R4, [R0, R2]       // R4: expr[i+1]
            SUBS R2, #1

            CMP  R4, #32            // expr[i+1] == ' '
            BEQ  operation_minus    //      do MINUS operation
            CMP  R4, #0             // expr[i+1] == '\0'
            BEQ  operation_minus    //      do MINUS operation

            MOVS R7, #1             // sign bit is 1(negative)
            ADDS R2, #1
            BL atoi
            CMP  R2, R1             // check expr[i] doesn't exceed it's boundary
            BLT  eval_ScanLoop      

        


    strlen:
        @ Return the length for a given string
        // R0: base address of postfix_expr
        // R1: return the length of postfix_expr

        MOVS R1, #0               // R1: int i = 0; it's a for loop iterator

        strlen_Loop:              // for(i = 0; arr[i]!='\0'; i++)
            LDRB R2, [R0, R1]     //    R2: arr[i]
            CMP  R2, 0            //    if(arr[i] == '\0') 
            BEQ  strlen_Escape    //        exit for_loop
            ADDS R1, #1           //    i++
            B strlen_Loop
        strlen_Escape:
            BX LR
    

    
    atoi:
        // TODO: implement a “convert string to integer” function
        // R0: base address of expr
        // R2: i for expr
        // R3: expr[i]
    
        // R6: converted_integer
        // R7: sign bit(0: positive, 1: negative)
        // R8: #10
        MOV  R6, #0
        MOV  R8, #10
        

        atoi_Loop:                  // for(i = 0; expr[i]!='\0'; i++)
            LDRB R3, [R0, R2]       //    R3: expr[i]
            CMP  R3, #32            //    if(expr[i] == ' ') 
            BEQ  atoi_Return        //        exit for_loop

            MUL  R6, R8             // R6 *= 10
            SUBS R3, #48            
            ADDS R6, R3             // R6 += expr[i] - '0';
            
            ADDS R2, #1             //    i++
            B atoi_Loop
        
        atoi_Return:
            CMP  R7, #1
            BNE  atoi_ReturnPositive            
            
            SUBS R7, #2             // R7 = -1
            MULS R6, R7             // R6 *= -1
            PUSH {R6}
            BX LR
        
        atoi_ReturnPositive:
            PUSH {R6}
            BX LR
   
    
    operation_plus:
        // R4: Operand 1 => result
        // R5: Operand 2 

        // 1. pop 2 operands from stack, and add them together
        // 2. push the result back to stack

        POP  {R4}
        POP  {R5}
        ADDS R4, R5
        PUSH {R4}
        BX LR

    operation_minus:
        POP  {R4}
        POP  {R5}
        SUBS R5, R4
        PUSH {R5}
        ADDS R2, #1
        B eval_ScanLoop

    show_result:
        POP  {R4}
        STR R4, [R9]
        B program_end

program_end:
    B program_end