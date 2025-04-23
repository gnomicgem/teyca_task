# Расчет и подтверждение операции API

Серверное приложение на базе Sinatra с использованием базы данных SQLite и библиотеки Sequel. 
Предоставляет собой API для работы с операциями оплаты товаров, 
включая их создание и подтверждение с учетом бонусов, кешбэка и скидок.

## Установка и запуск

Клонируйте репозиторий:

```bash
   git clone https://github.com/gnomicgem/teyca_task.git
   cd teyca_task
```

Установите зависимости:

```bash
  bundle install
```

Запустите сервер:

```bash
ruby app.rb
```
По умолчанию сервер запустится на http://localhost:4567.

## Функциональность API

### Расчет скидок и бонусов за операцию

#### Request example

POST /operation

Headers: Content-Type: application/json

Body:

```
{
    "user_id": 1,
    "positions": [
        {
            "id": 1,
            "price": 100,
            "quantity": 3
        },
        {
            "id": 2,
            "price": 50,
            "quantity": 2
        },
        {
            "id": 3,
            "price": 40,
            "quantity": 1
        },
        {
            "id": 4,
            "price": 150,
            "quantity": 2
        }
    ]
}
```

#### Response example

Success (200):

```
{
    "status": 200,
    "user": {
        "id": 1,
        "template_id": 1,
        "name": "Иван",
        "bonus": 10000.0
    },
    "operation_id": 2,
    "summ": 734.0,
    "positions": [
        {
            "id": 1,
            "type": "default",
            "value": 0,
            "description": "Standard loyalty rules",
            "discount_percent": 0,
            "discount": 0.0
        },
        {
            "id": 2,
            "type": "cashback",
            "value": 10,
            "description": "Product cashback",
            "discount_percent": 0,
            "discount": 0.0
        },
        {
            "id": 3,
            "type": "discount",
            "value": 15,
            "description": "Product discount",
            "discount_percent": 15,
            "discount": 6.0
        },
        {
            "id": 4,
            "type": "noloyalty",
            "value": 0,
            "description": "No loyalty rules apply",
            "discount_percent": 0,
            "discount": 0.0
        }
    ],
    "discount": {
        "summ": 6.0,
        "value": 0.81%
    },
    "cashback": {
        "existed_summ": 10000.0,
        "allowed_summ": 434.0,
        "value": 4.28%,
        "will_add": 31.7
    }
}
```

400 Bad Request 

```
{"status":"error","message":"Invalid JSON format"}
```

404 Not Found

```
{"status":"error","message":"User not found"}
```

### Подтверждение операции

#### Request example

POST /submit

Headers: Content-Type: application/json

Body:

```
{
    "user_id": 1,
    "template_id": 1,
    "name": "Иван",
    "bonus": 10000,
    "operation_id": 2,
    "write_off": 434
}
```

#### Response example

Success:

```
{
    "status": 200,
    "message": "Данные успешно обработаны!",
    "operation": {
        "user_id": 1,
        "cashback": 18.58,
        "cashback_percent": "4.28%",
        "discount": 6.0,
        "discount_percent": "0.81%",
        "write_off": 150.0,
        "check_summ": 434.0
    }
}
```

400 Bad Request

```
{
    "status": "error",
    "message": "operation_id is required"
}
```

422 Unprocessable Content

```
{
    "status": "error",
    "message": "Not enough bonuses to write off, available: 434.0"
}
```
