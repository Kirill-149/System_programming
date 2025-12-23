#!/bin/bash
echo "=== Сборка проекта Морской бой ==="
echo ""

echo "1. Компиляция сервера..."
fasm server.asm server.o
if [ $? -eq 0 ]; then
    ld server.o -o server
    echo "   ✓ Сервер скомпилирован"
    chmod +x server
    echo "   Исполняемый файл: ./server"
else
    echo "   ✗ Ошибка компиляции сервера"
    exit 1
fi

echo ""
echo "2. Компиляция клиента..."
fasm client.asm client.o
if [ $? -eq 0 ]; then
    ld client.o -o client
    echo "   ✓ Клиент скомпилирован"
    chmod +x client
    echo "   Исполняемый файл: ./client"
else
    echo "   ✗ Ошибка компиляции клиента"
    exit 1
fi

echo ""
echo "=== ГОТОВО ==="
echo "Запуск:"
echo "1. В одном терминале: ./server"
echo "2. В другом терминале: ./client"
echo ""
echo "Правила:"
echo "- Сервер ходит первым"
echo "- Формат хода: A1, B5, J10 и т.д."
echo "- Результат: H (попадание) или M (промах)"
echo "- Для выхода: q"
echo ""
echo "Очередность ходов:"
echo "1. Сервер делает ход"
echo "2. Клиент получает ход и отправляет результат"
echo "3. Клиент делает ход"
echo "4. Сервер получает ход и отправляет результат"
echo "5. Повтор с п.1"
