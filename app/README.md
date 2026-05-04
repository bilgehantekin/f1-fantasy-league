# GridCall

GridCall is a Flutter mobile app for F1 race predictions, private leagues,
sprint weekends, joker questions, reminders, live pages, race results, and
season standings.

## Features

- Race and sprint predictions
- Private league creation and invite-code joining
- League-scoped standings and weekly summaries
- Joker questions and result scoring
- Race reminder notifications
- Profile stats, badges, and account deletion request flow
- Supabase-backed auth, RLS, migrations, and edge functions

## Tech Stack

- Flutter 3.41.8 and Dart 3.11.5
- Riverpod
- GoRouter
- Supabase
- Sentry
- flutter_local_notifications

## Local Setup

1. Install Flutter and the Android/iOS toolchains.
2. Install the Supabase CLI.
3. Start local Supabase from the repo root:

```sh
supabase start
```

4. Apply migrations and seed data as needed:

```sh
supabase db reset
```

5. Install app dependencies:

```sh
cd app
flutter pub get
```

6. Run the app with the required environment values:

```sh
flutter run \
  --dart-define=SUPABASE_URL=<your-url> \
  --dart-define=SUPABASE_ANON_KEY=<your-anon-key> \
  --dart-define=SENTRY_DSN=<optional-dsn>
```

## Common Commands

```sh
cd app
dart format --set-exit-if-changed .
flutter analyze
flutter test --coverage
```

From the repo root:

```sh
supabase test db
```

## Database Tests

The Supabase tests cover prediction lock invariants, scoring rules, league
scoping, and RLS behavior for authenticated/anonymous users.

```sh
supabase start
supabase test db
```

## Release Notes

- Android 13+ notification permission is requested at runtime.
- Reminder notification IDs are deterministic and stored for selective cancel.
- Prediction writes rely on Supabase RLS and lock triggers for final authority.
