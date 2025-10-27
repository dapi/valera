# 📚 Документация Valera

**Обновлено:** 2025-01-27
**Проект:** AI-powered чат-бот для автоматизации автосервиса (Ruby on Rails 8.1)

## 🚨 С чего начать

### **Для AI-агентов:**
1. **🤖 [AI_NAVIGATION.md](AI_NAVIGATION.md)** - *ОБЯЗАТЕЛЬНО* - Оптимизированная навигация
2. **🔄 [FLOW.md](FLOW.md)** - Процесс разработки
3. **⚙️ [../CLAUDE.md](../CLAUDE.md)** - Технические инструкции

### **Для разработки:**
1. **📋 [product/constitution.md](product/constitution.md)** - Конституция продукта
2. **🔄 [FLOW.md](FLOW.md)** - Процесс разработки
3. **📋 [requirements/README.md](requirements/README.md)** - Работа с требованиями

## 📂 Структура документации

### 🏗️ **Продукт**
- **[📋 Конституция](product/constitution.md)** - требования к продукту
- **[📊 Примеры данных](product/data-examples/)** - Системные промпты, сообщения, прайс-листы
- **[📈 Бизнес-метрики](business-metrics.md)** - KPI и цели проекта

### 📋 **Требования**
- **[📖 Обзор](requirements/README.md)** - Управление требованиями
- **[🗺️ Roadmap](ROADMAP.md)** - Дорожная карта разработки
- **[🎭 User Stories](requirements/user-stories/)** - Пользовательские истории
- **[🏗️ Technical Specs](requirements/tsd/)** - Технические спецификации
- **[🔌 API](requirements/api/)** - API документация
- **[📋 Шаблоны](requirements/templates/)** - Шаблоны документов

### 🧠 **Доменная область**
- **[📖 Обзор](domain/README.md)** - Обзор домена
- **[📝 Терминология](domain/terminology.md)** - Объединенная терминология
- **[🏗️ Модели данных](domain/domain-models.md)** - Модели домена

### 💎 **Технические интеграции**
- **[🤖 ruby_llm](gems/ruby_llm/)** - AI/LLM интеграция
- **[📱 telegram-bot](gems/telegram-bot/)** - Telegram бот интеграция
- **[📝 Другие](gems/README.md)** - Прочие gem'ы

### 🛠 **Разработка**
- **[📖 Quick Start](development/README.md)** - Начало работы
- **[📝 YARD стандарты](development/YARD_DOCUMENTATION_STANDARDS.md)** - Документация кода
- **[🧪 Тестирование промптов](development/prompt-testing-guide.md)** - Оптимизация промптов

## 🎯 Ключевые принципы

### 🔄 **Основной процесс**
- **FLOW.md** - ЕДИНСТВЕННЫЙ источник правды по процессам
- **AI_NAVIGATION.md** - Оптимизированная навигация для AI-агентов

### 🤖 **Для AI-агентов**
**ОБЯЗАТЕЛЬНО:** Всегда начинать с **[AI_NAVIGATION.md](AI_NAVIGATION.md)**

### 📋 **Для разработчиков**
1. **Product Constitution** - фундаментальные требования
2. **FLOW.md** - процесс разработки
3. **requirements/README.md** - работа с требованиями

## 🔧 Поддержка документации (регламент)

### 📋 Кто и когда будет запускать скрипты:

**Еженедельно (по пятницам):**
- **Lead Developer** - полный аудит документации
```bash
./docs/scripts/documentation-audit.sh
```

**Перед релизами:**
- **Product Owner** - проверка критических файлов
```bash
./docs/scripts/check-product-constitution.sh
```

**Перед commit изменений:**
- **Разработчик** - быстрая проверка
```bash
./docs/scripts/validate-links.sh
```

Подробнее о скриптах см. [🛠 Scripts README](scripts/README.md)

