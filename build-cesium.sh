#!/bin/bash

# Скрипт для сборки Cesium и обновления файлов в проекте apex_living
# Используйте: ./build-cesium.sh

# Цветной вывод для лучшей читаемости
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Устанавливаем рабочие директории
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CESIUM_DIR="$BASEDIR/cesium"
APEX_DIR="$BASEDIR/apex_living"
CESIUM_BUILD_DIR="$CESIUM_DIR/Build/CesiumUnminified"
APEX_PUBLIC_DIR="$APEX_DIR/public/cesium"
APEX_STYLES_DIR="$APEX_DIR/styles"

echo -e "${BLUE}====== Сборка Cesium и обновление проекта apex_living ======${NC}"

# Шаг 1: Переходим в директорию Cesium и собираем проект
echo -e "${YELLOW}Шаг 1: Сборка Cesium...${NC}"
cd "$CESIUM_DIR" || { echo -e "${RED}Ошибка: Директория Cesium не найдена${NC}"; exit 1; }

# Проверяем установлены ли зависимости
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Установка зависимостей Cesium...${NC}"
    npm install || { echo -e "${RED}Ошибка установки зависимостей Cesium${NC}"; exit 1; }
fi

# Собираем проект
echo -e "${YELLOW}Запуск сборки Cesium...${NC}"
npm run build || { echo -e "${RED}Ошибка сборки Cesium${NC}"; exit 1; }

echo -e "${GREEN}Сборка Cesium завершена успешно!${NC}"

# Шаг 2: Создаем необходимые директории в проекте apex_living
echo -e "${YELLOW}Шаг 2: Создание директорий в проекте apex_living...${NC}"
mkdir -p "$APEX_PUBLIC_DIR/Workers"
mkdir -p "$APEX_PUBLIC_DIR/ThirdParty"
mkdir -p "$APEX_PUBLIC_DIR/Assets"
mkdir -p "$APEX_PUBLIC_DIR/Widgets"
mkdir -p "$APEX_STYLES_DIR"

echo -e "${GREEN}Директории созданы!${NC}"

# Шаг 3: Копируем файлы Cesium в проект apex_living
echo -e "${YELLOW}Шаг 3: Копирование файлов Cesium в проект apex_living...${NC}"

# Очистка предыдущих файлов
echo -e "${YELLOW}Очистка предыдущих файлов...${NC}"
rm -rf "$APEX_PUBLIC_DIR/Workers"/*
rm -rf "$APEX_PUBLIC_DIR/ThirdParty"/*
rm -rf "$APEX_PUBLIC_DIR/Assets"/*
rm -rf "$APEX_PUBLIC_DIR/Widgets"/*

# Копирование новых файлов
echo -e "${YELLOW}Копирование новых файлов...${NC}"
cp -r "$CESIUM_BUILD_DIR/Workers"/* "$APEX_PUBLIC_DIR/Workers"/ || { echo -e "${RED}Ошибка копирования Workers${NC}"; exit 1; }
cp -r "$CESIUM_BUILD_DIR/ThirdParty"/* "$APEX_PUBLIC_DIR/ThirdParty"/ || { echo -e "${RED}Ошибка копирования ThirdParty${NC}"; exit 1; }
cp -r "$CESIUM_BUILD_DIR/Assets"/* "$APEX_PUBLIC_DIR/Assets"/ || { echo -e "${RED}Ошибка копирования Assets${NC}"; exit 1; }
cp -r "$CESIUM_BUILD_DIR/Widgets"/* "$APEX_PUBLIC_DIR/Widgets"/ || { echo -e "${RED}Ошибка копирования Widgets${NC}"; exit 1; }

# Копирование CSS файла
cp "$CESIUM_BUILD_DIR/Widgets/widgets.css" "$APEX_STYLES_DIR/cesium-widgets.css" || { echo -e "${RED}Ошибка копирования CSS файла${NC}"; exit 1; }

echo -e "${GREEN}Файлы Cesium успешно скопированы в проект apex_living!${NC}"

# Шаг 4: Сборка проекта apex_living
echo -e "${YELLOW}Шаг 4: Сборка проекта apex_living...${NC}"
cd "$APEX_DIR" || { echo -e "${RED}Ошибка: Директория apex_living не найдена${NC}"; exit 1; }

# Проверяем установлены ли зависимости
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Установка зависимостей apex_living...${NC}"
    npm install || { echo -e "${RED}Ошибка установки зависимостей apex_living${NC}"; exit 1; }
fi

# Сборка проекта
echo -e "${YELLOW}Запуск сборки apex_living...${NC}"
npm run build || { echo -e "${RED}Ошибка сборки apex_living${NC}"; exit 1; }

echo -e "${GREEN}Сборка apex_living завершена успешно!${NC}"

# Вывод итогового результата
echo -e "${BLUE}====== Процесс сборки и обновления завершен успешно! ======${NC}"
echo -e "${GREEN}Теперь вы можете запустить проект с помощью:${NC}"
echo -e "${YELLOW}cd $APEX_DIR && npm run start${NC}"

exit 0 