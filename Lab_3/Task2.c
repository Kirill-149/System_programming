#include <stdio.h>
#include <stdlib.h>

long long parse_int(const char* str) {
    char* endptr;
    long long result = strtoll(str, &endptr, 10);

    if (*endptr != '\0') {
        fprintf(stderr, "Error: Division by zero or invalid number\n");
        exit(1);
    }

    return result;
}

long long calculate_expression(long long a, long long b, long long c) {
    if (b == 0) {
        fprintf(stderr, "Error: Division by zero or invalid number\n");
        exit(1);
    }

    return ((b - c) / b) + a;
}

int main(int argc, char* argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s a b c\n", argv[0]);
        return 1;
    }

    long long a = parse_int(argv[1]);
    long long b = parse_int(argv[2]);
    long long c = parse_int(argv[3]);

    long long result = calculate_expression(a, b, c);

    printf("Result: %lld\n", result);

    return 0;
}
