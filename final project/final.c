#include "stm32l476xx.h"
#define ONE_MSECOND 200
#define PWM1 42
#define PWM2 35
#define TURN_TIME 250
#define STOP_TIME 1000
#define LEFT 0
#define RIGHT 1

void GPIO_Init(void){
	// AHB2
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOCEN;
	// PA9, PA10
	GPIOA->MODER   &= 0b11111111110000000000001111110000;
	GPIOA->MODER   |= 0b00000000001010010101010000001010;
	GPIOA->OSPEEDR &= 0b11111111110000000000001111110000;
	GPIOA->OTYPER  &= 0b11111111111111111111100000011100;

	GPIOA->AFR[0] &= ~(GPIO_AFRL_AFSEL0 & GPIO_AFRL_AFSEL1);//AFR[0] LOW
	GPIOA->AFR[0] |= GPIO_AFRL_AFSEL0_0 | GPIO_AFRL_AFSEL1_0;//PA0 PA1
	// AF7
	GPIOA->AFR[1] = (GPIOA->AFR[1] & 0xFFFFF00F) | 0x00000770;//AFR[1] HIGH
	// PC13
	GPIOC->MODER   &= 0b11110011111111111111000011111111;
	GPIOC->MODER   |= 0b00000000000000000000101000000000;
	GPIOC->OSPEEDR &= 0b11110011111111111111000011111111;
	GPIOC->OSPEEDR |= 0b00000100000000000000000000000000;
	GPIOC->OTYPER  &= 0b11111111111111111111111111001111;
	// AF7
	GPIOC->AFR[0] = (GPIOC->AFR[0] & 0xFF00FFFF) | 0x00770000;//AFR[0] HIGH
}

void USART1_Init(void){
	// APB2
	RCC->APB2ENR |= RCC_APB2ENR_USART1EN;

	// Word length, Parity selection, Parity control enable, Transmitter enable, Receiver enable, Oversampling mode
	USART1->CR1  = (USART1->CR1 & ~(USART_CR1_M | USART_CR1_PS | USART_CR1_PCE | USART_CR1_TE | USART_CR1_RE | USART_CR1_OVER8)) | (USART_CR1_TE | USART_CR1_RE);
	// STOP bits, LIN mode enable, Clock enable
	USART1->CR2  = (USART1->CR2 & ~(USART_CR2_STOP | USART_CR2_LINEN | USART_CR2_CLKEN)) | (0x0);
	// RTS enable, CTS enable, One sample bit method enable, Smartcard mode enable, Half-duplex selection, IrDA mode enable
	USART1->CR3  = (USART1->CR3 & ~(USART_CR3_RTSE | USART_CR3_CTSE | USART_CR3_ONEBIT | USART_CR3_SCEN | USART_CR3_HDSEL | USART_CR3_IREN)) | (0x0);
	// USARTDIV
	USART1->BRR  = (USART1->BRR & 0xFFFF) | (4000000L/9600L);
	// USART enable
	USART1->CR1  |= USART_CR1_UE;

	// APB1
	RCC->APB1ENR1 |= RCC_APB1ENR1_USART3EN;
	// Word length, Parity selection, Parity control enable, Transmitter enable, Receiver enable, Oversampling mode
	USART3->CR1  = (USART3->CR1 & ~(USART_CR1_M | USART_CR1_PS | USART_CR1_PCE | USART_CR1_TE | USART_CR1_RE | USART_CR1_OVER8)) | (USART_CR1_TE | USART_CR1_RE);
	// STOP bits, LIN mode enable, Clock enable
	USART3->CR2  = (USART3->CR2 & ~(USART_CR2_STOP | USART_CR2_LINEN | USART_CR2_CLKEN)) | (0x0);
	// RTS enable, CTS enable, One sample bit method enable, Smartcard mode enable, Half-duplex selection, IrDA mode enable
	USART3->CR3  = (USART3->CR3 & ~(USART_CR3_RTSE | USART_CR3_CTSE | USART_CR3_ONEBIT | USART_CR3_SCEN | USART_CR3_HDSEL | USART_CR3_IREN)) | (0x0);
	// USARTDIV
	USART3->BRR  = (USART3->BRR & 0xFFFF) | (4000000L/9600L);
	// USART enable
	USART3->CR1  |= USART_CR1_UE;
}

void Timer_init(){
	//TODO: Initialize timer
	RCC->APB1ENR1 |= RCC_APB1ENR1_TIM2EN;
	TIM2->CR1 &= ~(TIM_CR1_CEN);
	TIM2->PSC = 39U;
	TIM2->ARR = 99U;
	TIM2->EGR = TIM_EGR_UG;
}

void PWM_channel_init(){
	//TODO: Initialize timer PWM channel
	TIM2->CR1 |= TIM_CR1_ARPE;
	//enable output compare
	TIM2->CCER |= TIM_CCER_CC1E;
	TIM2->CCER |= TIM_CCER_CC2E;

	TIM2->CCMR1 &= ~(TIM_CCMR1_OC1M & TIM_CCMR1_OC2M);
	//110: PWM mode 1: TIMx_CNT<TIMx_CCR2-->active, or inactive
	TIM2->CCMR1 |= (TIM_CCMR1_OC1M_1 | TIM_CCMR1_OC1M_2 | TIM_CCMR1_OC2M_1 | TIM_CCMR1_OC2M_2);

	TIM2->CCR1 = 0;
	TIM2->CCR2 = 0;
}

int UART_Send(char *arr, uint32_t size, int USARTnum){
	int sent = 0;
	if(USARTnum == 1){
		for(int i = 0; i < size; ++i){
			while(!(USART1->ISR & USART_ISR_TXE));
			USART1->TDR = (*arr & 0xFF);
			sent++;
			arr++;
		}
		while(!(USART1->ISR & USART_ISR_TC));
	}else if(USARTnum == 2){
		for(int i = 0; i < size; ++i){
			while(!(USART3->ISR & USART_ISR_TXE));
			USART3->TDR = (*arr & 0xFF);
			sent++;
			arr++;
		}
		while(!(USART3->ISR & USART_ISR_TC));
	}
	return sent;
}

int UART_Receive(int USARTnum){
	char recv_buf[20]={0};
	int distance = 0;
	int DATA_LEN = 3;
	// total_recv_byte = 4(header bytes) + DATA_LEN + 1(checksum bytes);
	if(USARTnum == 1){
		for(int i = 0; i <= 3; i++){
			while(!(USART1->ISR & USART_ISR_RXNE));
			recv_buf[i] = (USART1->RDR & 0xFF);

			// check legal header
			if( i <= 1 && recv_buf[i] != 0x5a) {
				// i = 0;
				// continue;
				return -1;
			}

			if(i == 3){
				DATA_LEN = recv_buf[i];
			}
		}
		for(int j = 4; j < DATA_LEN+5; j++){
			while(!(USART1->ISR & USART_ISR_RXNE));
			recv_buf[j] = (USART1->RDR & 0xFF);
		}
	}else if(USARTnum == 2){
		for(int i = 0; i <= 3; i++){
			while(!(USART3->ISR & USART_ISR_RXNE));
			recv_buf[i] = (USART3->RDR & 0xFF);

			// check legal header
			if( i <= 1 && recv_buf[i] != 0x5a) {
				// i = 0;
				// continue;
				return -1;
			}

			if(i == 3){
				DATA_LEN = recv_buf[i];
			}
		}
		for(int j = 4; j < DATA_LEN+5; j++){
			while(!(USART3->ISR & USART_ISR_RXNE));
			recv_buf[j] = (USART3->RDR & 0xFF);
		}
	}
	// skip checking checksum
	distance = (recv_buf[4] << 8) | recv_buf[5];
	return distance;
}

void busy_waiting(int val){
	for(int i = val; i >= 0; i--) {};
}

int detect_distance(int USARTnum){
	char cmd_getDistance[3] = {0xA5, 0x15, 0xBA};
	int distance = 0;
	UART_Send(cmd_getDistance, 3, USARTnum);
	distance = UART_Receive(USARTnum);
	return distance;
}

void turn(int left_or_right){
	if(left_or_right == LEFT){
		GPIOA->ODR = 0b0110 << 5;
		busy_waiting(TURN_TIME * ONE_MSECOND);
		GPIOA->ODR = 0b1111 << 5;
		busy_waiting(500 * ONE_MSECOND);
	}else if(left_or_right == RIGHT){
		GPIOA->ODR = 0b1001 << 5;
		busy_waiting(TURN_TIME * ONE_MSECOND);
		GPIOA->ODR = 0b1111 << 5;
		busy_waiting(500 * ONE_MSECOND);
	}
}

void run(){
	int distance = 0;
	int object_flag = 0;
	int corner_flag = 0;
	int counter = 0;
	int stop = 0;
	while(1){
		object_flag = 0;
		while(1){
			distance = detect_distance(1);
			if(distance <= 180 && distance > 0){
				if(object_flag == 0){
					GPIOA->ODR = 0b1111 << 5;
					busy_waiting(STOP_TIME * ONE_MSECOND);
					TIM2->CCR1 = 40;
					TIM2->CCR2 = 50;
				}
				stop = 1;
				object_flag = 1;
				counter = 0;
				if(corner_flag == 1) turn(RIGHT); else turn(LEFT);
				continue;
			}else{
				if(object_flag == 1){
					corner_flag = !corner_flag;
					GPIOA->ODR = 0b1111 << 5;
					busy_waiting(STOP_TIME * ONE_MSECOND);
					GPIOA->ODR = 0b0101 << 5;
					TIM2->CCR1 = 93;
					TIM2->CCR2 = 100;
					busy_waiting(100 * ONE_MSECOND);
					TIM2->CCR1 = PWM1;
					TIM2->CCR2 = PWM2+15;
					// TIM2->CCR1 = PWM1;
					// TIM2->CCR2 = PWM2;
				}else{
					corner_flag = 0;
				}
				object_flag = 0;
				counter++;
				GPIOA->ODR = 0b0101 << 5;
				if(counter == 15 && stop == 1){
					TIM2->CCR1 = PWM1;
					TIM2->CCR2 = PWM2+7;
				}
				break;
			}
		}
		object_flag = 0;
		while(1){
			distance = detect_distance(2);
			if(distance <= 180 && distance > 0){
				if(object_flag == 0){
					GPIOA->ODR = 0b1111 << 5;
					busy_waiting(STOP_TIME * ONE_MSECOND);
					TIM2->CCR1 = 50;
					TIM2->CCR2 = 40;
				}
				stop = 1;
				object_flag = 1;
				counter = 0;
				if(corner_flag == 1) turn(LEFT); else turn(RIGHT);
				continue;
			}else{
				if(object_flag == 1){
					corner_flag = !corner_flag;
					GPIOA->ODR = 0b1111 << 5;
					busy_waiting(STOP_TIME * ONE_MSECOND);
					GPIOA->ODR = 0b0101 << 5;
					TIM2->CCR1 = 93;
					TIM2->CCR2 = 100;
					busy_waiting(100 * ONE_MSECOND);
					TIM2->CCR1 = PWM1;
					TIM2->CCR2 = PWM2-5;
					// TIM2->CCR1 = PWM1;
					// TIM2->CCR2 = PWM2;
				}else{
					corner_flag = 0;
				}
				object_flag = 0;
				GPIOA->ODR = 0b0101 << 5;
				counter++;
				if(counter == 15 && stop == 1){
					TIM2->CCR1 = PWM1;
					TIM2->CCR2 = PWM2+5;
				}
				break;
			}
		}
	}
}

int main(void){
	GPIO_Init();
	USART1_Init();
	Timer_init();
	PWM_channel_init();
	TIM2->CR1 |= TIM_CR1_CEN;

	busy_waiting(2000 * ONE_MSECOND);
	GPIOA->ODR = 0b0101 << 5;
	TIM2->CCR1 = 93;
	TIM2->CCR2 = 100;
	busy_waiting(100 * ONE_MSECOND);
	TIM2->CCR1 = PWM1;
	TIM2->CCR2 = PWM2+5;
	run();
	return 0;
}
