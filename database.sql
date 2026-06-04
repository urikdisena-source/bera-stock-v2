-- ============================================================
--  BERA STOCK V2 — Esquema de Base de Datos
--  Compatible con: MySQL 8+ / MariaDB 10.5+
--  Generado: 2026
-- ============================================================

SET NAMES utf8mb4;
SET time_zone = '-04:00';   -- Venezuela (VET UTC-4)

-- ============================================================
--  CREAR BASE DE DATOS
-- ============================================================
CREATE DATABASE IF NOT EXISTS bera_stock
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE bera_stock;

-- ============================================================
--  1. CONFIGURACIÓN DEL SISTEMA
-- ============================================================
CREATE TABLE configuracion (
  clave            VARCHAR(60)   NOT NULL PRIMARY KEY,
  valor            TEXT          NOT NULL,
  descripcion      VARCHAR(255),
  actualizado_en   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT INTO configuracion (clave, valor, descripcion) VALUES
  ('dias_modificacion', '15',    'Días permitidos para que el cliente modifique un pedido'),
  ('camiones_capacidad','25',    'Cantidad de motos normales que caben en un camión');

-- ============================================================
--  2. USUARIOS / CONCESIONARIOS
-- ============================================================
CREATE TABLE usuarios (
  id               INT UNSIGNED  NOT NULL AUTO_INCREMENT PRIMARY KEY,
  email            VARCHAR(120)  NOT NULL UNIQUE,
  nombre           VARCHAR(120)  NOT NULL,
  concesionario    VARCHAR(120)  NOT NULL,
  rol              ENUM('admin','vendedor','viewer') NOT NULL DEFAULT 'viewer',
  password_hash    VARCHAR(255)  NOT NULL,          -- bcrypt hash en producción
  activo           TINYINT(1)    NOT NULL DEFAULT 1,
  creado_en        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ultimo_acceso    TIMESTAMP     NULL
);

-- Usuario administrador por defecto
INSERT INTO usuarios (email, nombre, concesionario, rol, password_hash) VALUES
  ('admin@bera.com', 'Admin Bera', 'Planta Bera Estado Aragua', 'admin', '$2b$10$HASH_AQUI');

-- ============================================================
--  3. CATÁLOGO DE MOTOS
-- ============================================================
CREATE TABLE categorias (
  id     VARCHAR(20)  NOT NULL PRIMARY KEY,   -- 'sincronicas', 'automaticas', etc.
  nombre VARCHAR(60)  NOT NULL,
  emoji  VARCHAR(10)
);

INSERT INTO categorias (id, nombre, emoji) VALUES
  ('sincronicas', 'Sincrónicas',      '🏍'),
  ('automaticas', 'Automáticas',      '🛵'),
  ('electrica',   'Eléctrica',        '⚡'),
  ('alta',        'Alta Cilindrada',  '🏁'),
  ('offroad',     'Off-Road',         '🌲'),
  ('carga',       'Carga',            '📦'),
  ('zontes',      'Zontes',           '⭐'),
  ('morini',      'Morini',           '🇮🇹'),
  ('segway',      'Segway',           '🚙');

CREATE TABLE motos (
  id               SMALLINT UNSIGNED NOT NULL PRIMARY KEY,
  nombre           VARCHAR(80)       NOT NULL,
  cc               VARCHAR(60)       NOT NULL,
  precio           DECIMAL(10,2)     NOT NULL,
  categoria_id     VARCHAR(20)       NOT NULL,
  poliza           TINYINT(1)        NOT NULL DEFAULT 0,
  activa           TINYINT(1)        NOT NULL DEFAULT 1,
  forzar_agotado   TINYINT(1)        NOT NULL DEFAULT 0,
  specs            JSON,                          -- especificaciones técnicas
  extras           JSON,                          -- características adicionales
  creado_en        TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en   TIMESTAMP         DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (categoria_id) REFERENCES categorias(id)
);

INSERT INTO motos (id, nombre, cc, precio, categoria_id, poliza, specs, extras) VALUES
  (1,  'Bera Bicycle',          'Eléctrica 350W',       660.00,  'electrica',   0, '{"Motor":"350W brushless","Batería":"48V/12AH","Vel. máx":"35 km/h","Frenos":"Disco"}',              '["Bluetooth integrado","Lector USB","Radio","40km de autonomía"]'),
  (2,  'BRF 150cc',             '150CC Sincrónico',     999.00,  'sincronicas', 1, '{"Motor":"150CC","Inicio":"Eléctrico/Pie","Vel. máx":"110 km/h","Tanque":"13.5L"}',                  '["13.5 HP","Torque 11Nm","Kit de herramientas","Escape con cámara"]'),
  (3,  'Socialista',            '150CC Sincrónico',    1030.00,  'sincronicas', 0, '{"Motor":"150CC","Potencia":"13.5 HP","Vel. máx":"130 km/h","Tanque":"13L"}',                          '["Puerto USB","Caliper doble pistón","Faro Halógeno"]'),
  (4,  'SBR 150',               '150CC Sincrónico',    1050.00,  'sincronicas', 1, '{"Motor":"150CC","Inicio":"Eléctrico/Pie","Vel. máx":"130 km/h","Tanque":"13L"}',                      '["Pantalla digital","Puerto USB","Faro LED"]'),
  (5,  'X1',                    '125CC Semi Auto',     1180.00,  'automaticas', 1, '{"Motor":"125CC Semi Auto","Inicio":"Eléctrico/Pie","Vel. máx":"110 km/h","Tanque":"3.5L"}',            '["Faros LED","Puerto USB","Caja 4 velocidades"]'),
  (6,  'Milan',                 '150CC Automático',    1220.00,  'automaticas', 1, '{"Motor":"150CC Auto","Inicio":"Eléctrico/Pie","Vel. máx":"110 km/h","Tanque":"6L"}',                   '["Faros LED","Pantalla digital","Maleta espaciosa"]'),
  (7,  'León',                  '150CC Sincrónico',    1150.00,  'sincronicas', 1, '{"Motor":"150CC","Inicio":"Eléctrico/Pie","Vel. máx":"137 km/h","Tanque":"13L"}',                       '["13HP","Faro LED","Amortiguadores graduables","Espaldar"]'),
  (8,  'Runner',                '150CC Automático',    1460.00,  'automaticas', 1, '{"Motor":"150CC Auto","Vel. máx":"110 km/h","Tanque":"6L","Frenos":"Disco"}',                           '["Faros LED","Pantalla digital","Maleta","Chaleco reflectivo"]'),
  (9,  'Tezú',                  'Eléctrico 3000W',     1390.00,  'electrica',   1, '{"Motor":"3000W","Batería":"60V 30Ah LifePo4","Vel. máx":"95 km/h","Rango":"60 km"}',                   '["BMS","Bluetooth","3 modos","Retroceso","Pantalla LED"]'),
  (10, 'BR200',                 '200CC Sincrónico',    1450.00,  'alta',        1, '{"Motor":"200CC","Vel. máx":"120 km/h","Tanque":"15L","Carga":"170kg"}',                                '["Estilo Scrambler","Amortiguadores a gas","Faro LED","USB Tipo C"]'),
  (11, 'Kavak',                 '150CC Off-Road',      1460.00,  'offroad',     1, '{"Motor":"150CC","Inicio":"Eléctrico/Pie","Vel. máx":"120 km/h","Tanque":"12L"}',                       '["13HP","Faros LED","Puerto USB","Tacómetro digital"]'),
  (12, 'BWS 180cc',             '180CC Automático',    1690.00,  'automaticas', 1, '{"Motor":"180CC Auto","Vel. máx":"110 km/h","Tanque":"8.5L","Frenos":"Disco CBS"}',                     '["Faros LED","Pantalla digital","Maleta","Defensas"]'),
  (13, 'Cobra',                 '150CC Automático',    1500.00,  'automaticas', 1, '{"Motor":"150CC Auto","Vel. máx":"90 km/h","Tanque":"5L","Frenos":"Disco"}',                            '["Faros LED","Maleta espaciosa","Posapies retráctiles"]'),
  (14, 'Antiking LE',           '200CC Sincrónico',    1390.00,  'alta',        1, '{"Motor":"200CC","Vel. máx":"120 km/h","Tanque":"15L","Estilo":"Café Racer"}',                           '["Puerto USB","Faro LED","Cauchos todo terreno"]'),
  (15, 'Optimus Electric',      'Eléctrico',           1720.00,  'electrica',   1, '{"Motor":"Eléctrico","Batería":"48V/30AH BMS","Vel. máx":"60 km/h","Frenos":"Disco"}',                  '["Pantalla 7\"","Alarma","Bluetooth","Audio","Garantía 12x12"]'),
  (16, 'GBR',                   '200CC Sincrónico',    1590.00,  'alta',        1, '{"Motor":"200CC","Vel. máx":"120 km/h","Tanque":"14L","Frenos":"Disco x2"}',                            '["Faros LED","Puerto USB","Rines 18\""]'),
  (17, 'DT BR200 RR',           '200CC Off-Road',      1950.00,  'offroad',     1, '{"Motor":"200CC","Vel. máx":"120 km/h","Tanque":"14L","Frenos":"Disco x2"}',                            '["Todo terreno","Puerto USB","Faro LED","Cauchos tacos"]'),
  (18, 'BRZ 250',               '250CC Sincrónico',    2190.00,  'alta',        1, '{"Motor":"250CC 4V","Inicio":"Eléctrico","Vel. máx":"140 km/h","Potencia":"25HP"}',                     '["6 velocidades","Refrigeración serpentín","Pantalla LED","Barras invertidas"]'),
  (19, 'GR 250',                '250CC Sincrónico',    2620.00,  'alta',        1, '{"Motor":"250CC 4V","Inicio":"Eléctrico","Vel. máx":"145 km/h","Potencia":"25HP"}',                     '["6 velocidades","Pantalla LED","Luces exploradoras","Cadena reforzada"]'),
  (20, 'Carguero',              '200CC Carga',         4190.00,  'carga',       1, '{"Motor":"200CC","Vel. máx":"60 km/h","Tanque":"20L","Carga":"800kg"}',                                 '["Reversa","Freno de mano","Cajón 130x200cm","Radio","Limpiabrisas"]'),
  (21, 'Tractor BRA 254',       'Diesel 25HP',        13200.00,  'carga',       0, '{"Motor":"Diesel 3cil 25HP","Tracción":"4WD","Tanque":"25L","Vel. máx":"37 km/h"}',                     '["9+9 velocidades","Tiro remolque","Techo","Filtro combustible"]'),
  (22, 'Zontes 200U',           '200CC ABS',           3350.00,  'zontes',      0, '{"Motor":"200CC","Inicio":"Eléctrico","Vel. máx":"130 km/h","Extras":"ABS+Inyección"}',                 '["2x USB","ABS Bosch","Pantalla LCD","Enfriamiento líquido"]'),
  (23, 'Zontes 350 T2',         '350CC 6V ABS',        5650.00,  'zontes',      1, '{"Motor":"350CC DOHC","Vel. máx":"160 km/h","Potencia":"39.44 CV","Frenos":"ABS"}',                     '["TFT Full Color","Keyless","Modos Eco/Sport","Nitrogen Shock"]'),
  (24, 'Zontes 368M',           '368CC CVT',           5900.00,  'zontes',      0, '{"Motor":"368CC CVT","Potencia":"39HP","Vel. máx":"—","Pantalla":"TFT 8\""}',                            '["Keyless","App Smartphones","USB A+C","Bluetooth"]'),
  (25, 'Zontes 703F',           '699CC Tricil.',      10000.00,  'zontes',      1, '{"Motor":"699CC","Potencia":"95HP","0-100":"~5 seg.","Pantalla":"TFT 6.75\""}',                          '["Tricilíndrico","Cámara HD","Quickshift","App"]'),
  (26, 'Morini X-Cape',         '650CC ADV',           5990.00,  'morini',      0, '{"Motor":"650CC","Inicio":"Eléctrico","Vel. máx":"180 km/h","Frenos":"Brembo ABS"}',                    '["Marzocchi front","KYB rear","TFT 7\"","6 velocidades"]'),
  (27, 'Morini STR',            '650CC Sport',         9000.00,  'morini',      0, '{"Motor":"650CC","Vel. máx":"170 km/h","Frenos":"Brembo ABS","Pantalla":"TFT 5\""}',                    '["KYB front+rear","Suspensión invertida","Bluetooth","6 velocidades"]'),
  (28, 'Morini SCR',            '650CC Scrambler',     9200.00,  'morini',      0, '{"Motor":"650CC","Vel. máx":"170 km/h","Frenos":"Brembo ABS","Pantalla":"TFT 5\""}',                    '["Bosch EFI","LED Full","Suspensión invertida","6 velocidades"]'),
  (29, 'Segway Snarler AT5L',   '499CC DOHC',         10200.00,  'segway',      1, '{"Motor":"499CC DOHC","Torque":"48 Nm","Sistema":"2WD/4WD","Carga":"270kg"}',                           '["App Smart-Moving","EBS","Dirección asistida","LED"]'),
  (30, 'Segway Fugleman UT10E', '1000CC 105HP',       24500.00,  'segway',      1, '{"Motor":"1000CC DOHC","Potencia":"105HP","Vel. máx":"90 km/h","Carga":"680kg"}',                       '["CVTech automático","6 asientos","TFT screen","4 discos"]'),
  (31, 'Segway Villain SX10W',  '1000CC Sport',       25500.00,  'segway',      1, '{"Motor":"1000CC DOHC","Torque":"93.5 Nm","Pantalla":"TFT 10.4\"","Carga":"250kg"}',                    '["Keyless","Techo corredizo","Puerta plástica","LED"]'),
  (32, 'Segway Snarler AT10W',  '1000CC 97HP',        16500.00,  'segway',      0, '{"Motor":"1000CC DOHC","Potencia":"97HP","Sistema":"2WD/4WD/Block","Frenos":"Hidráulicos 4R"}',          '["Bosch EFI","CVT","Rines alu 14\"","Smart-Moving App"]'),
  (33, 'Segway Super Villain',  '2.0 Turbo 235HP',   42500.00,  'segway',      0, '{"Motor":"2.0 Turbo GDi","Potencia":"235HP","0-100":"~5 seg.","Transmisión":"7AT"}',                     '["K-MAN 3.0 shocks","Beadlock 15\"","Pantalla 10.4\"","Cámara Full HD"]'),
  (34, 'Zontes 750',            '750CC Bicilíndrico',  7200.00,  'zontes',      0, '{"Motor":"750CC","Inicio":"Eléctrico","Vel. máx":"170 km/h","Pantalla":"TFT 7\""}',                     '["Sistema Keyless","USB A+C","Bluetooth","App Smartphones","Inyección Bosch"]');

-- ============================================================
--  4. COLORES POR MOTO (stock independiente por color)
-- ============================================================
CREATE TABLE colores_moto (
  id          INT UNSIGNED  NOT NULL AUTO_INCREMENT PRIMARY KEY,
  moto_id     SMALLINT UNSIGNED NOT NULL,
  nombre      VARCHAR(60)   NOT NULL,
  hex         CHAR(7)       NOT NULL,        -- formato #RRGGBB
  activa      TINYINT(1)    NOT NULL DEFAULT 1,
  stock       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  orden       TINYINT UNSIGNED  NOT NULL DEFAULT 0,

  FOREIGN KEY (moto_id) REFERENCES motos(id) ON DELETE CASCADE,
  UNIQUE KEY uq_moto_color (moto_id, nombre)
);

-- Colores iniciales para cada moto (4 por moto)
INSERT INTO colores_moto (moto_id, nombre, hex, stock, orden) VALUES
-- Bera Bicycle (1)
  (1,'Blanco Perla','#f5f5f5',0,0),(1,'Negro Mate','#212121',0,1),(1,'Azul Eléctrico','#1565c0',0,2),(1,'Verde Lima','#8bc34a',0,3),
-- BRF 150cc (2)
  (2,'Rojo Vivo','#e53935',0,0),(2,'Negro','#212121',0,1),(2,'Azul Oscuro','#1a237e',0,2),(2,'Gris Plata','#9e9e9e',0,3),
-- Socialista (3)
  (3,'Rojo','#c62828',0,0),(3,'Negro','#212121',0,1),(3,'Azul','#1565c0',0,2),(3,'Blanco','#fafafa',0,3),
-- SBR 150 (4)
  (4,'Negro Mate','#212121',0,0),(4,'Rojo','#d50000',0,1),(4,'Azul','#0d47a1',0,2),(4,'Blanco','#fafafa',0,3),
-- X1 (5)
  (5,'Amarillo','#fdd835',0,0),(5,'Negro','#212121',0,1),(5,'Rojo','#c62828',0,2),(5,'Azul','#1565c0',0,3),
-- Milan (6)
  (6,'Blanco Perla','#f5f5f5',0,0),(6,'Gris Plata','#9e9e9e',0,1),(6,'Rojo','#d50000',0,2),(6,'Negro','#212121',0,3),
-- León (7)
  (7,'Azul Marino','#0d47a1',0,0),(7,'Negro','#212121',0,1),(7,'Rojo Carmín','#b71c1c',0,2),(7,'Blanco','#fafafa',0,3),
-- Runner (8)
  (8,'Gris Oscuro','#424242',0,0),(8,'Negro','#212121',0,1),(8,'Rojo','#d50000',0,2),(8,'Azul','#1565c0',0,3),
-- Tezú (9)
  (9,'Negro Mate','#212121',0,0),(9,'Gris Acero','#607d8b',0,1),(9,'Blanco','#fafafa',0,2),(9,'Azul Cobalto','#1565c0',0,3),
-- BR200 (10)
  (10,'Negro','#212121',0,0),(10,'Verde Militar','#33691e',0,1),(10,'Marrón','#5d4037',0,2),(10,'Naranja','#e65100',0,3),
-- Kavak (11)
  (11,'Rojo','#d50000',0,0),(11,'Negro','#212121',0,1),(11,'Blanco','#fafafa',0,2),(11,'Verde','#2e7d32',0,3),
-- BWS 180cc (12)
  (12,'Negro','#212121',0,0),(12,'Blanco Perla','#f5f5f5',0,1),(12,'Rojo','#d50000',0,2),(12,'Azul','#1565c0',0,3),
-- Cobra (13)
  (13,'Negro','#212121',0,0),(13,'Gris','#757575',0,1),(13,'Rojo','#d50000',0,2),(13,'Blanco','#fafafa',0,3),
-- Antiking LE (14)
  (14,'Negro Café','#3e2723',0,0),(14,'Marrón Cuero','#795548',0,1),(14,'Rojo','#d50000',0,2),(14,'Crema','#fff9c4',0,3),
-- Optimus Electric (15)
  (15,'Blanco','#fafafa',0,0),(15,'Negro','#212121',0,1),(15,'Azul Eléctrico','#0288d1',0,2),(15,'Morado','#6a1b9a',0,3),
-- GBR (16)
  (16,'Rojo Racing','#d50000',0,0),(16,'Negro','#212121',0,1),(16,'Blanco','#fafafa',0,2),(16,'Gris Oscuro','#424242',0,3),
-- DT BR200 RR (17)
  (17,'Verde Militar','#33691e',0,0),(17,'Negro','#212121',0,1),(17,'Naranja','#e65100',0,2),(17,'Gris','#616161',0,3),
-- BRZ 250 (18)
  (18,'Negro','#212121',0,0),(18,'Azul Marino','#0d47a1',0,1),(18,'Rojo','#d50000',0,2),(18,'Blanco','#fafafa',0,3),
-- GR 250 (19)
  (19,'Rojo','#d50000',0,0),(19,'Negro','#212121',0,1),(19,'Blanco','#fafafa',0,2),(19,'Gris Acero','#546e7a',0,3),
-- Carguero (20)
  (20,'Amarillo','#f9a825',0,0),(20,'Naranja','#e65100',0,1),(20,'Rojo','#d50000',0,2),(20,'Negro','#212121',0,3),
-- Tractor BRA 254 (21)
  (21,'Rojo','#d50000',0,0),(21,'Azul','#1565c0',0,1),(21,'Verde','#2e7d32',0,2),(21,'Naranja','#e65100',0,3),
-- Zontes 200U (22)
  (22,'Negro','#212121',0,0),(22,'Gris Plata','#9e9e9e',0,1),(22,'Azul','#1565c0',0,2),(22,'Rojo','#d50000',0,3),
-- Zontes 350 T2 (23)
  (23,'Negro','#212121',0,0),(23,'Rojo','#d50000',0,1),(23,'Blanco','#fafafa',0,2),(23,'Azul','#1a237e',0,3),
-- Zontes 368M (24)
  (24,'Negro Grafito','#212121',0,0),(24,'Gris Plata','#9e9e9e',0,1),(24,'Azul','#0d47a1',0,2),(24,'Blanco','#fafafa',0,3),
-- Zontes 703F (25)
  (25,'Negro Carbón','#121212',0,0),(25,'Gris Oscuro','#424242',0,1),(25,'Rojo','#d50000',0,2),(25,'Azul','#1a237e',0,3),
-- Morini X-Cape (26)
  (26,'Naranja','#e65100',0,0),(26,'Negro','#212121',0,1),(26,'Gris','#616161',0,2),(26,'Rojo','#d50000',0,3),
-- Morini STR (27)
  (27,'Negro','#212121',0,0),(27,'Rojo','#d50000',0,1),(27,'Gris Plata','#9e9e9e',0,2),(27,'Verde','#2e7d32',0,3),
-- Morini SCR (28)
  (28,'Verde Militar','#33691e',0,0),(28,'Negro','#212121',0,1),(28,'Marrón','#5d4037',0,2),(28,'Naranja','#e65100',0,3),
-- Segway AT5L (29)
  (29,'Verde Militar','#33691e',0,0),(29,'Negro','#212121',0,1),(29,'Gris','#546e7a',0,2),(29,'Rojo','#d50000',0,3),
-- Segway Fugleman (30)
  (30,'Verde Oscuro','#1b5e20',0,0),(30,'Negro','#212121',0,1),(30,'Gris','#546e7a',0,2),(30,'Amarillo','#f9a825',0,3),
-- Segway Villain (31)
  (31,'Negro','#212121',0,0),(31,'Gris Oscuro','#424242',0,1),(31,'Azul','#0d47a1',0,2),(31,'Blanco','#fafafa',0,3),
-- Segway AT10W (32)
  (32,'Negro','#212121',0,0),(32,'Verde Militar','#33691e',0,1),(32,'Naranja','#e65100',0,2),(32,'Gris','#546e7a',0,3),
-- Segway Super Villain (33)
  (33,'Negro','#121212',0,0),(33,'Gris Oscuro','#424242',0,1),(33,'Azul Noche','#0d47a1',0,2),(33,'Rojo','#d50000',0,3),
-- Zontes 750 (34)
  (34,'Negro','#212121',0,0),(34,'Gris Plata','#9e9e9e',0,1),(34,'Azul Oscuro','#1a237e',0,2),(34,'Blanco','#fafafa',0,3);

-- ============================================================
--  5. PEDIDOS
-- ============================================================
CREATE TABLE pedidos (
  id                  VARCHAR(25)   NOT NULL PRIMARY KEY,   -- 'ORD-1234567890'
  usuario_id          INT UNSIGNED  NOT NULL,
  concesionario       VARCHAR(120)  NOT NULL,
  fecha               DATE          NOT NULL,
  total               DECIMAL(12,2) NOT NULL,
  estado              ENUM('pending','en_progreso','despachado','rejected') NOT NULL DEFAULT 'pending',
  modificado          TINYINT(1)    NOT NULL DEFAULT 0,
  fecha_limite_mod    DATE          NOT NULL,               -- fecha_pedido + dias_modificacion
  creado_en           TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  actualizado_en      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

CREATE INDEX idx_pedidos_usuario ON pedidos(usuario_id);
CREATE INDEX idx_pedidos_estado  ON pedidos(estado);

-- ============================================================
--  6. ITEMS DE PEDIDO
-- ============================================================
CREATE TABLE pedido_items (
  id              INT UNSIGNED  NOT NULL AUTO_INCREMENT PRIMARY KEY,
  pedido_id       VARCHAR(25)   NOT NULL,
  moto_id         SMALLINT UNSIGNED NOT NULL,
  moto_nombre     VARCHAR(80)   NOT NULL,               -- snapshot al momento del pedido
  moto_cc         VARCHAR(60)   NOT NULL,
  color_nombre    VARCHAR(60)   NOT NULL,
  color_hex       CHAR(7)       NOT NULL,
  cantidad        SMALLINT UNSIGNED NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal        DECIMAL(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,

  FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
  FOREIGN KEY (moto_id)   REFERENCES motos(id)
);

CREATE INDEX idx_pedido_items_pedido ON pedido_items(pedido_id);

-- ============================================================
--  7. DESPACHOS
-- ============================================================
CREATE TABLE despachos (
  id              VARCHAR(25)   NOT NULL PRIMARY KEY,   -- 'DSP-1234567890'
  pedido_id       VARCHAR(25)   NOT NULL,
  concesionario   VARCHAR(120)  NOT NULL,
  fecha_despacho  DATE          NOT NULL,
  observacion     TEXT,
  creado_por      INT UNSIGNED  NOT NULL,               -- usuario admin
  creado_en       TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (pedido_id)   REFERENCES pedidos(id),
  FOREIGN KEY (creado_por)  REFERENCES usuarios(id)
);

-- ============================================================
--  8. HISTORIAL DE CAMBIOS DE ESTADO (trazabilidad)
-- ============================================================
CREATE TABLE pedido_historial (
  id              INT UNSIGNED  NOT NULL AUTO_INCREMENT PRIMARY KEY,
  pedido_id       VARCHAR(25)   NOT NULL,
  estado_anterior VARCHAR(20),
  estado_nuevo    VARCHAR(20)   NOT NULL,
  usuario_id      INT UNSIGNED  NOT NULL,
  notas           TEXT,
  fecha           TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (pedido_id)  REFERENCES pedidos(id) ON DELETE CASCADE,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- ============================================================
--  VISTAS ÚTILES
-- ============================================================

-- Vista: stock total por moto (suma de todos sus colores)
CREATE OR REPLACE VIEW vista_stock_moto AS
  SELECT
    m.id,
    m.nombre,
    m.categoria_id,
    m.precio,
    m.activa,
    m.forzar_agotado,
    SUM(c.stock)                                     AS stock_total,
    SUM(CASE WHEN c.activa=1 THEN c.stock ELSE 0 END) AS stock_disponible
  FROM motos m
  LEFT JOIN colores_moto c ON c.moto_id = m.id
  GROUP BY m.id;

-- Vista: resumen de pedidos por concesionario
CREATE OR REPLACE VIEW vista_pedidos_resumen AS
  SELECT
    p.id,
    p.fecha,
    p.estado,
    p.total,
    p.concesionario,
    u.email,
    COUNT(pi.id)      AS total_items,
    SUM(pi.cantidad)  AS total_unidades
  FROM pedidos p
  JOIN usuarios u       ON u.id = p.usuario_id
  JOIN pedido_items pi  ON pi.pedido_id = p.id
  GROUP BY p.id;

-- Vista: pedidos por despachar
CREATE OR REPLACE VIEW vista_por_despachar AS
  SELECT * FROM vista_pedidos_resumen
  WHERE estado IN ('pending','en_progreso');

-- Vista: pedidos despachados
CREATE OR REPLACE VIEW vista_despachados AS
  SELECT
    vp.*,
    d.id          AS despacho_id,
    d.fecha_despacho,
    d.observacion AS obs_despacho
  FROM vista_pedidos_resumen vp
  JOIN despachos d ON d.pedido_id = vp.id
  WHERE vp.estado = 'despachado';

-- ============================================================
--  PROCEDIMIENTOS ALMACENADOS
-- ============================================================

DELIMITER //

-- Confirmar pedido y descontar stock
CREATE PROCEDURE sp_confirmar_pedido(IN p_pedido_id VARCHAR(25))
BEGIN
  DECLARE v_moto_id    SMALLINT UNSIGNED;
  DECLARE v_color      VARCHAR(60);
  DECLARE v_cantidad   SMALLINT UNSIGNED;
  DECLARE done         INT DEFAULT 0;

  DECLARE cur CURSOR FOR
    SELECT moto_id, color_nombre, cantidad
    FROM pedido_items WHERE pedido_id = p_pedido_id;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  START TRANSACTION;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_moto_id, v_color, v_cantidad;
    IF done THEN LEAVE read_loop; END IF;

    UPDATE colores_moto
    SET stock = GREATEST(0, stock - v_cantidad)
    WHERE moto_id = v_moto_id AND nombre = v_color;
  END LOOP;
  CLOSE cur;

  UPDATE pedidos SET estado = 'pending' WHERE id = p_pedido_id;

  COMMIT;
END //

-- Crear despacho y marcar pedido como despachado
CREATE PROCEDURE sp_crear_despacho(
  IN p_desp_id      VARCHAR(25),
  IN p_pedido_id    VARCHAR(25),
  IN p_fecha        DATE,
  IN p_obs          TEXT,
  IN p_admin_id     INT UNSIGNED
)
BEGIN
  DECLARE v_conces VARCHAR(120);

  SELECT concesionario INTO v_conces FROM pedidos WHERE id = p_pedido_id;

  INSERT INTO despachos (id, pedido_id, concesionario, fecha_despacho, observacion, creado_por)
  VALUES (p_desp_id, p_pedido_id, v_conces, p_fecha, p_obs, p_admin_id);

  UPDATE pedidos SET estado = 'despachado' WHERE id = p_pedido_id;

  INSERT INTO pedido_historial (pedido_id, estado_anterior, estado_nuevo, usuario_id, notas)
  VALUES (p_pedido_id, 'en_progreso', 'despachado', p_admin_id, CONCAT('Despacho: ', p_desp_id));
END //

DELIMITER ;

-- ============================================================
--  FIN DEL ESQUEMA
-- ============================================================
