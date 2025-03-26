# Документация API и gRPC методов юридического приложения

Данная документация описывает все API-методы и gRPC-взаимодействия между сервисами для мобильного юридического приложения.

## Общая структура системы

Система состоит из следующих сервисов:

1. **auth service** — управление пользователями, аутентификация, подписки
2. **chat service** — обработка сообщений, диалоги с AI
3. **doc service** — работа с документами и шаблонами
4. **AI service** — интеллектуальные функции, интеграция с DeepSeek

> Примечание: административная панель для юристов будет реализована отдельно на Flask-admin без REST API. 
> Для авторизация будут использоваться токены, полученные через auth service.

## HTTP API и WebSocket

Swagger files:

1. [auth service](https://github.com/progerg/Lawly/blob/master/documentation/api/swagger-auth-service.yml)
2. [chat service](https://github.com/progerg/Lawly/blob/master/documentation/api/swagger-chat-service.yml)
3. [doc service](https://github.com/progerg/Lawly/blob/master/documentation/api/swagger-doc-service.yml)

### auth service (HTTP)

#### Авторизация
- `POST /api/v1/auth/register` — регистрация нового пользователя
- `POST /api/v1/auth/login` — вход в систему
- `POST /api/v1/auth/logout` — выход из системы

#### Пользователь и подписки
- `GET /api/v1/auth/user` — получение информации о текущем пользователе
- `GET /api/v1/auth/user/subscription` — информация о подписке пользователя
- `POST /api/v1/auth/subscribe/{tariff_id}` — оформление подписки на тариф
- `GET /api/v1/auth/tariffs` — получение списка доступных тарифов
- `GET /api/v1/auth/privacy-policy` — получение текста политики конфиденциальности

### doc service (HTTP)

#### Шаблоны
- `GET /api/v1/docs/templates` — получение списка шаблонов
- `GET /api/v1/docs/templates/{template_id}` — информация о конкретном шаблоне
- `GET /api/v1/docs/templates/{template_id}/download` — скачивание документа по шаблону
- `POST /api/v1/docs/custom-template` — создание кастомного шаблона

#### Документы
- `POST /api/v1/docs/document-creation` — начало процесса создания документа
- `PUT /api/v1/docs/document-creation/{creation_id}` — обновление статуса создания документа
- `GET /api/v1/docs/documents` — получение списка базовых документов пользователя
- `GET /api/v1/docs/document-structures` — получение структуры всех базовых документов
- `POST /api/v1/docs/improve-text` — улучшение текста (юридический формат)

### chat service

#### HTTP API
- `GET /api/v1/chat/ai/messages` — получение сообщений из чата с AI с фильтрацией по датам
- `POST /api/v1/chat/ai/messages` — отправка сообщения AI-помощнику

#### WebSocket
- `ws://domain.com/api/v1/chat/ws` — соединение для получения новых сообщений в реальном времени
- События:
  - `new_message` — событие нового сообщения
  - `message_read` — событие прочтения сообщения
  - `typing` — событие набора сообщения

## gRPC методы (межсервисное взаимодействие)

- [Protobuf](https://github.com/progerg/Lawly/blob/master/documentation/api/grpc.proto)

### AI service

#### Методы для chat service
- `GenerateChatResponse` — получение ответа от AI на сообщение пользователя

#### Методы для doc service
- `ImproveText` — улучшение текста (перевод с обычного языка на юридический)
- `GenerateCustomTemplate` — генерация кастомного шаблона на основе описания ситуации

### doc service <-> AI service
- `GetDocumentStructure` — получение информации о структуре документа для AI
- `ImproveFieldText` — улучшение текста для конкретного поля документа

## Особенности реализации

### WebSocket для реал-тайм коммуникации
- Клиент устанавливает WebSocket соединение с chat service
- Сервер отправляет события о новых сообщениях, статусе прочтения и т.д.
- Формат события: `{"type": "new_message", "data": { ... содержимое сообщения ... }}`

### gRPC для межсервисного взаимодействия
- Используется для высокопроизводительной коммуникации между сервисами
- Поддерживает потоковую передачу данных и двунаправленную коммуникацию
- Сериализация данных через Protocol Buffers обеспечивает эффективность

### Firebase Cloud Messaging
- Используется для отправки push-уведомлений на мобильные устройства
- chat service и doc service отправляют HTTP-запросы к Firebase
- Уведомления о новых сообщениях и готовых документах

### Интеграция с DeepSeek
- AI service взаимодействует с моделью DeepSeek через HTTP/gRPC
- Используется для генерации ответов в чате и улучшения текста

### Безопасность
- Все HTTP API защищены JWT аутентификацией
- WebSocket соединения авторизуются через токены
- gRPC взаимодействия защищены mTLS (mutual TLS)

## Особенности реализации

### WebSockets
- Используются в chat service для обеспечения real-time коммуникации
- Клиент устанавливает соединение при входе в раздел чата
- Сервер отправляет уведомления о новых сообщениях

### Firebase Cloud Messaging
- Используется для отправки push-уведомлений на мобильные устройства
- chat service и doc service отправляют HTTP-запросы к Firebase для триггера уведомлений
- Уведомления отправляются о:
  - Новых сообщениях в чатах
  - Завершении генерации документов

### Интеграция с DeepSeek
- AI service взаимодействует с моделью DeepSeek через HTTP/gRPC
- Модель используется для:
  - Генерации ответов в чате
  - Улучшения текста
  - Генерации документов и шаблонов

### Безопасность
- Все HTTP API защищены JWT аутентификацией
- Проверка подписки для доступа к премиум-функциям

## gRPC методы

### AI service

#### Методы для chat service
- `GenerateChatResponse` — получение ответа от AI на сообщение пользователя

#### Методы для doc service
- `ImproveText` — улучшение текста (перевод с обычного языка на юридический)
- `GenerateDocument` — генерация документа на основе данных пользователя
- `GenerateCustomTemplate` — генерация кастомного шаблона на основе описания ситуации

### chat service

#### WebSocket методы
- `StreamMessages` — стрим для получения новых сообщений в реальном времени
- `MarkMessagesAsRead` — отправка статуса прочтения сообщений

### doc service <-> AI service

#### Методы для работы с документами
- `GetDocumentStructure` — получение информации о структуре документа для AI
- `SaveGeneratedDocument` — сохранение сгенерированного документа

## Особенности реализации

### WebSockets
- Используются в chat service для обеспечения real-time коммуникации
- Клиент устанавливает соединение при входе в раздел чата
- Сервер отправляет уведомления о новых сообщениях

### Firebase Cloud Messaging
- Используется для отправки push-уведомлений на мобильные устройства
- chat service и doc service отправляют HTTP-запросы к Firebase для триггера уведомлений
- Уведомления отправляются о:
  - Новых сообщениях в чатах
  - Завершении генерации документов
  - Ответах юриста на обращения

### Интеграция с DeepSeek
- AI service взаимодействует с моделью DeepSeek через HTTP/gRPC
- Модель используется для:
  - Генерации ответов в чате
  - Улучшения текста
  - Генерации документов и шаблонов

### Безопасность
- Все HTTP API защищены JWT аутентификацией
- Различные уровни доступа для обычных пользователей и юристов
- Проверка подписки для доступа к премиум-функциям


![API Schema](https://github.com/progerg/Lawly/blob/master/documentation/api/service-scheme.png)