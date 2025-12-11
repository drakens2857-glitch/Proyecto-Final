Se crean 3 colecciones pensadas para datos semiestructurados relacionados al sistema de reservas:

profiles - perfiles extendidos de usuario (documentos grandes con preferencias, historial, notas).
booking_histories - historiales/envelope de reservas con cambios y logs (un documento por reserva con array de eventos).
analytics - almacenamiento de métricas y métricas agregadas por día para queries analíticas ad-hoc.
Justificación: MongoDB es útil para almacenar documentos con esquemas flexibles.
