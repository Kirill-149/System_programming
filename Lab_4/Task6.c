#include <stdio.h>

int main() {
    int n = 0;
    int sum = 0;

    printf("Enter n: ");
    scanf("%d", &n);

    for (int i = 5; i < n; i += 5) {
        if (i % 3 != 0 && i % 7 != 0) {
            sum += i;
        }
    }

    printf("Sum: %d\n", sum);
    return 0;
}
