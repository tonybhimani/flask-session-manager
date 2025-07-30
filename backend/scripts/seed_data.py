from app import db
from app.models import User
from app.extensions import bcrypt # Hash passwords
from datetime import datetime, timedelta

def add_demo_data():
    print("Seeding database...")

    # Clear existing data (optional, useful for re-seeding)
    db.drop_all() # Drops all tables
    db.create_all() # Re-creates tables based on models (ensure you're okay with this during dev)
    # OR: if you just want to clear data without dropping tables:
    # User.query.delete()
    # Listing.query.delete()
    # Media.query.delete()
    # db.session.commit()

    # Create Users
    print("Creating users...")
    user1_password_hash = bcrypt.generate_password_hash("password123").decode('utf-8')
    user2_password_hash = bcrypt.generate_password_hash("securepass").decode('utf-8')
    user3_password_hash = bcrypt.generate_password_hash("devpass").decode('utf-8')

    user1 = User(
        username="prof.farwell",
        email="farwell@example.com",
        password_hash=user1_password_hash,
        first_name="Professor",
        last_name="Farwell",
        phone_number="555-123-4567"
    )
    user2 = User(
        username="jane.doe",
        email="jane@example.com",
        password_hash=user2_password_hash,
        first_name="Jane",
        last_name="Doe",
        phone_number="555-987-6543"
    )
    user3 = User(
        username="john.smith",
        email="john@example.com",
        password_hash=user3_password_hash,
        first_name="John",
        last_name="Smith",
        phone_number="555-111-2222"
    )
    db.session.add_all([user1, user2, user3])
    db.session.commit()
    print(f"Added {User.query.count()} users.")

    print("Database seeding complete!")