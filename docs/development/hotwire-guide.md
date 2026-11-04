# Hotwire Guide для AI-агентов

**Версия:** 1.0
**Дата:** 01.01.2026
**Тип документа:** HOW (Практическое руководство)
**Источник:** [hotwired.dev](https://hotwired.dev/)

---

## Что такое Hotwire?

Hotwire (HTML Over The Wire) — подход к созданию современных веб-приложений с минимальным JavaScript. Отправляет HTML вместо JSON по сети.

**Философия:** Сервер рендерит HTML → отправляет фрагменты → браузер обновляет DOM.

**Компоненты:**
- **Turbo** — 80% интерактивности без JS
- **Stimulus** — 20% для кастомной логики

---

## Turbo

### Turbo Drive

Автоматически перехватывает клики по ссылкам и отправки форм, превращая их в fetch-запросы.

**Как работает:**
1. Перехватывает клик/submit
2. Загружает страницу через fetch
3. Заменяет `<body>`, объединяет `<head>`
4. Обновляет URL через History API

**Управление:**

```html
<!-- Отключить Turbo Drive -->
<a href="/slow-page" data-turbo="false">Обычная ссылка</a>

<!-- Отключить prefetch -->
<a href="/page" data-turbo-prefetch="false">Без prefetch</a>

<!-- Подтверждение действия -->
<a href="/delete" data-turbo-method="delete"
   data-turbo-confirm="Удалить?">Удалить</a>

<!-- Глобальное отключение prefetch -->
<meta name="turbo-prefetch" content="false">
```

### Turbo Frames

Независимые секции страницы, обновляющиеся изолированно.

**Базовый синтаксис:**

```erb
<%# Rails helper %>
<%= turbo_frame_tag @todo do %>
  <p><%= @todo.description %></p>
  <%= link_to 'Edit', edit_todo_path(@todo) %>
<% end %>

<%# Или HTML напрямую %>
<turbo-frame id="message_1">
  <h1>Заголовок</h1>
  <a href="/messages/1/edit">Редактировать</a>
</turbo-frame>
```

**Ленивая загрузка:**

```html
<!-- Загружается при появлении на странице -->
<turbo-frame id="comments" src="/comments">
  <p>Загрузка...</p>
</turbo-frame>

<!-- Загружается когда становится видимым -->
<turbo-frame id="sidebar" src="/sidebar" loading="lazy">
  <p>Загрузка...</p>
</turbo-frame>
```

**Атрибуты:**
| Атрибут | Описание |
|---------|----------|
| `id` | Уникальный идентификатор (обязательный) |
| `src` | URL для автозагрузки |
| `loading="lazy"` | Отложенная загрузка до видимости |
| `target="_top"` | Навигация обновляет всю страницу |
| `data-turbo-action` | Управление History API |

**Навигация между фреймами:**

```html
<!-- Ссылка обновит другой фрейм -->
<a href="/messages" data-turbo-frame="messages_list">
  Показать сообщения
</a>
```

### Turbo Streams

Точечные обновления DOM через WebSocket или HTTP-ответы.

**8 действий:**

| Action | Описание |
|--------|----------|
| `append` | Добавить в конец элемента |
| `prepend` | Добавить в начало элемента |
| `replace` | Заменить весь элемент |
| `update` | Заменить содержимое (innerHTML) |
| `remove` | Удалить элемент |
| `before` | Вставить перед элементом |
| `after` | Вставить после элемента |
| `refresh` | Обновить страницу (morphing) |

**Синтаксис HTML:**

```html
<turbo-stream action="append" target="messages">
  <template>
    <div id="message_1">Новое сообщение</div>
  </template>
</turbo-stream>

<turbo-stream action="replace" target="message_1">
  <template>
    <div id="message_1">Обновлённое сообщение</div>
  </template>
</turbo-stream>

<turbo-stream action="remove" target="message_1">
</turbo-stream>
```

**Rails helpers (в .turbo_stream.slim/.erb):**

```slim
/ Заменить элемент
= turbo_stream.replace "chat_#{@chat.id}_header" do
  = render 'chats/header', chat: @chat

/ Добавить в конец
= turbo_stream.append "messages" do
  = render @message

/ Удалить
= turbo_stream.remove @message
```

### Turbo Broadcasts (Real-time через ActionCable)

**В модели:**

```ruby
class Message < ApplicationRecord
  # Автоматический broadcast refresh при изменениях
  broadcasts_refreshes_to :chat

  # Или более гранулярно
  broadcasts_to ->(message) { [message.chat, :messages] }
end
```

**В view (подписка):**

```erb
<%= turbo_stream_from @chat %>
<%= turbo_stream_from @chat, :messages %>
```

**Доступные методы broadcasts:**

| Метод | Описание |
|-------|----------|
| `broadcasts_refreshes` | Broadcast refresh при любых изменениях |
| `broadcasts_refreshes_to` | Broadcast refresh на конкретный stream |
| `broadcasts_to` | Broadcast create/update/destroy |
| `broadcast_append_to` | Ручной broadcast append |
| `broadcast_replace_to` | Ручной broadcast replace |
| `broadcast_remove_to` | Ручной broadcast remove |

---

## Stimulus

JavaScript-фреймворк для добавления интерактивности к HTML.

### Структура контроллера

```javascript
// app/javascript/controllers/hello_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // Определяем targets
  static targets = ["name", "output"]

  // Определяем values (реактивные данные)
  static values = {
    url: String,
    count: { type: Number, default: 0 }
  }

  // Lifecycle: при подключении к DOM
  connect() {
    console.log("Hello controller connected!")
  }

  // Lifecycle: при отключении от DOM
  disconnect() {
    // Cleanup
  }

  // Action methods
  greet() {
    this.outputTarget.textContent = `Hello, ${this.nameTarget.value}!`
  }

  // Callback при изменении value
  countValueChanged() {
    console.log(`Count is now ${this.countValue}`)
  }
}
```

### HTML-разметка

```html
<div data-controller="hello"
     data-hello-url-value="/api/greet"
     data-hello-count-value="5">

  <!-- Targets -->
  <input data-hello-target="name" type="text">
  <span data-hello-target="output"></span>

  <!-- Actions -->
  <button data-action="click->hello#greet">Greet</button>

  <!-- Shorthand для click (по умолчанию для button) -->
  <button data-action="hello#greet">Greet</button>

  <!-- Другие события -->
  <input data-action="input->hello#search keyup->hello#filter">
</div>
```

### Синтаксис data-action

```
event->controller#method
```

| Часть | Описание |
|-------|----------|
| `event` | DOM-событие (click, input, submit, keyup) |
| `controller` | Имя контроллера (snake_case) |
| `method` | Метод контроллера |

**События по умолчанию:**
- `<button>`, `<a>` → click
- `<input>`, `<textarea>` → input
- `<form>` → submit
- `<select>` → change

### Доступ к targets

```javascript
// Один элемент (первый найденный)
this.nameTarget        // → Element
this.hasNameTarget     // → Boolean

// Все элементы
this.nameTargets       // → Element[]
```

### Доступ к values

```javascript
// Чтение
this.urlValue          // → "/api/greet"
this.countValue        // → 5

// Запись (автоматически обновляет data-атрибут)
this.countValue = 10

// Callback при изменении
countValueChanged(value, previousValue) {
  // ...
}
```

### Полезные паттерны

**Подключение к Turbo-событиям:**

```javascript
connect() {
  this.element.addEventListener("turbo:submit-end", this.handleSubmit.bind(this))
}

disconnect() {
  this.element.removeEventListener("turbo:submit-end", this.handleSubmit.bind(this))
}

handleSubmit(event) {
  if (event.detail.success) {
    // Форма успешно отправлена
  }
}
```

**Работа со скроллом:**

```javascript
connect() {
  this.animationFrameId = requestAnimationFrame(() => {
    this.scrollToBottom()
  })
}

disconnect() {
  if (this.animationFrameId) {
    cancelAnimationFrame(this.animationFrameId)
  }
}
```

---

## Интеграция Turbo + Stimulus

### Типичный CRUD-сценарий

**Controller:**

```ruby
def create
  @message = @chat.messages.create!(message_params)

  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to @chat }
  end
end
```

**View (create.turbo_stream.slim):**

```slim
= turbo_stream.append "messages" do
  = render @message
```

**HTML с Stimulus:**

```slim
div data-controller="chat-scroll"
  #messages data-scroll-container="true"
    = render @chat.messages

  = form_with model: [@chat, Message.new],
              data: { controller: "chat-message-form",
                      action: "keydown.enter->chat-message-form#submit" } do |f|
    = f.text_field :text, data: { chat_message_form_target: "input" }
    = f.submit "Отправить"
```

---

## Примеры из проекта Super Valera

### Real-time обновления чатов

```ruby
# app/models/message.rb
class Message < ApplicationRecord
  # Автоматический broadcast при создании/обновлении
  broadcasts_refreshes_to :chat
end
```

### Turbo Stream ответ при takeover

```slim
/ app/views/tenants/chats/takeover.turbo_stream.slim
= turbo_stream.replace "chat_#{@chat.id}_header" do
  = render 'tenants/chats/chat_header', chat: @chat

= turbo_stream.replace "chat_#{@chat.id}_controls" do
  = render 'tenants/chats/chat_controls', chat: @chat
```

### Stimulus контроллер для скролла

```javascript
// app/javascript/controllers/chat_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.animationFrameId = requestAnimationFrame(() => {
      this.scrollToBottom()
    })
  }

  disconnect() {
    if (this.animationFrameId) {
      cancelAnimationFrame(this.animationFrameId)
    }
  }

  scrollToBottom() {
    const container = this.element.closest('[data-scroll-container]')
    if (container) {
      container.scrollTop = container.scrollHeight
    }
  }
}
```

---

## Turbo Events

**События навигации:**
- `turbo:before-visit` — перед переходом
- `turbo:visit` — начало перехода
- `turbo:load` — страница загружена

**События форм:**
- `turbo:submit-start` — начало отправки
- `turbo:submit-end` — конец отправки (success/error в detail)

**События frames:**
- `turbo:frame-load` — фрейм загружен
- `turbo:frame-render` — фрейм отрендерен

**События streams:**
- `turbo:before-stream-render` — перед рендером stream

---

## Рекомендации для проекта

1. **Используй `broadcasts_refreshes_to`** для real-time обновлений (Turbo 8 morphing)
2. **Создавай .turbo_stream.slim** для AJAX-ответов
3. **Stimulus** для клиентской логики (валидация, UI-поведение)
4. **Избегай inline JS** — всё через Stimulus контроллеры
5. **Именуй контроллеры** в snake_case (файл: `hello_world_controller.js` → `data-controller="hello-world"`)

---

## Ссылки

- [Turbo Handbook](https://turbo.hotwired.dev/handbook/introduction)
- [Stimulus Handbook](https://stimulus.hotwired.dev/handbook/introduction)
- [Hotrails Tutorial](https://www.hotrails.dev/)
- [turbo-rails gem](https://github.com/hotwired/turbo-rails)

---

**Версия:** 1.0
**Дата создания:** 01.01.2026
**Ответственный:** Development Team
