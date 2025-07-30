# flask-session-manager

## 🔐 Full-Stack Auth + Session Management App

A full-stack demo app showcasing secure login, session persistence, and cross-device logout using Firebase Cloud Messaging. Built with Flask and Flutter.

This project demonstrates how to:

- Authenticate users using JWTs (access + refresh tokens)
- Persist sessions across app restarts using refresh tokens
- Revoke all active sessions for a user via a "Log Out All Devices" feature
- Handle forced logout across devices using Firebase Cloud Messaging (FCM)
- Tested on Android and Web. iOS is untested (no device/certificates), and FCM does not support Windows targets.

---

## 🧩 Features

### ✅ Backend (Python + Flask)

- Built with Flask, SQLAlchemy, and SQLite
- JWT-based authentication with access + refresh tokens
- Device-level session management using refresh token tracking
- Global logout via API endpoint + Firebase Cloud Messaging
- Secure password hashing with `bcrypt`
- Modular structure using Flask Blueprints
- Environment-based config with `.env` support
- Scripts for database setup and seeding
- Tested on Web and Android (no Windows FCM support)
- iOS supported, but not tested due to lack of Apple hardware

### ✅ Frontend (Flutter)

- Built with Flutter (tested on Web and Android)
- Firebase Cloud Messaging integration (foreground & background support)
- User authentication (register, login, logout)
- Token-based session persistence (refresh token auto-login)
- "Log Out All Devices" feature (triggers FCM + token revocation)
- Simple navigation flow:
  - Login and registration screens
  - Home screen (shown after successful auth)
  - Profile screen with "Log Out All Devices" button
- Minimal UI focused on session management and FCM handling

---

## 📁 Project Structure

```
flask-session-management/
├── backend/                   # Flask backend API for auth, token management, and FCM integration
├── frontend/                  # Flutter frontend app with login UI, session persistence, and FCM handling
├── FIREBASE_README.md         # Setup guide for Firebase Cloud Messaging on both backend and frontend
├── LICENSE                    # MIT license for the entire project
└── README.md                  # Main project overview and usage instructions
```

---

## 🚀 Getting Started

### 1. Backend Setup (Flask)

#### a. Create `.env` file in `/backend` folder:

```ini
SECRET_KEY='YOUR SECRET KEY'
DATABASE_URL='sqlite:///C:/YOUR_PATH/flutter-flask-marketplace/backend/app.db'
JWT_SECRET_KEY='YOUR JWT SECRET KEY'
FIREBASE_SERVICE_ACCOUNT_KEY_PATH='C:/YOUR_PATH/your-project-name-firebase-adminsdk-xxxxx-xxxxxx.json'

# ➤ You'll also need to download your Firebase Admin SDK JSON file from the Firebase Console.
#   This file contains sensitive credentials (e.g., API keys and service account certificates).
#   For security, do *not* commit it to version control or store it in the project directory—especially in production.
#   Even in development, treat this file with caution and keep it in a secure path outside the project tree.
```

Generate keys (inside Python shell):

```python
import secrets
print(secrets.token_hex(32))
```

#### b. Set up virtual environment and install dependencies

```bash
cd backend
python -m venv venv
source venv/bin/activate      # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

#### c. Create database (optional seed)

```bash
cd backend/scripts
python create_db.py           # Create database
python create_db.py --seed    # Add demo data
```

#### d. Run the API server

```bash
python run.py
```

Your API will be available at: `http://127.0.0.1:5000/api`

---

### 2. Frontend Setup (Flutter)

Ensure Flutter is installed and working (`flutter doctor`)

```bash
cd frontend
flutter pub get
flutter run -d chrome         # or edge or device/emulator id
```

To update the API base URL, open:
`frontend/lib/utils/constants.dart`

**Firebase Note:**
Some required Firebase files are not included in this repo. You must generate or download them from your Firebase Console. Setup instructions, including how to configure `firebase-messaging-sw.js` and add your **Web Push certificate (VAPID key)** to `constants.dart`, are detailed in the [FIREBASE_README.md](FIREBASE_README.md).

---

### 3. Firebase Project Setup

This project uses Firebase Cloud Messaging for push notifications. To fully enable FCM on both backend and frontend:

📄 Follow the steps in [FIREBASE_README.md](FIREBASE_README.md)

It covers:

- Creating a Firebase project
- Registering your web app
- Enabling FCM
- Downloading required files (like `firebase-messaging-sw.js`)
- Adding your VAPID key to `constants.dart`
- Backend configuration for sending push messages

---

## 🔌 API Endpoints

| Endpoint                  | Method | Description                                                      |
| ------------------------- | ------ | ---------------------------------------------------------------- |
| `/api/register`           | POST   | Creates a new user account                                       |
| `/api/login`              | POST   | Authenticates a user and returns JWT + refresh token             |
| `/api/refresh`            | POST   | Validates and rotates the refresh token                          |
| `/api/user`               | GET    | Returns info about the currently logged-in user                  |
| `/api/sessions`           | GET    | Lists all active sessions (for debugging; protect in production) |
| `/api/logout`             | POST   | Logs out the current session/device                              |
| `/api/logout_all_devices` | POST   | Logs out all devices and sends an FCM notification               |

> Full routing logic lives in: `/backend/app/routes.py`

---

## 📸 Demo Preview

### Log Out All Devices

![Log Out All Devices](https://raw.githubusercontent.com/tonybhimani/flask-session-manager/refs/heads/media/session_manager_demo.gif)

---

## 📌 Future Plans

There are no active plans to expand this project further. That said, I may revisit or build on it in the future. For now, it's meant as a functional example—feel free to explore or adapt it as you see fit.

---

## 🙌 Acknowledgments

This project was another hands-on exercise in combining Flutter with a Flask backend—this time with a focus on session management and integrating Firebase Cloud Messaging. It served as a practical way to explore authentication flows and notification handling in more depth.

---

## 📄 License

MIT License. Feel free to use or build on it. Attribution is appreciated but not required.
