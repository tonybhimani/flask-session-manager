# Backend – Flask API

This is the backend component of the full-stack session management app. It provides a RESTful API for user authentication, session tracking, and Firebase Cloud Messaging integration, all built with Flask and SQLite.

---

## 🧩 Features

- User registration and login with password hashing
- JWT-based authentication with refresh token support
- Device-level session tracking
- Logout from single or all devices
- Firebase Cloud Messaging (FCM) integration for session events
- SQLite database using SQLAlchemy ORM
- Modular API design using Flask Blueprints
- CORS enabled for Flutter frontend communication

---

## 📁 Project Structure

```
backend/
├── app/
│   ├── __init__.py        # Initializes the Flask app and registers routes and extensions
│   ├── config.py          # Central configuration for environment, database, and secrets
│   ├── extensions.py      # Sets up Flask extensions (SQLAlchemy, JWT, FCM)
│   ├── models.py          # SQLAlchemy models for User and Session data
│   ├── routes.py          # API routes for auth, token refresh, and logout actions
├── scripts/
│   ├── create_db.py       # Script to initialize the database schema
│   ├── seed_data.py       # (Optional) Script to add sample data to the database
├── .env                   # (User-created) Environment variables like SECRET_KEY and DB path
├── requirements.txt       # List of Python dependencies
├── run.py                 # Entry point to launch the Flask development server
└── README.md              # This file
```

---

## 📦 Requirements

- Python 3.10+
- pip
- virtualenv (optional but recommended)

---

## 🚀 Setup

1. Clone the repository and navigate to the backend folder:

```bash
cd backend
```

2. (Optional) Create and activate a virtual environment:

```bash
python -m venv venv
source venv/bin/activate      # On Windows: venv\Scripts\activate
```

3. Install dependencies:

```bash
pip install -r requirements.txt
```

4. Create database (optional seed)

```bash
cd scripts
python create_db.py           # Create database
python create_db.py --seed    # Add demo data
```

5. Run the development server:

```bash
python run.py
```

The API will be available at `http://127.0.0.1:5000/api`.

---

## 🌱 Environment Variables

You can configure the secret keys and database URL settings in a `.env` file:

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
