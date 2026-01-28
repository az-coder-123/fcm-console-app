# FCM Console App 🔧

**FCM Console** is a desktop-first Flutter admin tool for sending Firebase Cloud Messaging (FCM) messages using the HTTP v1 API. It is intended for administrative use (sending notifications) — it does NOT include client SDKs like `firebase_messaging` or `firebase_core`.

---

## 🎯 Purpose
- Manage multiple Firebase Service Account profiles (JSON files).
- Configure and fetch device tokens from Supabase (dynamic per-profile config).
- Compose and send notifications (single/multi-device or topic) via the FCM HTTP v1 API using service-account auth.
- Persist send history locally (SQLite via `sqflite_common_ffi`).

## 🚀 Quick Start
1. Install dependencies:

```bash
cd /path/to/fcm-console-app
flutter pub get
```

2. Run the app on macOS or Windows:

```bash
flutter run -d macos   # or -d windows
```

3. First steps inside the app:
- Import a Firebase Service Account JSON (Profiles → Import).
- Activate a profile (this authenticates the app for FCM).
- Configure Supabase (Settings → Supabase) with your URL + key and test the connection.
- Fetch tokens (Dashboard → Tokens) and select targets.
- Compose & send messages (Composer). View history in History.

## 🧩 Key Technologies
- Flutter (desktop: macOS & Windows)
- Riverpod for state management
- SQLite (sqflite_common_ffi) for local persistence
- flutter_secure_storage for secrets
- googleapis_auth for Service Account OAuth2
- supabase Dart client for fetching device tokens
- fluent_ui for desktop UI

## 🗂️ Project Structure (high level)
```
lib/
├─ core/        # constants, utils, models, db
├─ features/    # auth, settings, dashboard
├─ providers/   # Riverpod providers
└─ main.dart
```

## ✅ Notes & Constraints
- This app is an *admin* tool — do NOT include mobile/client Firebase SDKs.
- Service Account JSONs are stored securely using `flutter_secure_storage` (only when imported).
- Supabase credentials are stored per-profile and can be reset when switching profiles.
- Follow the repository's `AGENTS.md` guidelines for code style and development practices.

## 🛠️ Development Tips
- Lint & analyze:

```bash
flutter analyze
```

- Run unit or integration tests (add tests under `test/`):

```bash
flutter test
```

## 🤝 Contributing
Open issues or submit PRs with clear descriptions and tests. Keep changes focused and follow the repository conventions in `AGENTS.md` and `APP_SPEC.md`.

---

If you want a localized README (Vietnamese) or additional sections (developer workflow, architecture diagrams, CI), tell me which sections to add and I'll update it. Thank you! ✨
