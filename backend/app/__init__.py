import os
from flask import Flask, send_from_directory
from app.config import Config
from app.extensions import db, migrate, bcrypt, cors, jwt, limiter

def create_app(config_class=Config):
    app = Flask(__name__)
    app.config.from_object(config_class)

    # Initialize Flask extensions
    db.init_app(app)
    migrate.init_app(app, db)
    bcrypt.init_app(app)
    cors.init_app(app) # Enable CORS for all routes by default
    jwt.init_app(app) # Initialize JWTManager with the app
    limiter.init_app(app) # Initialize Limiter with the app

    # Register blueprints
    from app.routes import bp as api_bp # Import the blueprint for routes.py
    app.register_blueprint(api_bp, url_prefix='/api') # All routes in api_bp are prefixed with /api

    return app