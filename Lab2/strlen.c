#include<stdio.h>

int stringlen(char *arr){
    int cnt = 0;

    for(int i = 0; arr[i] != '\0'; i++){
        cnt++;
    }
    return cnt;
}

int main(){
    char test[] = "hello, there!";

    int res = stringlen(test);

    printf("%d\n", res);

}