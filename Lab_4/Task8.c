#include <stdio.h>

int alternate_with_zero(int n) {
    if (n == 0) return 0;

    int result = 0;
    int multiplier = 1;
    int num = (n < 0) ? -n : n;

    // Обрабатываем цифры в прямом порядке
    int temp = num;
    int length = 0;
    while (temp > 0) {
        length++;
        temp /= 10;
    }

    int digits[length];
    temp = num;
    for (int i = length - 1; i >= 0; i--) {
        digits[i] = temp % 10;
        temp /= 10;
    }

    // Собираем результат с нулями после каждой цифры
    for (int i = 0; i < length; i++) {
        result = result * 10 + digits[i];
        result = result * 10 + 0;
    }

    return (n < 0) ? -result : result;
}

int main() {
    int n;

    printf("Enter a number: ");
    scanf("%d", &n);

    int result = alternate_with_zero(n);

    printf("Original number: %d\n", n);
    printf("Number with zeros: %d\n", result);

    return 0;
}
