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
