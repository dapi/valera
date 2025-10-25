# Documentation Maintenance Scripts

Данная директория содержит скрипты для автоматической проверки и поддержки качества документации.

## 📋 Доступные скрипты

### 1. **validate-links.sh**
Валидация внутренних ссылок в документации
```bash
./docs/scripts/validate-links.sh
```
**Проверяет:**
- Корректность относительных ссылок между .md файлами
- Соответствие структуры директорий

### 2. **check-product-constitution.sh**
Проверка соответствия Product Constitution
```bash
./docs/scripts/check-product-constitution.sh
```
**Проверяет:**
- Отсутствие запрещенных кнопок и команд
- Соблюдение dialogue-only принципа
- Наличие предупреждений в gem документации

### 3. **documentation-audit.sh**
Комплексный аудит документации
```bash
./docs/scripts/documentation-audit.sh
```
**Включает:**
- Валидацию ссылок
- Проверку Product Constitution
- Анализ структуры документации
- Метрики качества

## 🔄 Рекомендуемый порядок использования

### Перед commit изменений в документации:
```bash
# 1. Проверить Product Constitution
./docs/scripts/check-product-constitution.sh

# 2. Проверить ссылки
./docs/scripts/validate-links.sh

# 3. Запустить полный аудит (опционально)
./docs/scripts/documentation-audit.sh
```

### Регулярное обслуживание:
- **Еженедельно (по пятницам):** Lead Developer - полный аудит документации
```bash
# Полный аудит документации
./docs/scripts/documentation-audit.sh
```

### Перед релизами:
- **За день до релиза:** Product Owner - проверка критических файлов
```bash
# Проверить только Product Constitution и ключевые ссылки
./docs/scripts/check-product-constitution.sh
```

## 📊 Метрики качества

Скрипты проверяют следующие метрики:
- **Валидность ссылок:** 100% ссылок должны работать
- **Product Constitution compliance:** 0 нарушений
- **FLOW структура:** Равное количество User Stories и TDD документов
- **Полнота структуры:** Наличие всех обязательных директорий и файлов

## 🚨 Обнаруженные проблемы

При обнаружении проблем скрипты:
- Выводят детальный отчет об ошибках
- Предоставляют конкретные места для исправления
- Возвращают ненулевой exit code для автоматизации

## 🛠 Интеграция с CI

Для включения в CI/CD pipeline:
```yaml
- name: Documentation Quality Check
  run: |
    ./docs/scripts/documentation-audit.sh
```

---

**Создано:** 25.10.2025
**Автор:** Claude AI Agent
**Обновлено:** 25.10.2025