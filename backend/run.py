import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

from app import create_app, db
from app.models import User, Session # Import models for Flask shell context

# Create application instance
app = create_app()

# For Flask-Migrate and allows 'flask shell' to interact with the models and database
@app.shell_context_processor
def make_shell_context():
    return {'db': db, 'User': User, 'Session': Session}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True) # debug=True for development