from flask import Blueprint, request, jsonify
from database import query, execute, transaction
from auth_utils import require_admin
from datetime import datetime

bp = Blueprint('despachos', __name__, url_prefix='/api/despachos')


# ── GET todos los despachos ───────────────────────────────────
@bp.get('/')
@require_admin
def get_all():
    despachos = query(
        '''SELECT d.*, u.nombre AS creado_por_nombre
           FROM despachos d
           JOIN usuarios u ON u.id = d.creado_por
           ORDER BY d.creado_en DESC'''
    )
    for d in despachos:
        d['items'] = query(
            'SELECT * FROM pedido_items WHERE pedido_id = %s',
            (d['pedido_id'],)
        )
        if d.get('fecha_despacho'):
            d['fecha_despacho'] = str(d['fecha_despacho'])
        if d.get('creado_en'):
            d['creado_en'] = str(d['creado_en'])
    return jsonify(despachos)


# ── POST crear despacho ───────────────────────────────────────
@bp.post('/')
@require_admin
def crear_despacho():
    data      = request.get_json(silent=True) or {}
    pedido_id = data.get('pedido_id', '').strip()
    fecha     = data.get('fecha')
    obs       = (data.get('observacion') or 'Sin observaciones').strip()

    if not pedido_id:
        return jsonify({'error': 'pedido_id requerido'}), 400
    if not fecha:
        return jsonify({'error': 'fecha requerida'}), 400

    pedido = query(
        'SELECT id, concesionario, estado FROM pedidos WHERE id=%s',
        (pedido_id,), fetchone=True
    )
    if not pedido:
        return jsonify({'error': 'Pedido no encontrado'}), 404

    desp_id = f"DSP-{int(datetime.now().timestamp()*1000)}"

    transaction([
        ('''INSERT INTO despachos (id, pedido_id, concesionario, fecha_despacho, observacion, creado_por)
            VALUES (%s,%s,%s,%s,%s,%s)''',
         (desp_id, pedido_id, pedido['concesionario'], fecha, obs, request.user['id'])),

        ("UPDATE pedidos SET estado='despachado' WHERE id=%s", (pedido_id,)),

        ('''INSERT INTO pedido_historial (pedido_id, estado_anterior, estado_nuevo, usuario_id, notas)
            VALUES (%s,%s,'despachado',%s,%s)''',
         (pedido_id, pedido['estado'], request.user['id'], f'Despacho: {desp_id}'))
    ])
    return jsonify({'ok': True, 'despacho_id': desp_id}), 201


# ── DELETE despacho ───────────────────────────────────────────
@bp.delete('/<desp_id>')
@require_admin
def eliminar_despacho(desp_id):
    existe = query('SELECT id FROM despachos WHERE id=%s', (desp_id,), fetchone=True)
    if not existe:
        return jsonify({'error': 'Despacho no encontrado'}), 404
    execute('DELETE FROM despachos WHERE id=%s', (desp_id,))
    return jsonify({'ok': True})
