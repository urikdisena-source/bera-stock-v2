from flask import Blueprint, request, jsonify
from database import query, execute
from auth_utils import require_admin, hash_password

bp = Blueprint('usuarios', __name__, url_prefix='/api/usuarios')


# ── GET todos los usuarios ────────────────────────────────────
@bp.get('/')
@require_admin
def get_all():
    usuarios = query(
        'SELECT id, email, nombre, concesionario, rol, activo, creado_en, ultimo_acceso '
        'FROM usuarios ORDER BY id'
    )
    for u in usuarios:
        for f in ('creado_en', 'ultimo_acceso'):
            if u.get(f):
                u[f] = str(u[f])
    return jsonify(usuarios)


# ── POST crear usuario ────────────────────────────────────────
@bp.post('/')
@require_admin
def crear_usuario():
    data       = request.get_json(silent=True) or {}
    email      = (data.get('email') or '').strip().lower()
    nombre     = (data.get('nombre') or '').strip()
    concesionario = (data.get('concesionario') or '').strip()
    rol        = data.get('rol', 'viewer')
    password   = data.get('password', 'bera2025')

    if not email or not nombre or not concesionario:
        return jsonify({'error': 'email, nombre y concesionario son requeridos'}), 400

    if rol not in ('admin', 'vendedor', 'viewer'):
        return jsonify({'error': 'Rol inválido'}), 400

    existe = query('SELECT id FROM usuarios WHERE email=%s', (email,), fetchone=True)
    if existe:
        return jsonify({'error': 'El correo ya está registrado'}), 409

    pw_hash = hash_password(password)
    new_id  = execute(
        'INSERT INTO usuarios (email, nombre, concesionario, rol, password_hash) VALUES (%s,%s,%s,%s,%s)',
        (email, nombre, concesionario, rol, pw_hash)
    )
    return jsonify({'ok': True, 'id': new_id}), 201


# ── POST registrarse (cliente) ────────────────────────────────
@bp.post('/registro')
def registro():
    data          = request.get_json(silent=True) or {}
    email         = (data.get('email') or '').strip().lower()
    nombre        = (data.get('nombre') or '').strip()
    concesionario = (data.get('concesionario') or '').strip()
    password      = data.get('password', '')

    if not email or not nombre or not concesionario or not password:
        return jsonify({'error': 'Todos los campos son requeridos'}), 400

    if len(password) < 6:
        return jsonify({'error': 'La contraseña debe tener al menos 6 caracteres'}), 400

    existe = query('SELECT id FROM usuarios WHERE email=%s', (email,), fetchone=True)
    if existe:
        return jsonify({'error': 'El correo ya está registrado'}), 409

    pw_hash = hash_password(password)
    execute(
        'INSERT INTO usuarios (email, nombre, concesionario, rol, password_hash) VALUES (%s,%s,%s,"viewer",%s)',
        (email, nombre, concesionario, pw_hash)
    )
    return jsonify({'ok': True, 'mensaje': 'Cuenta creada. Inicia sesión.'}), 201


# ── PUT actualizar rol o concesionario ────────────────────────
@bp.put('/<int:uid>')
@require_admin
def update_usuario(uid):
    data   = request.get_json(silent=True) or {}
    fields, vals = [], []

    if 'rol' in data:
        if data['rol'] not in ('admin', 'vendedor', 'viewer'):
            return jsonify({'error': 'Rol inválido'}), 400
        fields.append('rol=%s'); vals.append(data['rol'])

    if 'concesionario' in data:
        fields.append('concesionario=%s'); vals.append(str(data['concesionario'])[:120])

    if 'activo' in data:
        fields.append('activo=%s'); vals.append(int(bool(data['activo'])))

    if not fields:
        return jsonify({'error': 'Sin campos para actualizar'}), 400

    vals.append(uid)
    execute(f"UPDATE usuarios SET {', '.join(fields)} WHERE id=%s", vals)
    return jsonify({'ok': True})


# ── DELETE usuario ─────────────────────────────────────────────
@bp.delete('/<int:uid>')
@require_admin
def eliminar_usuario(uid):
    if uid == request.user['id']:
        return jsonify({'error': 'No puedes eliminarte a ti mismo'}), 400
    execute('UPDATE usuarios SET activo=0 WHERE id=%s', (uid,))
    return jsonify({'ok': True})
