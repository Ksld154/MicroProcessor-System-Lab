#include <stdio.h>

#define ARRAY_LEN 8

// swap the value of a and b
void swap(int *a, int *b){
    int tmp = *a;
    *a = *b;
    *b = tmp;
}

void bubbleSort(int *arr){
    for (int i = 0; i < ARRAY_LEN; i++){
        for(int j = 0; j < ARRAY_LEN-i-1; j++){
            if(arr[j] >= arr[j+1]){
                swap(&arr[j], &arr[j+1]);
            }
        }
    }
}

int main(){

    int arr[ARRAY_LEN] = {8 ,11, 1, -2, 21, 0, 6, -11};
    
    bubbleSort(arr);
    
    for (int i = 0; i < ARRAY_LEN; i++){
        printf("%d ", arr[i]);
    }
    return 0;
}