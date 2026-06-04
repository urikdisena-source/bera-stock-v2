import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    DB_HOST            = os.getenv('DB_HOST', 'localhost')
    DB_PORT            = int(os.getenv('DB_PORT', 3306))
    DB_USER            = os.getenv('DB_USER', 'root')
    DB_PASSWORD        = os.getenv('DB_PASSWORD', '')
    DB_NAME            = os.getenv('DB_NAME', 'bera_stock')
    JWT_SECRET         = os.getenv('JWT_SECRET', 'bera_secret_key_2026')
    JWT_EXPIRES_HOURS  = int(os.getenv('JWT_EXPIRES_HOURS', 24))
    FLASK_PORT         = int(os.getenv('FLASK_PORT', 5000))
    FLASK_DEBUG        = os.getenv('FLASK_DEBUG', 'true').lower() == 'true'
