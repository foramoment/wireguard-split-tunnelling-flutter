---
description: Continue developing the WireGuard Flutter app - pick up where previous session left off
---

# Продолжение разработки WireGuard Client

Это **long-running agent проект** на основе паттерна из статьи Anthropic.

## Шаг 1: Изучи текущее состояние

Прочитай эти файлы в указанном порядке:

1. **claude-progress.txt** — лог всех предыдущих сессий, текущее состояние, известные проблемы
2. **feature_list.json** — список всех 75 фич со статусами (passes: true/false)
3. **app_spec.txt** — полная спецификация приложения

## Шаг 2: Проверь окружение

```bash
# Убедись что проект собирается
flutter pub get
flutter build windows

# Проверь git историю
git log --oneline -10
```

## Шаг 3: Выбери следующую фичу

В feature_list.json найди первую фичу где `"passes": false` с наименьшим приоритетом (priority: 1 > 2 > 3).

## Шаг 4: Реализуй фичу

1. Реализуй инкрементально
2. Тестируй после каждого изменения
3. Коммить часто с осмысленными сообщениями

## Шаг 5: Обнови статус

1. В feature_list.json измени `"passes": true` для завершённой фичи
2. Добавь новую сессию в claude-progress.txt
3. Закоммить изменения

## Важные правила

- ❌ НЕ пытайся сделать много фич за раз
- ❌ НЕ оставляй код в сломанном состоянии
- ❌ НЕ удаляй и не редактируй описания фич в feature_list.json
- ✅ Делай маленькие, фокусированные коммиты
- ✅ Обновляй claude-progress.txt перед завершением сессии
- ✅ Проверяй что flutter build windows работает

## Структура проекта

```
wg-flutter/
├── lib/
│   ├── main.dart              # Entry point
│   ├── app.dart               # App widget with Riverpod
│   ├── core/theme/            # Material 3 theming
│   ├── core/router/           # go_router navigation
│   ├── models/                # Data models (Tunnel, Peer, etc.)
│   ├── services/              # Storage services (Hive)
│   ├── providers/             # Riverpod providers
│   ├── screens/               # UI screens
│   ├── widgets/               # Reusable widgets
│   └── utils/                 # Utilities (config parser)
├── feature_list.json          # Source of truth for features
├── claude-progress.txt        # Session log
├── app_spec.txt               # App specification
└── prompts/                   # Agent prompts (reference)
```

## Быстрые команды

```bash
flutter pub get              # Install dependencies
flutter build windows        # Build for Windows
flutter run -d windows       # Run in debug mode
flutter test                 # Run tests
dart run build_runner build  # Generate JSON serialization
git log --oneline -10        # Recent commits
```
