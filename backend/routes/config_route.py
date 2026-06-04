from flask import Blueprint, request, jsonify
from database import query, execute
from auth_utils import require_admin

bp = Blueprint('config', __name__, url_prefix='/api/config')


@bp.get('/')
@require_admin
def get_config():
    rows = query('SELECT clave, valor, descripcion FROM configuracion')
    return jsonify({r['clave']: r['valor'] for r in rows})


@bp.put('/')
@require_admin
def update_config():
    data = request.get_json(silent=True) or {}
    for clave, valor in data.items():
        existe = query('SELECT clave FROM configuracion WHERE clave=%s', (clave,), fetchone=True)
        if existe:
            execute('UPDATE configuracion SET valor=%s WHERE clave=%s', (str(valor), clave))
        else:
            execute('INSERT INTO configuracion (clave, valor) VALUES (%s,%s)', (clave, str(valor)))
    return jsonify({'ok': True})
