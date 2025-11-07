#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Объявления функций из ассемблера
extern void queue_init(void);
extern int queue_enqueue(long value);
extern long queue_dequeue(void);
extern void queue_fill_random(long count);
extern void queue_remove_even(void);
extern long queue_count_primes(void);
extern long queue_get_odds(long* buffer, long buffer_size);
extern long queue_size_func(void);
extern int queue_is_empty(void);

// Функция для демонстрации содержимого очереди
int print_queue_full() {
    long size = queue_size_func();
    printf("Очередь [размер: %ld]: ", size);

    if (size == 0) {
        printf("пуста\n");
        return 1;
    }

    // Временный массив для хранения элементов
    long* temp = malloc(size * sizeof(long));
    if (temp == NULL) {
        printf("Ошибка выделения памяти!\n");
        return 0;
    }

    // Извлекаем все элементы
    long successfully_dequeued = 0;
    for (long i = 0; i < size; i++) {
        long value = queue_dequeue();
        if (value != 0) {
            temp[successfully_dequeued++] = value;
            printf("%ld ", value);
        }
    }

    // Восстанавливаем очередь
    long restore_errors = 0;
    for (long i = 0; i < successfully_dequeued; i++) {
        if (!queue_enqueue(temp[i])) {
            restore_errors++;
            for (int retry = 0; retry < 3; retry++) {
                if (queue_enqueue(temp[i])) {
                    restore_errors--;
                    break;
                }
            }
        }
    }

    if (restore_errors > 0) {
        printf("\n[Ошибка: Не удалось восстановить %ld элементов!]", restore_errors);
        queue_init();
        for (long i = 0; i < successfully_dequeued - restore_errors; i++) {
            queue_enqueue(temp[i]);
        }
    }

    printf("\n");
    free(temp);
    return (restore_errors == 0);
}

// Функция для печати только нечетных чисел
void print_queue_odds() {
    long size = queue_size_func();
    printf("Нечетные числа: ");

    if (size == 0) {
        printf("нет\n");
        return;
    }

    long odds_buffer[1000];
    long odds_count = queue_get_odds(odds_buffer, 1000);

    if (odds_count == 0) {
        printf("нет");
    } else {
        for (long i = 0; i < odds_count; i++) {
            printf("%ld ", odds_buffer[i]);
        }
    }
    printf("[из %ld элементов]\n", size);
}

int main() {
    printf("=== Демонстрация работы очереди ===\n\n");

    // Инициализация очереди
    queue_init();
    printf("1. Инициализация очереди\n");
    print_queue_full();

    // Добавление элементов
    printf("\n2. Добавление элементов в конец:\n");
    for (long i = 1; i <= 5; i++) {
        queue_enqueue(i * 11);
    }
    print_queue_full();

    // Удаление из начала
    printf("\n3. Удаление из начала:\n");
    long removed = queue_dequeue();
    if (removed != 0) {
        printf("Удален: %ld\n", removed);
    }
    print_queue_full();

    // Заполнение случайными числами
    printf("\n4. Заполнение 10 случайными числами:\n");
    queue_fill_random(10);
    print_queue_full();

    // Подсчет простых чисел
    printf("\n5. Подсчет простых чисел в очереди:\n");
    long prime_count = queue_count_primes();
    printf("Количество простых чисел: %ld\n", prime_count);

    // Получение нечетных чисел
    printf("\n6. Получение списка нечетных чисел:\n");
    long odds_buffer[100];
    long odds_count = queue_get_odds(odds_buffer, 100);
    printf("Нечетные числа (%ld шт.): ", odds_count);
    for (long i = 0; i < odds_count; i++) {
        printf("%ld ", odds_buffer[i]);
    }
    printf("\n");

    // Удаление четных чисел
    printf("\n7. Удаление всех четных чисел:\n");
    printf("До удаления: ");
    print_queue_full();
    queue_remove_even();
    printf("После удаления: ");
    print_queue_full();

    // Очистка очереди
    printf("\n8. Очистка очереди:\n");
    while (!queue_is_empty()) {
        queue_dequeue();
    }
    printf("Очередь пуста: %s\n", queue_is_empty() ? "да" : "нет");

    return 0;
}
