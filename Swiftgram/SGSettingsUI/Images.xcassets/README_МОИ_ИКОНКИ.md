# Куда класть свои иконки (MQGram)

Замените файлы в этих папках своими картинками — приложение подхватит их автоматически.

## Шапка экрана MQGram

| Папка | Файл | Назначение |
|-------|------|------------|
| `MQGramSettings.imageset/` | **MQGramSettings.png** | Большая иконка в шапке экрана MQGram |

Рекомендуемый размер: около 80×80 pt (или 240×240 px для @3x).

---

## Вкладки раздела «Функции»

| Папка | Файл | Назначение |
|-------|------|------------|
| `MQGramTabAppearance.imageset/` | **MQGramTabAppearance.png** | Иконка «Оформление» |
| `MQGramTabSecurity.imageset/` | **MQGramTabSecurity.png** | Иконка «Приватность» |
| `MQGramTabPlugins.imageset/` | **MQGramTabPlugins.png** | Иконка «Твики» |
| `MQGramTabOther.imageset/` | **MQGramTabOther.png** | Иконка «Другие функции» |

Рекомендуемый размер для иконок в списке: 24×24 pt (72×72 px для @3x). Формат: PNG (можно и PDF в одной шкале).

---

## Другие ресурсы

- `MQGramVerifiedBadge.imageset/` — значок верификации (Galochka.png).
- `glePlugins/1.imageset/` — иконка по умолчанию для плагинов без своей иконки.
- `SwiftgramSettings.imageset/`, `SwiftgramPro.imageset/` — иконки пунктов меню настроек.

После замены файлов пересоберите приложение (Bazel).
