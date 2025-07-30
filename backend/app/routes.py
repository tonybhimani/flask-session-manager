import os
import uuid # uuid for unique filenames
from flask import Blueprint, jsonify, request, abort, current_app
from app.models import User, Session
from app.extensions import db, bcrypt, jwt, limiter
from firebase_admin import messaging
from datetime import datetime, timedelta, timezone
from flask_jwt_extended import (
    create_access_token,
    jwt_required,
    get_jwt_identity,
    create_refresh_token,
    get_jwt, # JWT CLAIMS IN v4+
    decode_token
)
from sqlalchemy import or_ # Import or_ for OR conditions in queries

# Create a Blueprint named 'api'
bp = Blueprint('api', __name__)

# Helper function to serialize User objects to a dictionary
def user_to_dict(user):
    return {
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'first_name': user.first_name,
        'last_name': user.last_name,
        'phone_number': user.phone_number,
        'created_at': user.created_at.isoformat(), # Convert datetime to ISO format string
        'updated_at': user.updated_at.isoformat()
    }

# --- Helper function to serialize Session objects to a dictionary ---
def session_to_dict(session):
    return {
        'id': session.id,
        'user_id': session.user_id,
        'refresh_token': session.refresh_token,
        'device_id': session.device_id,
        'fcm_token': session.fcm_token,
        'ip_address': session.ip_address,
        'user_agent': session.user_agent,
        'created_at': session.created_at.isoformat(),
        'expires_at': session.expires_at.isoformat(),
        'is_revoked':session.is_revoked
    }


# --- SESSION ENDPOINTS ---

@bp.route('/sessions', methods=['GET'])
# @limiter.limit("60 per hour")
def get_sessions():
    # In a real app, protect this for admin only access
    sessions = Session.query.all()
    sessions_data = [session_to_dict(session) for session in sessions]
    return jsonify(sessions_data)

@bp.route('/sessions/<int:session_id>', methods=['GET'])
# @limiter.limit("60 per hour")
def get_session(session_id):
    # In a real app, protect this for admin only access
    session = Session.query.get_or_404(session_id)
    return jsonify(session_to_dict(session))


# --- AUTHENTICATION ENDPOINTS ---

@bp.route('/register', methods=['POST'])
@limiter.limit("5 per hour") # Stricter limit for registration to prevent spam/abuse
def register():
    data = request.get_json()

    if not data or not data.get('username') or not data.get('email') or not data.get('password'):
        return jsonify({'message': 'Missing required fields: username, email, and password'}), 400

    if User.query.filter_by(username=data['username']).first():
        return jsonify({'message': 'Username already exists'}), 409
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'message': 'Email already registered'}), 409

    hashed_password = bcrypt.generate_password_hash(data['password']).decode('utf-8')

    new_user = User(
        username=data['username'],
        email=data['email'],
        password_hash=hashed_password,
        first_name=data.get('first_name'),
        last_name=data.get('last_name'),
        phone_number=data.get('phone_number')
    )

    db.session.add(new_user)
    db.session.commit()

    # Create and store refresh token immediately
    access_token = create_access_token(identity=str(new_user.id))
    refresh_token = create_refresh_token(identity=str(new_user.id))

    # Decode the refresh token to extract its unique ID (JTI)
    refresh_token_payload = decode_token(refresh_token)
    refresh_token_jti = refresh_token_payload['jti']

    # Use datetime.now(timezone.utc) for current UTC time
    refresh_token_expires = datetime.now(timezone.utc) + current_app.config['JWT_REFRESH_TOKEN_EXPIRES']

    new_session = Session(
        user_id=new_user.id,
        refresh_token=refresh_token_jti, # Store the JTI here
        device_id=data['device_id'], # Use the device_id from the registration request
        fcm_token=data['fcm_token'], # Use FCM token from the registration request
        ip_address=request.remote_addr,
        user_agent=request.headers.get('User-Agent'),
        expires_at=refresh_token_expires,
        is_revoked=False
    )
    db.session.add(new_session)
    db.session.commit()

    # Return both tokens and user info upon successful registration
    access_token = create_access_token(identity=str(new_user.id))
    return jsonify(access_token=access_token, refresh_token=refresh_token, user=user_to_dict(new_user)), 201

@bp.route('/login', methods=['POST'])
@limiter.limit("10 per minute") # Stricter limit for login to prevent brute-force attacks
def login():
    username = request.json.get('username', None) # Can also use email
    password = request.json.get('password', None)
    device_id = request.json.get('device_id', None)
    fcm_token = request.json.get('fcm_token', None)

    if not username or not password or not device_id:
        return jsonify({"message": "Missing username, password, or device_id"}), 400

    user = User.query.filter_by(username=username).first()
    if not user and '@' in username: # Also try to login with email if username not found
        user = User.query.filter_by(email=username).first()

    if not user or not bcrypt.check_password_hash(user.password_hash, password):
        # Return a generic error message for security, don't tell if username or password was wrong
        return jsonify({"message": "Bad username or password"}), 401 # 401 Unauthorized

    # Invalidate any existing session for this user on this specific device_id
    # This ensures only one active session per device_id at a time for the user
    existing_session = Session.query.filter_by(user_id=user.id, device_id=device_id, is_revoked=False).first()
    if existing_session:
        existing_session.is_revoked = True # Mark as revoked
        db.session.add(existing_session) # Stage for update
        # You could also delete it: db.session.delete(existing_session)

    # Create ACCESS and REFRESH tokens
    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    # Decode the refresh token to extract its unique ID (JTI)
    refresh_token_payload = decode_token(refresh_token)
    refresh_token_jti = refresh_token_payload['jti']

    # Store the refresh token in the database
    # Assuming refresh tokens expire in 30 days, adjust as needed in your JWT config
	# Use datetime.now(timezone.utc) for current UTC time
    refresh_token_expires = datetime.now(timezone.utc) + current_app.config['JWT_REFRESH_TOKEN_EXPIRES']

    new_session = Session(
        user_id=user.id,
        refresh_token=refresh_token_jti,
        device_id=device_id,
        fcm_token=fcm_token,
        ip_address=request.remote_addr, # Get client IP
        user_agent=request.headers.get('User-Agent'), # Get user agent
        expires_at=refresh_token_expires,
        is_revoked=False
    )
    db.session.add(new_session)
    db.session.commit()

    # Return both tokens to the client and include user info on login as well
    return jsonify(access_token=access_token, refresh_token=refresh_token, user=user_to_dict(user)), 200

@bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True) # Requires a valid refresh token
@limiter.limit("5 per minute") # Limit refresh attempts
def refresh():
    current_user_id = int(get_jwt_identity())
    current_refresh_token_jti = get_jwt()['jti'] # Get the JTI of the refresh token from the current request

    # Check if this refresh token is in our database and is not revoked
    session = Session.query.filter_by(
        user_id=current_user_id,
        refresh_token=current_refresh_token_jti, # Compare with the stored JTI
        is_revoked=False
    ).first()

    if not session:
        return jsonify({"message": "Refresh token is invalid or has been revoked."}), 401

    # Make session.expires_at timezone-aware before comparison
    # ASSUMPTION: expires_at is stored in UTC without timezone info
    # We "localize" it to UTC before comparison.
    now_utc = datetime.now(timezone.utc)
    session_expires_utc = session.expires_at.replace(tzinfo=timezone.utc) # Make it timezone-aware UTC

    if session_expires_utc < now_utc: # Compare now timezone-aware with timezone-aware
        session.is_revoked = True
        db.session.commit()
        return jsonify({"message": "Refresh token expired. Please log in again."}), 401

    # Create a new access token
    new_access_token = create_access_token(identity=str(current_user_id))
    return jsonify(access_token=new_access_token), 200

@bp.route('/logout', methods=['POST'])
@jwt_required() # Requires a valid access token to perform a logout
@limiter.limit("10 per hour")
def logout():
    current_user_id = int(get_jwt_identity())
    # The JWT being used to make this request will have a 'jti' (JWT ID) claim.
    # We should use this to identify the specific access token's associated refresh token to revoke it.
    # However, Flask-JWT-Extended doesn't directly link access token JTI to refresh token JTI.
    # The standard way to revoke a single session is to pass the refresh token itself,
    # or a device_id from the client. Let's assume the client sends its device_id.

    device_id = request.json.get('device_id', None) # Client sends its device_id
    if not device_id:
        return jsonify({"message": "Device ID is required for single device logout"}), 400

    # Find the session for this user and device_id and mark it as revoked
    session_to_revoke = Session.query.filter_by(
        user_id=current_user_id,
        device_id=device_id,
        is_revoked=False
    ).first()

    if session_to_revoke:
        session_to_revoke.is_revoked = True
        db.session.commit()
        return jsonify({"message": "Logged out successfully from this device"}), 200
    else:
        # Session not found or already revoked, or device_id mismatch
        return jsonify({"message": "No active session found for this device"}), 404

@bp.route('/logout_all_devices', methods=['POST'])
@jwt_required() # Requires a valid access token to perform this action
@limiter.limit("5 per hour") # Limit this critical security action
def logout_all_devices():
    current_user_id = int(get_jwt_identity())
    current_device_id = request.json.get('device_id') # Get device_id from the request body

    if not current_device_id:
        return jsonify({"message": "Device ID is required"}), 400

    try:
        # Find all active sessions for the current user
        all_user_sessions = Session.query.filter_by(
            user_id=current_user_id,
            is_revoked=False
        ).all()

        if not all_user_sessions:
            return jsonify({"message": "No active sessions found for this user"}), 200

        fcm_tokens_to_notify = []
        for session in all_user_sessions:
            # Mark all sessions as revoked
            session.is_revoked = True
            db.session.add(session) # Stage for update

            # Collect FCM tokens for other devices (excluding the current one)
            # and only if an FCM token exists for that session
            if session.device_id != current_device_id and session.fcm_token:
                fcm_tokens_to_notify.append(session.fcm_token)

        db.session.commit() # Commit all session revocations

        # Send FCM messages to other devices
        if fcm_tokens_to_notify:
            print(f"Attempting to send FCM logout messages to {len(fcm_tokens_to_notify)} devices.")
            # Create a multicast message for batch sending
            message = messaging.MulticastMessage(
                data={
                    'logout_command': 'true', # Simple flag for client to understand
                    'message': 'Your account has been logged out from all other devices for security reasons.',
                    'timestamp': str(datetime.now(timezone.utc).timestamp())
                },
                tokens=fcm_tokens_to_notify
            )

            try:
                # Use multicast for batch sending
                response = messaging.send_each_for_multicast(message)
                print(f"FCM Send Report: Success: {response.success_count}, Failure: {response.failure_count}")
                if response.failure_count > 0:
                    for resp in response.responses:
                        if not resp.success:
                            print(f"FCM send error: {resp.exception}")
            except Exception as e:
                print(f"Error sending FCM messages: {e}")
        else:
            print("No other devices with FCM tokens to notify.")

        return jsonify({"message": "Successfully logged out all devices."}), 200

    except Exception as e:
        db.session.rollback() # Rollback changes if any error occurs
        print(f"Error during logout_all_devices: {e}")
        return jsonify({"message": "An error occurred during logout."}), 500


# --- USER ENDPOINTS ---

@bp.route('/users', methods=['GET'])
# @limiter.limit("60 per hour")
def get_users():
    # In a real app, you might protect this or only allow admin access
    users = User.query.all()
    users_data = [user_to_dict(user) for user in users]
    return jsonify(users_data)

@bp.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = User.query.get_or_404(user_id)
    return jsonify(user_to_dict(user))

@bp.route('/user', methods=['GET'])
@jwt_required() # Requires a valid JWT
@limiter.limit("60 per hour") # Limit fetching current user details
def get_current_user():
    current_user_id = int(get_jwt_identity()) # Get the ID of the logged-in user
    user = User.query.get_or_404(current_user_id) # Fetch the user from the database
    return jsonify(user_to_dict(user)), 200 # Return the user data

@bp.route('/user', methods=['PUT'])
@jwt_required() # Requires a valid JWT
@limiter.limit("60 per hour") # Limit updates
def update_user():
    current_user_id = int(get_jwt_identity()) # Get the ID of the logged-in user
    user = User.query.get_or_404(current_user_id) # Fetch the user from the database

    data = request.get_json()
    if not data:
        return jsonify({'message': 'No data provided for update'}), 400

    # Update fields if they are provided in the request body
    if 'username' in data:
        # Check if new username is unique and not current user's username
        if data['username'] != user.username and User.query.filter_by(username=data['username']).first():
            return jsonify({'message': 'Username already taken'}), 409
        user.username = data['username']

    if 'email' in data:
        # Check if new email is unique and not current user's email
        if data['email'] != user.email and User.query.filter_by(email=data['email']).first():
            return jsonify({'message': 'Email already registered'}), 409
        user.email = data['email']

    if 'password' in data and data['password']: # Ensure password is not empty
        user.password_hash = bcrypt.generate_password_hash(data['password']).decode('utf-8')

    if 'first_name' in data:
        user.first_name = data['first_name']
    if 'last_name' in data:
        user.last_name = data['last_name']
    if 'phone_number' in data:
        user.phone_number = data['phone_number']

    user.updated_at = datetime.now(timezone.utc) # Update the timestamp

    db.session.commit()
    return jsonify(user_to_dict(user)), 200 # Return the updated user data

@bp.route('/user', methods=['DELETE'])
@jwt_required() # Requires a valid JWT
@limiter.limit("5 per hour") # Stricter limit for account deletion
def delete_user():
    current_user_id = int(get_jwt_identity())
    user = User.query.get_or_404(current_user_id)

    db.session.delete(user)
    db.session.commit()

    # After deleting the user, invalidate their token and log them out
    # For token-based authentication like JWT, invalidating the token often means
    # adding it to a blacklist or just letting it expire. However, in this case,
    # since the user account is gone, their token is effectively useless.

    return jsonify({'message': 'Account and all associated data deleted successfully'}), 204 # No Content