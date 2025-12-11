Casos de uso integrados:

Sesiones: Redis STRING para almacenar token corto y expiración (autenticación rápida).
Cola de atención: LIST para push/pop de turnos; el worker consume y marca reservas en SQL.
Contadores: STRING/INCR para conteos globales (total de reservas, visitas).
Configuraciones: HASH para settings por sucursal (lectura rápida sin tocar SQL).
Leaderboard/Métricas: ZSET para rankear usuarios por puntos.
