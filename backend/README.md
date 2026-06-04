# BERA STOCK V2 — Backend Python/Flask

## Requisitos
- Python 3.10+
- MySQL 8+ corriendo localmente

---

## Instalación rápida

### 1. Instalar dependencias
```bash
cd "BERA STOCK V2/backend"
pip install -r requirements.txt
```

### 2. Configurar variables de entorno
```bash
# Copiar el archivo de ejemplo
copy .env.example .env

# Editar .env con tus credenciales de MySQL
```

### 3. Crear la base de datos
```bash
# Ejecutar el schema SQL en MySQL
mysql -u root -p < ../database.sql
```

### 4. Crear contraseña del admin
```python
# Ejecutar en Python para generar el hash de admin123
python -c "import bcrypt; print(bcrypt.hashpw(b'admin123', bcrypt.gensalt()).decode())"
# Copiar el resultado y actualizar en MySQL:
# UPDATE usuarios SET password_hash='RESULTADO' WHERE email='admin@bera.com';
```

### 5. Iniciar el servidor
```bash
python app.py
```
El servidor corre en: **http://localhost:5000**

---

## Endpoints de la API

| Método | Ruta | Descripción | Auth |
|--------|------|-------------|------|
| POST | `/api/auth/login` | Iniciar sesión | ❌ |
| POST | `/api/usuarios/registro` | Registrar concesionario | ❌ |
| GET | `/api/health` | Estado del servidor y DB | ❌ |
| GET | `/api/motos/` | Catálogo completo | ✅ |
| PUT | `/api/motos/:id` | Actualizar precio/activa | 👑 |
| PUT | `/api/motos/:id/colores/:cid` | Actualizar stock de color | 👑 |
| POST | `/api/motos/:id/colores` | Agregar color | 👑 |
| DELETE | `/api/motos/:id/colores/:cid` | Eliminar color | 👑 |
| GET | `/api/pedidos/` | Todos los pedidos | 👑 |
| GET | `/api/pedidos/mis-pedidos` | Pedidos del usuario | ✅ |
| GET | `/api/pedidos/por-despachar` | Pedidos pendientes | 👑 |
| GET | `/api/pedidos/despachados` | Pedidos despachados | 👑 |
| POST | `/api/pedidos/` | Crear pedido | ✅ |
| PUT | `/api/pedidos/:id/estado` | Cambiar estado | 👑 |
| PUT | `/api/pedidos/:id/modificar` | Modificar pedido | ✅ |
| DELETE | `/api/pedidos/:id` | Eliminar pedido | 👑 |
| GET | `/api/despachos/` | Todos los despachos | 👑 |
| POST | `/api/despachos/` | Crear despacho | 👑 |
| DELETE | `/api/despachos/:id` | Eliminar despacho | 👑 |
| GET | `/api/usuarios/` | Lista de usuarios | 👑 |
| POST | `/api/usuarios/` | Crear usuario | 👑 |
| PUT | `/api/usuarios/:id` | Actualizar usuario | 👑 |
| DELETE | `/api/usuarios/:id` | Desactivar usuario | 👑 |
| GET | `/api/config/` | Configuración | 👑 |
| PUT | `/api/config/` | Actualizar config | 👑 |

**✅ = Token JWT requerido**
**👑 = Token JWT + rol admin o vendedor**

---

## Estructura de archivos
```
backend/
├── app.py              ← Punto de entrada Flask
├── config.py           ← Variables de entorno
├── database.py         ← Conexión y helpers MySQL
├── auth_utils.py       ← JWT + bcrypt
├── requirements.txt    ← Dependencias Python
├── .env                ← Tu configuración (NO subir a git)
├── .env.example        ← Plantilla de configuración
└── routes/
    ├── auth.py         ← Login
    ├── motos.py        ← Catálogo
    ├── pedidos.py      ← Pedidos
    ├── despachos.py    ← Despachos
    ├── usuarios.py     ← Usuarios
    └── config_route.py ← Configuración
```
