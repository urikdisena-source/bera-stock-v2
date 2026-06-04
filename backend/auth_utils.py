import jwt
import bcrypt
from datetime import datetime, timedelta, timezone
from functools import wraps
from flask import request, jsonify
from config import Config


def hash_password(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode(), hashed.encode())
    except Exception:
        return False


def generate_token(user: dict) -> str:
    payload = {
        'id':     user['id'],
        'email':  user['email'],
        'rol':    user['rol'],
        'nombre': user['nombre'],
        'conces': user.get('concesionario', ''),
        'exp':    datetime.now(timezone.utc) + timedelta(hours=Config.JWT_EXPIRES_HOURS)
    }
    return jwt.encode(payload, Config.JWT_SECRET, algorithm='HS256')


def decode_token(token: str) -> dict:
    return jwt.decode(token, Config.JWT_SECRET, algorithms=['HS256'])


def require_auth(f):
    """Decorador: exige token JWT válido en el header Authorization."""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.headers.get('Authorization', '')
        if not auth.startswith('Bearer '):
            return jsonify({'error': 'Token requerido'}), 401
        try:
            payload = decode_token(auth.split(' ', 1)[1])
            request.user = payload
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token expirado'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Token inválido'}), 401
        return f(*args, **kwargs)
    return decorated


def require_admin(f):
    """Decorador: exige rol admin o vendedor."""
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.headers.get('Authorization', '')
        if not auth.startswith('Bearer '):
            return jsonify({'error': 'Token requerido'}), 401
        try:
            payload = decode_token(auth.split(' ', 1)[1])
            if payload.get('rol') not in ('admin', 'vendedor'):
                return jsonify({'error': 'Sin permisos suficientes'}), 403
            request.user = payload
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token expirado'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Token inválido'}), 401
        return f(*args, **kwargs)
    return decorated
