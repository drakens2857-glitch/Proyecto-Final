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
