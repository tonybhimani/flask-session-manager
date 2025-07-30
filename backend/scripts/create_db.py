# create_db.py
import os
import sys
#from dotenv import load_dotenv

# Load environment variables from .env file
#load_dotenv()

# Add your project's root directory to the Python path if necessary
# This helps with imports when running the script directly
# For example, if 'your_app_name' is a package in your project root:
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app, db # Replace 'your_app_name'
from app.models import User # Import all models here
from seed_data import add_demo_data # Import your seeding function

# Create an application instance
app = create_app() # Or your direct app instance

with app.app_context():
    # Delete existing database file if it exists, for a truly fresh start
    db_path = os.path.join(app.root_path, 'app.db') # Adjust 'app.db' if your db file has a different name
    if os.path.exists(db_path):
        os.remove(db_path)
        print(f"Existing database file '{db_path}' deleted.")

    # Create all tables defined in your models
    db.create_all()
    print("Database tables created successfully!")

    # Optionally add demo data
    if '--seed' in sys.argv or '-s' in sys.argv:
        add_demo_data()
    else:
        print("Skipping demo data population. Run with 'python create_db.py --seed' to include demo data.")

print("Database setup process complete.")