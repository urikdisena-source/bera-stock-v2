import json
from flask import Blueprint, request, jsonify
from database import query, execute
from auth_utils import require_auth, require_admin

bp = Blueprint('motos', __name__, url_prefix='/api/motos')


def _moto_con_colores(moto_id):
    """Devuelve una moto con su lista de colores."""
    m = query(
        '''SELECT m.*, c.nombre AS cat_nombre, c.emoji
           FROM motos m JOIN categorias c ON c.id = m.categoria_id
           WHERE m.id = %s''',
        (moto_id,), fetchone=True
    )
    if not m:
        return None
    m['colores'] = query(
        'SELECT id, nombre, hex, activa, stock, orden '
        'FROM colores_moto WHERE moto_id = %s ORDER BY orden',
        (moto_id,)
    )
    # Parsear JSON
    for field in ('specs', 'extras'):
        if isinstance(m.get(field), str):
            m[field] = json.loads(m[field])
    return m


# ── GET todas las motos (catálogo) ──────────────────────────
@bp.get('/')
@require_auth
def get_motos():
    motos = query(
        '''SELECT m.id, m.nombre, m.cc, m.precio, m.categoria_id,
                  m.poliza, m.activa, m.forzar_agotado, m.specs, m.extras
           FROM motos m ORDER BY m.id'''
    )
    result = []
    for m in motos:
        for f in ('specs', 'extras'):
            if isinstance(m.get(f), str):
                m[f] = json.loads(m[f])
        m['colores'] = query(
            'SELECT id, nombre, hex, activa, stock, orden '
            'FROM colores_moto WHERE moto_id = %s ORDER BY orden',
            (m['id'],)
        )
        result.append(m)
    return jsonify(result)


# ── GET una moto ─────────────────────────────────────────────
@bp.get('/<int:moto_id>')
@require_auth
def get_moto(moto_id):
    m = _moto_con_colores(moto_id)
    if not m:
        return jsonify({'error': 'Moto no encontrada'}), 404
    return jsonify(m)


# ── PUT actualizar precio / activa / forzar_agotado ──────────
@bp.put('/<int:moto_id>')
@require_admin
def update_moto(moto_id):
    data = request.get_json(silent=True) or {}
    fields, vals = [], []

    if 'precio' in data:
        fields.append('precio = %s');        vals.append(float(data['precio']))
    if 'activa' in data:
        fields.append('activa = %s');        vals.append(int(bool(data['activa'])))
    if 'forzar_agotado' in data:
        fields.append('forzar_agotado = %s'); vals.append(int(bool(data['forzar_agotado'])))

    if not fields:
        return jsonify({'error': 'Sin campos para actualizar'}), 400

    vals.append(moto_id)
    execute(f"UPDATE motos SET {', '.join(fields)} WHERE id = %s", vals)
    return jsonify({'ok': True})


# ── PUT stock de un color ─────────────────────────────────────
@bp.put('/<int:moto_id>/colores/<int:color_id>')
@require_admin
def update_color(moto_id, color_id):
    data = request.get_json(silent=True) or {}
    fields, vals = [], []

    if 'stock' in data:
        fields.append('stock = %s');  vals.append(max(0, int(data['stock'])))
    if 'activa' in data:
        fields.append('activa = %s'); vals.append(int(bool(data['activa'])))
    if 'nombre' in data:
        fields.append('nombre = %s'); vals.append(str(data['nombre'])[:60])
    if 'hex' in data:
        fields.append('hex = %s');    vals.append(str(data['hex'])[:7])

    if not fields:
        return jsonify({'error': 'Sin campos'}), 400

    vals += [color_id, moto_id]
    execute(f"UPDATE colores_moto SET {', '.join(fields)} WHERE id = %s AND moto_id = %s", vals)
    return jsonify({'ok': True})


# ── POST agregar color ────────────────────────────────────────
@bp.post('/<int:moto_id>/colores')
@require_admin
def add_color(moto_id):
    data = request.get_json(silent=True) or {}
    nombre = (data.get('nombre') or '').strip()
    hex_   = (data.get('hex') or '#000000').strip()
    stock  = max(0, int(data.get('stock', 0)))

    if not nombre:
        return jsonify({'error': 'Nombre requerido'}), 400

    # Orden = máximo actual + 1
    row = query('SELECT COALESCE(MAX(orden),0)+1 AS o FROM colores_moto WHERE moto_id=%s',
                (moto_id,), fetchone=True)
    orden = row['o'] if row else 0

    new_id = execute(
        'INSERT INTO colores_moto (moto_id, nombre, hex, activa, stock, orden) VALUES (%s,%s,%s,1,%s,%s)',
        (moto_id, nombre, hex_, stock, orden)
    )
    return jsonify({'ok': True, 'id': new_id}), 201


# ── DELETE color ──────────────────────────────────────────────
@bp.delete('/<int:moto_id>/colores/<int:color_id>')
@require_admin
def delete_color(moto_id, color_id):
    # No permitir borrar si es el único
    count = query('SELECT COUNT(*) AS n FROM colores_moto WHERE moto_id=%s', (moto_id,), fetchone=True)
    if count and count['n'] <= 1:
        return jsonify({'error': 'Debe quedar al menos 1 color'}), 400

    execute('DELETE FROM colores_moto WHERE id=%s AND moto_id=%s', (color_id, moto_id))
    return jsonify({'ok': True})
