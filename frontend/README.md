### Frontend - Flutter

This is the frontend component of the push notification app. Built with Flutter 3.32.8, it interacts with a Flask backend via a RESTful API and demonstrates Firebase Cloud Messaging on supported platforms. The app runs on web and mobile (Chrome, Edge, Android, and iOS).

---

## 🧩 Features

- User authentication (register, login, logout)
- Token refresh and session persistence
- Push notification support via Firebase Cloud Messaging (FCM)
- Custom device tokens tied to user sessions
- Tokens and user data stored via SharedPreferences (mobile) and localStorage (web)
- In-app test screen to trigger and receive messages
- Simple UI with consistent green-accented color scheme
- Compatible with web and mobile (Chrome, Edge, Android, iOS)

---

## 📁 Project Structure

```
frontend/
├── lib/
│   ├── main.dart                # Entry point of the Flutter app
│   ├── platform/                # Platform-specific services
│   │   ├── service_worker/      # FCM service worker for web notifications
│   │   └── storage/             # Local storage handlers (SharedPreferences and localStorage)
│   ├── screens/                 # UI screens (Login, Register, Profile, etc.)
│   ├── services/                # REST API calls and auth token handling
│   ├── utils/
│   │   └── constants.dart       # Centralized app constants (e.g., API base URL)
├── assets/                      # Static assets (icons, images, branding)
├── pubspec.yaml                 # Project metadata and dependency configuration
└── README.md                    # This file
```

---

## 🧰 Development Environment

Built and tested using:

```java
Flutter 3.32.8 • channel stable • https://github.com/flutter/flutter.git
Framework • revision edada7c56e (5 days ago) • 2025-07-25 14:08:03 +0000
Engine • revision ef0cd00091 (6 days ago) • 2025-07-24 12:23:50 -0700
Tools • Dart 3.8.1 • DevTools 2.45.1
```

---

## 🚀 Setup

Make sure Flutter is installed and functioning properly by running:

```bash
flutter doctor
```

Then, fetch dependencies and launch the app:

```bash
flutter pub get
flutter run -d chrome            # You can also use edge, etc.
```

For Android, use either a physical device or emulator. To check available devices:

```bash
adb devices
```

Then run the app using the appropriate device ID:

```bash
flutter pub get
flutter run -d emulator-5554     # Example ID from adb devices output
```

> ⚠️ iOS is currently untested due to my lack of hardware availability.

To change the backend API base URL, update the following file:

```
lib/utils/constants.dart
```

This file contains platform-specific notes for setting local IP addresses during development. It also holds the VAPID key used for Firebase Cloud Messaging (FCM). You'll need to replace the placeholder with your actual public VAPID key, which can be found in your Firebase Console.

> Note: The backend's `run.py` is configured to listen on all interfaces via `0.0.0.0`, which helps when running the Flutter frontend on real devices during development.

---

## 🧪 Test Credentials

To quickly access the app, use the following seeded test account:

```bash
Username: prof.farwell
Password: password123
```

You can modify or remove this in `backend/scripts/seed_data.py`.
