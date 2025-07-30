from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_bcrypt import Bcrypt
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address

db = SQLAlchemy()
migrate = Migrate()
bcrypt = Bcrypt()
cors = CORS()
jwt = JWTManager()
limiter = Limiter(
    key_func=get_remote_address, # Identify the client (by IP address)
    default_limits=["200 per 15 minute"], # Set global default
    storage_uri="memory://" # Default storage, overridden by config.py
)