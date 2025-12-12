# Proyecto Final: Sistema Híbrido SQL + MongoDB + Redis

---

## Estructura del repositorio

```
/proyecto-final/
  /sql/
    modelo_conceptual.md
    modelo_relacional.md
    create_tables.sql
    insert_data.sql
    queries_avanzadas.sql
  /mongodb/
    diseño_colecciones.md
    inserts.json
    consultas_aggregation.md
  /redis/
    comandos_basicos.txt
    operaciones_estructuras.txt
    casos_de_uso_redis.md
  /integracion/
    docker-compose.yml
    demo_integration.js
  /documentacion/
    arquitectura_de_datos.md
    conexion_entre_las_3_bases.md
  README.md
```

---

# README.md

Este proyecto demuestra un sistema de información híbrido que integra PostgreSQL (SQL), MongoDB (documental) y Redis (clave-valor). Incluye: modelos, scripts SQL, colecciones y pipelines MongoDB, ejemplos y comandos Redis, y un demo de integración usando Node.js.

**Requisitos de ejecución:**

* Docker & Docker Compose
* Node.js 18+

# /sql/modelo_conceptual.md

Se modela un sistema de **Reservas y Atención al Cliente** para una cadena de servicios (por ejemplo: talleres/centros de atención).

Entidades principales:

* Usuario (User)
* Cliente (Customer) - extiende Usuario
* Empleado (Employee)
* Servicio (Service)
* Sucursal (Branch)
* Reserva (Booking)
* Pago (Payment)

Diagrama conceptual :

```
User( user_id PK, name, email )
Customer( customer_id PK, user_id FK -> User, document_id, phone )
Employee( employee_id PK, user_id FK -> User, role )
Branch( branch_id PK, name, address )
Service( service_id PK, name, duration_min, price )
Booking( booking_id PK, customer_id FK -> Customer, branch_id FK -> Branch, scheduled_at, status )
Booking_Service( booking_id FK, service_id FK ) -- relación M:N
Payment( payment_id PK, booking_id FK -> Booking, amount, method, paid_at )
```

Normalizado hasta 3FN: atributos atómicos, dependencias funcionales resueltas, tablas separadas para relaciones N:M.

---

# /sql/modelo_relacional.md

Se traducen las entidades anteriores a tablas con tipos SQL (PostgreSQL).

Claves y relaciones: PRIMARY KEY, FOREIGN KEY con `ON DELETE CASCADE` donde corresponde.

---

# /sql/create_tables.sql

```sql
-- Crear esquema para PostgreSQL
CREATE SCHEMA IF NOT EXISTS app;
SET search_path = app;

CREATE TABLE "user" (
  user_id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE customer (
  customer_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
  document_id VARCHAR(50),
  phone VARCHAR(30)
);

CREATE TABLE employee (
  employee_id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES "user"(user_id) ON DELETE CASCADE,
  role VARCHAR(50)
);

CREATE TABLE branch (
  branch_id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  address TEXT
);

CREATE TABLE service (
  service_id SERIAL PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  duration_min INT NOT NULL,
  price NUMERIC(10,2) NOT NULL
);

CREATE TABLE booking (
  booking_id SERIAL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES customer(customer_id) ON DELETE CASCADE,
  branch_id INT NOT NULL REFERENCES branch(branch_id),
  scheduled_at TIMESTAMP NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'scheduled',
  created_at TIMESTAMP DEFAULT now()
);

-- tabla many-to-many booking <-> service
CREATE TABLE booking_service (
  booking_id INT NOT NULL REFERENCES booking(booking_id) ON DELETE CASCADE,
  service_id INT NOT NULL REFERENCES service(service_id) ON DELETE CASCADE,
  PRIMARY KEY (booking_id, service_id)
);

CREATE TABLE payment (
  payment_id SERIAL PRIMARY KEY,
  booking_id INT NOT NULL REFERENCES booking(booking_id) ON DELETE CASCADE,
  amount NUMERIC(10,2) NOT NULL,
  method VARCHAR(50),
  paid_at TIMESTAMP
);

-- Algunas vistas/materializaciones para consultas frecuentes (opcional)
CREATE VIEW vw_booking_details AS
SELECT b.booking_id, u.name as customer_name, br.name as branch_name, b.scheduled_at, b.status
FROM booking b
JOIN customer c ON c.customer_id = b.customer_id
JOIN "user" u ON u.user_id = c.user_id
JOIN branch br ON br.branch_id = b.branch_id;

```

---

# /sql/insert_data.sql

```sql
-- Inserts de ejemplo
INSERT INTO "user" (name, email) VALUES
('Ana Perez','ana.perez@example.com'),
('Carlos Lopez','carlos.lopez@example.com'),
('Sofia Martinez','sofia.m@example.com'),
('Diego Ruiz','diego.ruiz@example.com');

INSERT INTO customer (user_id, document_id, phone) VALUES
(1, 'CC12345', '3001112222'),
(3, 'CC98765', '3003334444');

INSERT INTO employee (user_id, role) VALUES
(2, 'technician'),
(4, 'reception');

INSERT INTO branch (name, address) VALUES
('Sucursal Centro','Calle 1 #10-20'),
('Sucursal Norte','Av 5 #30-40');

INSERT INTO service (name, duration_min, price) VALUES
('Cambio de aceite', 30, 45.00),
('Alineación', 60, 80.00),
('Revisión general', 45, 60.00);

INSERT INTO booking (customer_id, branch_id, scheduled_at, status) VALUES
(1, 1, now() + interval '2 day', 'scheduled'),
(1, 2, now() + interval '7 day', 'scheduled'),
(2, 1, now() + interval '1 day', 'cancelled');

INSERT INTO booking_service (booking_id, service_id) VALUES
(1,1),(1,3),(2,2);

INSERT INTO payment (booking_id, amount, method, paid_at) VALUES
(1, 105.00, 'card', now()),
(2, 80.00, 'cash', null);
```

---

# /sql/queries_avanzadas.sql

```sql
-- 1) JOINs: INNER, LEFT, RIGHT, FULL (FULL OUTER en PG)
-- INNER JOIN: reservas confirmadas con cliente y sucursal
SELECT b.booking_id, u.name AS customer_name, br.name AS branch_name
FROM booking b
JOIN customer c ON c.customer_id = b.customer_id
JOIN "user" u ON u.user_id = c.user_id
JOIN branch br ON br.branch_id = b.branch_id
WHERE b.status = 'scheduled';

-- LEFT JOIN: todos los clientes y sus últimas reservas (si existen)
SELECT u.name, b.booking_id, b.scheduled_at
FROM "user" u
LEFT JOIN customer c ON c.user_id = u.user_id
LEFT JOIN booking b ON b.customer_id = c.customer_id
ORDER BY u.user_id;

-- FULL OUTER JOIN: ejemplo entre servicios y pagos (hypothetical)
SELECT s.service_id, s.name, p.payment_id
FROM service s
FULL OUTER JOIN booking_service bs ON bs.service_id = s.service_id
FULL OUTER JOIN booking b ON b.booking_id = bs.booking_id
FULL OUTER JOIN payment p ON p.booking_id = b.booking_id;

-- 2) GROUP BY + HAVING: total facturado por sucursal (solo con > 1 pago)
SELECT br.branch_id, br.name, SUM(p.amount) AS total
FROM payment p
JOIN booking b ON b.booking_id = p.booking_id
JOIN branch br ON br.branch_id = b.branch_id
GROUP BY br.branch_id, br.name
HAVING SUM(p.amount) > 100;

-- 3) Subconsulta: clientes que han pagado más de la media
SELECT c.customer_id, u.name
FROM customer c
JOIN "user" u ON u.user_id = c.user_id
WHERE (SELECT SUM(amount) FROM payment p JOIN booking b ON b.booking_id = p.booking_id WHERE b.customer_id = c.customer_id) >
      (SELECT AVG(total) FROM (SELECT SUM(amount) as total FROM payment GROUP BY booking_id) t);

-- 4) CTEs con WITH: disponibilidad por sucursal en rango de fechas
WITH bookings_in_range AS (
  SELECT branch_id, scheduled_at FROM booking
  WHERE scheduled_at BETWEEN now() AND now() + interval '10 day'
)
SELECT br.branch_id, br.name, COUNT(bir.scheduled_at) AS reserved_in_next_10_days
FROM branch br
LEFT JOIN bookings_in_range bir ON bir.branch_id = br.branch_id
GROUP BY br.branch_id, br.name;

-- 5) Consulta que usa JOINs, agregación y subconsulta combinada
WITH payments_per_booking AS (
  SELECT booking_id, SUM(amount) AS paid_total FROM payment GROUP BY booking_id
)
SELECT b.booking_id, u.name, COALESCE(ppb.paid_total,0) as paid_total
FROM booking b
JOIN customer c ON c.customer_id = b.customer_id
JOIN "user" u ON u.user_id = c.user_id
LEFT JOIN payments_per_booking ppb ON ppb.booking_id = b.booking_id
WHERE COALESCE(ppb.paid_total,0) < (
  SELECT AVG(amount) FROM payment
);
```

---

# /mongodb/diseño_colecciones.md

Se crean 3 colecciones pensadas para datos semiestructurados relacionados al sistema de reservas:

1. `profiles` - perfiles extendidos de usuario (documentos grandes con preferencias, historial, notas).
2. `booking_histories` - historiales/envelope de reservas con cambios y logs (un documento por reserva con array de eventos).
3. `analytics` - almacenamiento de métricas y métricas agregadas por día para queries analíticas ad-hoc.

Justificación: MongoDB es útil para almacenar documentos con esquemas flexibles.

---

# /mongodb/inserts.json

```json
[
  {
    "_id": {"$oid":"64b1f1a1c2a3e1a1a1a1a1a1"},
    "user_id": 1,
    "preferences": {"notifications": true, "language": "es", "favorite_services": ["Cambio de aceite","Alineación"]},
    "addresses": [{"label":"Casa","address":"Calle 1 #10-20"}],
    "created_at": {"$date":"2025-12-01T10:00:00Z"}
  },
  {
    "_id": {"$oid":"64b1f1a1c2a3e1a1a1a1a1a2"},
    "user_id": 3,
    "preferences": {"notifications": false, "language": "en"},
    "notes": "Cliente VIP",
    "created_at": {"$date":"2025-11-28T12:00:00Z"}
  }
]
```

---

# /mongodb/consultas_aggregation.md

**Pipeline 1:** Obtener número de reservas y total pagado por usuario (lookup entre booking/payment almacenados en SQL — simulación con colección booking_histories que contiene payment array)

```js
// pipeline: agrupar por user_id, contar reservas, sumar pagos
[
  { $match: { "events.0": { $exists: true } } },
  { $unwind: "$events" },
  { $match: { "events.type": "payment" } },
  { $group: { _id: "$user_id", total_paid: { $sum: "$events.amount" }, payments_count: { $sum: 1 } } },
  { $sort: { total_paid: -1 } }
]
```

**Pipeline 2:** Perfil con último evento y lista de servicios frecuentes

```js
[
  { $match: { user_id: 1 } },
  { $project: { user_id:1, preferences:1, last_event: { $arrayElemAt: ["$events", -1] }, services: "$events.service_name" } },
  { $unwind: { path: "$services", preserveNullAndEmptyArrays: true } },
  { $group: { _id: "$user_id", servicesList: { $push: "$services" }, last_event: { $first: "$last_event" } } }
]
```

*Nota:* Si quiere usarse `$lookup` entre MongoDB y SQL, en la práctica se realiza en el nivel de la API/backend (ej: Node.js) o usando herramientas ETL.

---

# /redis/comandos_basicos.txt

```
# Conexión (CLI): redis-cli -h localhost -p 6379
# Ejemplos básicos:
SET session:1:user_id 1
GET session:1:user_id
INCR counter:bookings_total
LPUSH queue:appointments 12345
RPOP queue:appointments
HSET config:branch:1 open true staff_count 5
HGETALL config:branch:1
SADD online_users 1 3 5
SMEMBERS online_users
ZADD leaderboard 150 user:1 200 user:2
ZRANGE leaderboard 0 -1 WITHSCORES
```

---

# /redis/operaciones_estructuras.txt

```
# STRING: sesiones y tokens
SET session:user:1 "{\"user_id\":1,\"expires\":\"...\"}" EX 1800

# LIST: cola de turnos
LPUSH queue:turns "booking:101"
RPUSH queue:turns "booking:102"
BRPOP queue:turns 0 -- bloqueo para consumidor

# HASH: configuraciones por sucursal
HSET branch:1:config open true max_capacity 30 contact "3001112222"
HGET branch:1:config max_capacity

# SET: usuarios en línea (no duplicados)
SADD online_users 1
SADD online_users 2

# ZSET: ranking por puntos o métricas
ZADD user_points 120 "user:1" 200 "user:3"
ZRANGE user_points 0 -1 WITHSCORES

# TTL (expiración)
SET otp:12345 987654 EX 120 -- OTP expira en 120s
```

---

# /redis/casos_de_uso_redis.md

Casos de uso integrados:

* **Sesiones:** Redis STRING para almacenar token corto y expiración (autenticación rápida).
* **Cola de atención:** LIST para push/pop de turnos; el worker consume y marca reservas en SQL.
* **Contadores:** STRING/INCR para conteos globales (total de reservas, visitas).
* **Configuraciones:** HASH para settings por sucursal (lectura rápida sin tocar SQL).
* **Leaderboard/Métricas:** ZSET para rankear usuarios por puntos.

---

# /integracion/docker-compose.yml

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: apppass
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  mongodb:
    image: mongo:6
    ports:
      - "27017:27017"
    volumes:
      - mongodata:/data/db

  redis:
    image: redis:7
    ports:
      - "6379:6379"
    command: redis-server --save 60 1

volumes:
  pgdata:
  mongodata:
```

---

# /integracion/demo_integration.js

```js
// Demo Node.js que muestra la integración conceptual entre PostgreSQL, MongoDB y Redis
// Ejecutar: node demo_integration.js (asegurar npm i pg mongodb ioredis)

const { Client } = require('pg');
const { MongoClient } = require('mongodb');
const Redis = require('ioredis');

async function main(){
  // Conexiones
  const pg = new Client({ host: 'localhost', port: 5432, user:'appuser', password:'apppass', database:'appdb' });
  const mongo = new MongoClient('mongodb://localhost:27017');
  const redis = new Redis();

  await pg.connect();
  await mongo.connect();

  const db = mongo.db('appdb');

  // 1) Leer usuario y perfil extendido
  const res = await pg.query(`SELECT u.user_id, u.name FROM public."user" u LIMIT 1`);
  console.log('User from PG:', res.rows[0]);

  const profile = await db.collection('profiles').findOne({ user_id: res.rows[0].user_id });
  console.log('Profile from MongoDB:', profile);

  // 2) Incrementar contador global en Redis
  const bookingsCount = await redis.incr('counter:bookings_total');
  console.log('Bookings counter (Redis):', bookingsCount);

  // 3) Push a queue para procesar notificación
  await redis.lpush('queue:notifications', `notify:user:${res.rows[0].user_id}`);
  console.log('Pushed notification job to Redis list');

  // Cleanup
  await pg.end();
  await mongo.close();
  redis.disconnect();
}

main().catch(err=>{ console.error(err); process.exit(1) });
```

---

# /documentacion/arquitectura_de_datos.md

Explicación arquitectónica:

* **SQL (PostgreSQL):** datos transaccionales y relaciones fuertes (usuarios, reservas, pagos). Garantiza consistencia y ACID para operaciones financieras.
* **MongoDB:** almacenamiento flexible para perfiles, logs y historiales que cambian con frecuencia y contienen arrays/objetos anidados.
* **Redis:** operaciones rápidas en memoria para sesiones, counters, colas y caches; mejora latencia y descarga tráfico del SQL.

Beneficios: rendimiento en consultas rápidas, flexibilidad documental, integridad transaccional.
Riesgos: complejidad operacional, necesidad de estrategia de sincronización y backup multi-DB.

---

# /documentacion/conexion_entre_las_3_bases.md

Caso de uso integrado (flujo):

1. Cliente crea una reserva en frontend -> API escribe reserva en PostgreSQL.
2. API a su vez guarda un documento resumen en MongoDB en `booking_histories` con eventos iniciales (create).
3. API incrementa `counter:bookings_total` en Redis y coloca un job en `queue:notifications`.
4. Worker (consumidor) lee job desde Redis, ejecuta tareas (enviar email) y registra eventos de envío en MongoDB (append a booking_histories.events).
5. Cuando se efectúa el pago, SQL recibe el registro de `payment` y se actualiza el documento en MongoDB con el evento `payment`, además Redis se usa para expiraciones y notificaciones en tiempo real.

Justificación técnica: mantener la fuente de verdad transaccional en SQL, usar MongoDB para trazabilidad/documentos anidados y Redis para rendimiento.

---











