// Recursive C++ program to 
// implement Stein's Algorithm 
#include <bits/stdc++.h> 
using namespace std; 

// Function to implement 
// Stein's Algorithm 
int gcd(int a, int b) { 
	
	if (a == b) 
		return a; 

	// GCD(0, b) == b; GCD(a, 0) == a, 
	// GCD(0, 0) == 0 
	if (a == 0) 
		return b; 
	if (b == 0) 
		return a; 


	// look for factors of 2 
	if (~a & 1) {  // a is even
		if (b & 1) // b is odd 
			return gcd(a >> 1, b); 
		else // both a and b are even 
			return gcd(a >> 1, b >> 1) << 1; 
	} 

	if (~b & 1) // a is odd, and b is even 
		return gcd(a, b >> 1); 

	// reduce larger number 
	if (a > b) 
		return gcd((a - b) >> 1, b); 

	return gcd((b - a) >> 1, a); 
} 

// Driver code 
int main() { 
	int a = 34, b = 17; 
	printf("Gcd of given numbers is %d\n", gcd(a, b)); 
	return 0; 
} 
