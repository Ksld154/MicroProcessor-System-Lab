#include <stdio.h>

int N = 10;
int f1 = 1;
int f2 = 1;
int res = 0;




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



int main(){

    int res = 0;
    res = fib(N);
    printf("%d\n", res);

    return 0;
}
