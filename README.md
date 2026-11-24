# MyCarJournal

Flutter + Firebase застосунок для автомобіліста: журнал заправок, розрахунок витрати пального, облік подій обслуговування з фото та кілька авто в гаражі.

## Демо

- Web: https://mycarjournal-71dbe.web.app
- Firebase project: `mycarjournal-71dbe`

## Можливості

- Реєстрація з обов’язковим підтвердженням email. До підтвердження доступний лише екран верифікації та видалення акаунта.
- Вхід, відновлення пароля через лист на email, повторне надсилання листа підтвердження.
- Профіль: аватар з ініціалами, редагування імені, зміна пароля, вихід і видалення облікового запису.
- Унікальна іконка та splash screen.
- Кілька автомобілів у гаражі, вибір активного авто.
- Журнал заправок: дата, пробіг, літри, ціна за літр, повний бак, АЗС, нотатки.
- Розрахунок витрати методом «повний бак → повний бак»:
  `витрата = літри між повними баками / пробіг × 100`.
- Статистика: середня та остання витрата, ціна 1 км, витрати за місяцями, структура витрат на ТО.
- Журнал подій: категорії, вартість, пробіг, нотатки, нагадування про наступне ТО.
- До 5 фото на подію. Фото стискаються на клієнті та зберігаються разом із подією.
- Темна, світла або системна тема; активне авто зберігається в SharedPreferences.

## Технології

- Flutter 3.47 / Dart 3.13
- Firebase Authentication (Email/Password)
- Cloud Firestore
- flutter_riverpod, go_router, fl_chart, image_picker, image, intl, shared_preferences
- flutter_launcher_icons, flutter_native_splash

## Запуск

```powershell
flutter pub get
flutter run -d chrome
```

Конфігурація Firebase для web уже знаходиться в `lib/firebase_options.dart`.
Локальний backup конфігурації `firebase.txt` додано в `.gitignore`.

## Firebase

- Authentication → Email/Password.
- Email verification увімкнено; після реєстрації застосунок надсилає лист і блокує роботу до підтвердження.
- У Firebase Console перевірте шаблони листів (верифікація та відновлення пароля) і додайте домен hosting до Authorized domains.
- Firestore Database → production mode, регіон `europe-west`.
- Правила доступу — у `firestore.rules`: користувач бачить і змінює лише власне дерево `users/{uid}/...`.
- Cloud Storage не використовується.

Схема Firestore:

```text
users/{uid}/vehicles/{vehicleId}
users/{uid}/fuelEntries/{entryId}
users/{uid}/events/{eventId}
users/{uid}/events/{eventId}/photos/{photoId}
```

## Деплой

```powershell
firebase login
firebase deploy --only firestore:rules
flutter build web --release
firebase deploy --only hosting
```

## Структура проєкту

```text
lib/
  core/        тема, кольори, форматери, валідатори, типи авто, конфіг застосунку
  data/        репозиторії Firebase та сервіс стискання фото
  features/    auth, dashboard, fuel, events, stats, garage, profile, splash
  models/      Vehicle, FuelEntry, MaintenanceEvent, EventPhoto, FuelStats
  providers/   Riverpod-провайдери та auth-router
  shared/      спільні віджети, зокрема UserAvatar
  app.dart     MaterialApp.router, локалізація uk, теми
  router.dart  go_router з auth-redirect і перевіркою email
  main.dart    ініціалізація Firebase, SharedPreferences, intl
test/
  fuel_calculator_test.dart
  user_display_test.dart
```

## Перевірка

```powershell
flutter analyze
flutter test
```

## Ключові екрани

- Реєстрація — `lib/features/auth/register_screen.dart`.
- Вхід — `lib/features/auth/login_screen.dart`.
- Підтвердження email — `lib/features/auth/verify_email_screen.dart`.
- Відновлення пароля — `lib/features/auth/forgot_password_screen.dart`.
- Видалення облікового запису — `lib/features/auth/delete_account_screen.dart`.
- Профіль — `lib/features/profile/profile_screen.dart`.
