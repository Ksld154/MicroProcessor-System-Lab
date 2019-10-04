#include<stdio.h>

int myAtoi(char *input_str){

    int signBit = 1;
    int value = 0;
    int i = 0;

    if(input_str[0] == '-'){
        signBit = -1;
        i++;
    }

    for(; input_str[i] != '\0'; i++){
        value *= 10;
        value += input_str[i] - '0';
    }

    return signBit * value;
}


int main(){
    
    char test[] = "-1234";
    int res = myAtoi(test);
    printf("%d\n", res);

    return 0;
}