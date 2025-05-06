# Документация API и gRPC методов юридического приложения

Данная документация описывает все API-методы и gRPC-взаимодействия между сервисами для мобильного юридического приложения.

## Общая структура системы

Система состоит из следующих сервисов:

1. **user service** — управление пользователями, аутентификация, подписки
2. **chat service** — обработка сообщений, диалоги с AI
3. **doc service** — работа с документами и шаблонами
4. **AI service** — интеллектуальные функции, интеграция с DeepSeek

> Примечание: административная панель для юристов будет реализована отдельно на Flask-admin без REST API. 
> Для авторизация будут использоваться токены, полученные через auth service.

## HTTP API и WebSocket

Swagger files:

1. [user service](https://github.com/progerg/Lawly/blob/master/documentation/api/swagger-user-openapi.json)
2. [chat service](https://github.com/progerg/Lawly/blob/master/documentation/api/swagger-chat-openapi.json)
3. [doc service](https://github.com/progerg/Lawly/blob/master/documentation/api/swagger-doc-openapi.json)

Подробную документацию также можно посмотреть здесь
1. [user сервис docs](https://user-service.lawly.ru/docs)
2. [chat сервис docs](https://chat-service.lawly.ru/docs)
3. [document сервис docs](https://doc-service.lawly.ru/docs)

#### WebSocket
- соединение для получения новых сообщений в реальном времени

## gRPC методы (межсервисное взаимодействие)

- [Protobuf файлы](https://github.com/Lawly-code/protos)

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