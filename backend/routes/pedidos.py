from flask import Blueprint, request, jsonify
from database import query, execute, transaction
from auth_utils import require_auth, require_admin
from datetime import datetime, timedelta, date

bp = Blueprint('pedidos', __name__, url_prefix='/api/pedidos')


def _dias_modificacion():
    row = query("SELECT valor FROM configuracion WHERE clave='dias_modificacion'", fetchone=True)
    return int(row['valor']) if row else 15


def _items_de_pedido(pedido_id):
    return query(
        'SELECT * FROM pedido_items WHERE pedido_id = %s',
        (pedido_id,)
    )


def _pedido_completo(p):
    p['items'] = _items_de_pedido(p['id'])
    # Calcular si puede modificar
    dias = _dias_modificacion()
    try:
        fecha_obj = p['fecha'] if isinstance(p['fecha'], date) else datetime.strptime(str(p['fecha']), '%Y-%m-%d').date()
        limite = fecha_obj + timedelta(days=dias)
        p['puede_modificar'] = (
            p['estado'] in ('pending', 'en_progreso') and
            date.today() <= limite
        )
        p['fecha_limite_mod'] = limite.strftime('%d/%m/%Y')
        p['fecha'] = fecha_obj.strftime('%d/%m/%Y')
    except Exception:
        p['puede_modificar'] = False
    return p


# ── GET todos los pedidos (admin) ─────────────────────────────
@bp.get('/')
@require_admin
def get_all():
    pedidos = query(
        '''SELECT p.*, u.nombre AS user_nombre, u.concesionario
           FROM pedidos p JOIN usuarios u ON u.id = p.usuario_id
           ORDER BY p.creado_en DESC'''
    )
    return jsonify([_pedido_completo(p) for p in pedidos])


# ── GET pedidos por despachar ────────────────────────────────
@bp.get('/por-despachar')
@require_admin
def get_por_despachar():
    pedidos = query(
        '''SELECT p.*, u.nombre AS user_nombre, u.concesionario
           FROM pedidos p JOIN usuarios u ON u.id = p.usuario_id
           WHERE p.estado IN ('pending','en_progreso')
           ORDER BY p.creado_en DESC'''
    )
    return jsonify([_pedido_completo(p) for p in pedidos])


# ── GET pedidos despachados ──────────────────────────────────
@bp.get('/despachados')
@require_admin
def get_despachados():
    pedidos = query(
        '''SELECT p.*, u.nombre AS user_nombre, u.concesionario,
                  d.id AS despacho_id, d.fecha_despacho, d.observacion AS obs_despacho
           FROM pedidos p
           JOIN usuarios u   ON u.id  = p.usuario_id
           JOIN despachos d  ON d.pedido_id = p.id
           WHERE p.estado = 'despachado'
           ORDER BY p.creado_en DESC'''
    )
    return jsonify([_pedido_completo(p) for p in pedidos])


# ── GET pedidos de un usuario ────────────────────────────────
@bp.get('/mis-pedidos')
@require_auth
def get_mis_pedidos():
    pedidos = query(
        '''SELECT p.*, u.nombre AS user_nombre, u.concesionario
           FROM pedidos p JOIN usuarios u ON u.id = p.usuario_id
           WHERE p.usuario_id = %s
           ORDER BY p.creado_en DESC''',
        (request.user['id'],)
    )
    return jsonify([_pedido_completo(p) for p in pedidos])


# ── POST crear pedido ─────────────────────────────────────────
@bp.post('/')
@require_auth
def crear_pedido():
    data  = request.get_json(silent=True) or {}
    items = data.get('items', [])
    if not items:
        return jsonify({'error': 'El pedido no tiene ítems'}), 400

    total = sum(i['precio'] * i['cantidad'] for i in items)
    dias  = _dias_modificacion()
    hoy   = date.today()
    pedido_id = f"ORD-{int(datetime.now().timestamp()*1000)}"

    ops = [(
        '''INSERT INTO pedidos (id, usuario_id, concesionario, fecha, total, estado, fecha_limite_mod)
           VALUES (%s, %s, %s, %s, %s, 'pending', %s)''',
        (pedido_id, request.user['id'], request.user['conces'],
         hoy, total, hoy + timedelta(days=dias))
    )]

    for item in items:
        ops.append((
            '''INSERT INTO pedido_items
               (pedido_id, moto_id, moto_nombre, moto_cc, color_nombre, color_hex, cantidad, precio_unitario)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s)''',
            (pedido_id, item['id'], item['nombre'], item.get('cc',''),
             item.get('colorN','—'), item.get('colorH','#999'),
             item['cantidad'], item['precio'])
        ))

    # Descontar stock por color
    for item in items:
        ops.append((
            '''UPDATE colores_moto SET stock = GREATEST(0, stock - %s)
               WHERE moto_id = %s AND nombre = %s''',
            (item['cantidad'], item['id'], item.get('colorN',''))
        ))

    transaction(ops)
    return jsonify({'ok': True, 'pedido_id': pedido_id}), 201


# ── PUT cambiar estado ────────────────────────────────────────
@bp.put('/<pedido_id>/estado')
@require_admin
def cambiar_estado(pedido_id):
    data   = request.get_json(silent=True) or {}
    estado = data.get('estado')
    estados_validos = ('pending', 'en_progreso', 'despachado', 'rejected')
    if estado not in estados_validos:
        return jsonify({'error': f'Estado inválido. Válidos: {estados_validos}'}), 400

    pedido = query('SELECT estado FROM pedidos WHERE id=%s', (pedido_id,), fetchone=True)
    if not pedido:
        return jsonify({'error': 'Pedido no encontrado'}), 404

    transaction([
        ('UPDATE pedidos SET estado=%s WHERE id=%s', (estado, pedido_id)),
        ('''INSERT INTO pedido_historial (pedido_id, estado_anterior, estado_nuevo, usuario_id)
            VALUES (%s,%s,%s,%s)''',
         (pedido_id, pedido['estado'], estado, request.user['id']))
    ])
    return jsonify({'ok': True})


# ── PUT modificar pedido (cliente) ────────────────────────────
@bp.put('/<pedido_id>/modificar')
@require_auth
def modificar_pedido(pedido_id):
    pedido = query(
        'SELECT * FROM pedidos WHERE id=%s AND usuario_id=%s',
        (pedido_id, request.user['id']), fetchone=True
    )
    if not pedido:
        return jsonify({'error': 'Pedido no encontrado'}), 404

    if pedido['estado'] not in ('pending', 'en_progreso'):
        return jsonify({'error': 'Este pedido ya no se puede modificar'}), 400

    dias = _dias_modificacion()
    fecha_obj = pedido['fecha'] if isinstance(pedido['fecha'], date) else datetime.strptime(str(pedido['fecha']), '%Y-%m-%d').date()
    if date.today() > fecha_obj + timedelta(days=dias):
        return jsonify({'error': 'El plazo de modificación ha vencido'}), 400

    data  = request.get_json(silent=True) or {}
    items = data.get('items', [])
    if not items:
        return jsonify({'error': 'El pedido no puede quedar vacío'}), 400

    total = sum(i['precio'] * i['cantidad'] for i in items)
    ops   = [
        ('DELETE FROM pedido_items WHERE pedido_id=%s', (pedido_id,)),
        ('UPDATE pedidos SET total=%s, modificado=1, estado="pending" WHERE id=%s', (total, pedido_id))
    ]
    for item in items:
        ops.append((
            '''INSERT INTO pedido_items
               (pedido_id, moto_id, moto_nombre, moto_cc, color_nombre, color_hex, cantidad, precio_unitario)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s)''',
            (pedido_id, item['id'], item['nombre'], item.get('cc',''),
             item.get('colorN','—'), item.get('colorH','#999'),
             item['cantidad'], item['precio'])
        ))
    transaction(ops)
    return jsonify({'ok': True})


# ── DELETE pedido ─────────────────────────────────────────────
@bp.delete('/<pedido_id>')
@require_admin
def eliminar_pedido(pedido_id):
    execute('DELETE FROM pedidos WHERE id=%s', (pedido_id,))
    return jsonify({'ok': True})
