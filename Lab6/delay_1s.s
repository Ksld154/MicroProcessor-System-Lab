.syntax unified
.cpu cortex-m4
.thumb
.data

.text
	.global delay_1s

    .equ onesec, 200000

do_delay:
	//TODO: Write a delay 1sec function
	SUB R3, R3, #1
	CMP R3, #0
	BNE do_delay
	BX  LR

delay_1s:
	LDR R3, =onesec
	B do_delay