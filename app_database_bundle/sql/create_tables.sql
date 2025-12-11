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
