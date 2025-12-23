#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Объявления функций из ассемблера
extern void array_init(void);
extern int array_add(long value);
extern long array_remove_first(void);
extern void array_fill_random(long count);
extern void array_remove_even(void);
extern long array_count_primes(void);
extern long array_get_odds(long* buffer, long buffer_size);
extern long array_get_size(void);
extern int array_is_empty(void);

// Функция для печати содержимого массива
void print_array() {
    long size = array_get_size();
    printf("Массив [размер: %ld]: ", size);

    if (size == 0) {
        printf("пуст\n");
        return;
    }

    // Извлекаем все элементы, печатаем и сохраняем во временный массив
    long* temp = malloc(size * sizeof(long));
    if (temp == NULL) {
        printf("Ошибка выделения памяти!\n");
        return;
    }

    for (long i = 0; i < size; i++) {
        long value = array_remove_first();
        temp[i] = value;
        printf("%ld ", value);
    }

    // Восстанавливаем массив
    for (long i = 0; i < size; i++) {
        array_add(temp[i]);
    }

    free(temp);
    printf("\n");
}

int main() {
    printf("=== Демонстрация работы с динамическим массивом ===\n\n");

    // Инициализация массива
    array_init();
    printf("1. Инициализация динамического массива\n");
    print_array();

    // Добавление элементов
    printf("\n2. Добавление 5 элементов:\n");
    for (long i = 1; i <= 5; i++) {
        array_add(i * 11);
    }
    print_array();

    // Удаление первого элемента
    printf("\n3. Удаление первого элемента:\n");
    long removed = array_remove_first();
    printf("Удален: %ld\n", removed);
    print_array();

    // Заполнение случайными числами
    printf("\n4. Заполнение 10 случайными числами:\n");
    array_fill_random(10);
    print_array();

    // Подсчет простых чисел
    printf("\n5. Подсчет простых чисел в массиве:\n");
    long prime_count = array_count_primes();
    printf("Количество простых чисел: %ld\n", prime_count);

    // Получение нечетных чисел
    printf("\n6. Получение нечетных чисел:\n");
    long odds_buffer[100];
    long odds_count = array_get_odds(odds_buffer, 100);
    printf("Найдено нечетных чисел: %ld\n", odds_count);
    printf("Нечетные числа: ");
    for (long i = 0; i < odds_count; i++) {
        printf("%ld ", odds_buffer[i]);
    }
    printf("\n");

    // Удаление четных чисел
    printf("\n7. Удаление всех четных чисел:\n");
    printf("До удаления: ");
    print_array();
    array_remove_even();
    printf("После удаления: ");
    print_array();

    // Очистка массива
    printf("\n8. Очистка массива:\n");
    long cleared_count = 0;
    while (!array_is_empty()) {
        array_remove_first();
        cleared_count++;
    }
    printf("Очищено элементов: %ld\n", cleared_count);
    printf("Массив пуст: %s\n", array_is_empty() ? "да" : "нет");

    return 0;
}
