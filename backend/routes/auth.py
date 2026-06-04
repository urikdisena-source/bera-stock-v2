from flask import Blueprint, request, jsonify
from database import query
from auth_utils import verify_password, generate_token

bp = Blueprint('auth', __name__, url_prefix='/api/auth')


@bp.post('/login')
def login():
    data = request.get_json(silent=True) or {}
    email    = (data.get('email') or '').strip().lower()
    password = (data.get('password') or '')

    if not email or not password:
        return jsonify({'error': 'Correo y contraseña requeridos'}), 400

    user = query(
        'SELECT id, email, nombre, concesionario, rol, password_hash, activo '
        'FROM usuarios WHERE email = %s',
        (email,), fetchone=True
    )

    if not user or not user['activo']:
        return jsonify({'error': 'Correo o contraseña incorrectos'}), 401

    if not verify_password(password, user['password_hash']):
        return jsonify({'error': 'Correo o contraseña incorrectos'}), 401

    # Actualizar último acceso
    from database import execute
    execute('UPDATE usuarios SET ultimo_acceso = NOW() WHERE id = %s', (user['id'],))

    token = generate_token(user)
    return jsonify({
        'token':  token,
        'user': {
            'id':           user['id'],
            'email':        user['email'],
            'nombre':       user['nombre'],
            'concesionario': user['concesionario'],
            'rol':          user['rol']
        }
    })
