# MQGram — промпт для ИИ, что доделать

Ты работаешь в репозитории `stuffinydev-hub/MQGram-`, ветка от текущего состояния после правок логотипов и соцсетей. Это iOS-клиент на базе Telegram/Swiftgram. Соблюдай стиль проекта, GLEGram-код помечай `// MARK: - GLEGram` / `// MARK: - End GLEGram`, не трогай секреты и не пушь в main.

## Уже сделано
- В `Swiftgram/SGSettingsUI/Images.xcassets/` заменены GLEGram/MQGram-иконки на пользовательский фиолетовый логотип MQGram из вложения.
- В `Swiftgram/SGSettingsUI/Sources/GLEGramSettingsController.swift` обновлены ссылки раздела “Ссылки”:
  - VPN-канал: `https://t.me/stivenvpn`
  - Владелец: `https://t.me/jutsodev`
  - Life-канал / чат: `https://t.me/jutsolife`
  - MQGram: `https://t.me/MQGram`

## 1. UI / настройки
1. Убрать вкладку/пункт AI, если он есть в текущей сборке.
2. Скрыть `Swiftgram Pro` из настроек.
3. Скрыть обычный пункт `Swiftgram` из настроек.
4. Добавить доступ к скрытому Swiftgram через long-press 2 секунды на кнопку “Вопросы о Telegram” (`Settings_FAQ`) в `PeerInfoSettingsItems.swift` / disclosure item node.
5. Проверить, что пункт MQGram/GLEGram остаётся видимым.

## 2. Sponsor modal при запуске
1. Добавить модальное окно при входе в приложение с кастомным дизайном, не копируя скриншот 1-в-1.
2. Текст должен рекламировать/вести на каналы пользователя: MQGram, VPN, Life.
3. Сделать кнопки: открыть MQGram, открыть VPN, закрыть.
4. Показывать аккуратно после готовности root controller в `AppDelegate.swift`; не ломать cold start и авторизацию.

## 3. Удалённые сообщения
1. Доделать AyuGram-style сохранение удалённых сообщений в namespace `1338`, если уже начато.
2. Когда собеседник удаляет сообщение, у пользователя MQGram должен остаться визуальный индикатор удаления как на макете: красная корзина/метка возле сообщения.
3. Проверить файлы/модули `SGDeletedMessages`, `ChatHistoryEntriesForView.swift`, `SGMessageTextBlock.swift`, context menu/edit history.

## 4. Обязательный закреплённый чат/канал
1. Для всех пользователей MQGram должен быть обязательный чат/канал MQGram.
2. Он должен быть закреплён.
3. Запретить unpin / unsubscribe / delete / leave для этого peer.
4. Разрешить только mute и mark as read.
5. Найти места: `ChatContextMenus.swift`, `ChatListNode.swift`, engine pin/archive operations.

## 5. Приватность: read receipts после действия
1. Добавить настройку “Прочитать после действий”.
2. Если включена: открытие чата не отправляет read receipt/две галочки.
3. Read receipt отправляется только после того, как пользователь сам отправил сообщение в этот чат.
4. Интеграционные точки: `ChatHistoryListNode.swift` (`applyMaxReadIndex`), `AccountContext.applyMaxReadIndex`, `ChatController.sendMessages`.

## 6. Исключения приватности
1. Добавить общий список исключений приватности.
2. Для выбранных пользователей не применять ghost/privacy функции: read receipts, typing/recording/upload statuses, online status hiding и т.п.
3. Переиспользовать существующий `selectivePrivacyPeersController` и storage pattern из `SGSimpleSettings.messageReadReceiptsSendToPeerIds`, но лучше завести отдельный ключ, чтобы не ломать текущую логику read receipts whitelist.

## 7. Сборка и PR
1. Локально проверить хотя бы Swift-синтаксис/доступные команды, не запускать macOS-only IPA build на Linux.
2. Создать PR.
3. Проверить GitHub Actions; IPA пользователь будет деплоить через Actions/Release и Sideloadly.
