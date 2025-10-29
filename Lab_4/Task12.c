#include <stdio.h>

int is_digits_non_decreasing(int n) {
    if (n < 0) n = -n;
    if (n < 10) return 1;

    int prev_digit = n % 10;
    n /= 10;

    while (n > 0) {
        int current_digit = n % 10;
        if (current_digit > prev_digit) {
            return 0;
        }
        prev_digit = current_digit;
        n /= 10;
    }

    return 1;
}

int main() {
    int n;

    printf("Enter a number: ");
    scanf("%d", &n);

    if (is_digits_non_decreasing(n)) {
        printf("Digits are in non-decreasing order\n");
    } else {
        printf("Digits are NOT in non-decreasing order\n");
    }

    return 0;
}
