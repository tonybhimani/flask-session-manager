from app.extensions import db
from datetime import datetime

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False) # For hashed passwords
    first_name = db.Column(db.String(50), nullable=True)
    last_name = db.Column(db.String(50), nullable=True)
    phone_number = db.Column(db.String(20), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationship to Session model - allows user.sessions to get all sessions for a user
    sessions = db.relationship('Session', backref='user', lazy=True, cascade='all, delete-orphan')

    def __repr__(self):
        return f'<User {self.username}>'

class Session(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    refresh_token = db.Column(db.String(255), unique=True, nullable=False, index=True) # Index for faster lookup
    device_id = db.Column(db.String(255), nullable=False) # Unique ID for the device/app installation
    fcm_token = db.Column(db.String(255), nullable=True) # Firebase Cloud Messaging token
    ip_address = db.Column(db.String(45), nullable=True) # Enough for IPv6
    user_agent = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    expires_at = db.Column(db.DateTime, nullable=False) # When this refresh token expires
    is_revoked = db.Column(db.Boolean, default=False, nullable=False) # Flag to mark token as invalid

    def __repr__(self):
        return f'<Session {self.id} for User {self.user_id}>'