"""
BERA STOCK V2 — Backend Flask
Ejecutar: python app.py
"""
import os
from flask import Flask, jsonify, send_from_directory
from flask_cors import CORS
from config import Config

# Ruta al index.html (un nivel arriba del backend)
FRONTEND_DIR = os.path.join(os.path.dirname(__file__), '..')

# ── Importar blueprints ──────────────────────────────────────
from routes.auth         import bp as auth_bp
from routes.motos        import bp as motos_bp
from routes.pedidos      import bp as pedidos_bp
from routes.despachos    import bp as despachos_bp
from routes.usuarios     import bp as usuarios_bp
from routes.config_route import bp as config_bp

app = Flask(__name__)
app.config['JSON_SORT_KEYS'] = False

# Permitir peticiones desde el frontend (mismo equipo o red local)
CORS(app, resources={r'/api/*': {'origins': '*'}},
     supports_credentials=True)

# ── Registrar blueprints ─────────────────────────────────────
app.register_blueprint(auth_bp)
app.register_blueprint(motos_bp)
app.register_blueprint(pedidos_bp)
app.register_blueprint(despachos_bp)
app.register_blueprint(usuarios_bp)
app.register_blueprint(config_bp)


# ── Servir frontend ──────────────────────────────────────────
@app.get('/')
def frontend():
    return send_from_directory(FRONTEND_DIR, 'index.html')

@app.get('/LOGOS/<path:filename>')
def logos(filename):
    return send_from_directory(os.path.join(FRONTEND_DIR, 'LOGOS'), filename)

# ── Health check ─────────────────────────────────────────────
@app.get('/api/health')
def health():
    from database import query
    try:
        query('SELECT 1', fetchone=True)
        db_ok = True
    except Exception as e:
        db_ok = False
    return jsonify({
        'status': 'ok' if db_ok else 'error',
        'db':     'conectada' if db_ok else 'sin conexión',
        'version': '2.0'
    }), 200 if db_ok else 500


# ── Manejo de errores globales ────────────────────────────────
@app.errorhandler(404)
def not_found(e):
    return jsonify({'error': 'Ruta no encontrada'}), 404

@app.errorhandler(405)
def method_not_allowed(e):
    return jsonify({'error': 'Método no permitido'}), 405

@app.errorhandler(500)
def server_error(e):
    return jsonify({'error': 'Error interno del servidor', 'detalle': str(e)}), 500


if __name__ == '__main__':
    print(f"BERA STOCK V2 - Backend API corriendo en http://localhost:{Config.FLASK_PORT}/api/")
    app.run(
        host='0.0.0.0',
        port=Config.FLASK_PORT,
        debug=Config.FLASK_DEBUG
    )
