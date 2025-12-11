# Bundle: PostgreSQL + MongoDB + Redis (demo)

Contenido:
- sql/create_tables.sql
- sql/insert_data.sql
- sql/queries_avanzadas.sql
- mongodb/* (diseño, inserts y consultas)
- redis/* (comandos y casos de uso)
- integracion/docker-compose.yml
- integracion/demo_integration.js

Instrucciones rápidas:

1. Levantar servicios con Docker:
   docker-compose -f integracion/docker-compose.yml up -d

2. Importar SQL en PostgreSQL:
   psql -h localhost -U appuser -d appdb -f sql/create_tables.sql
   psql -h localhost -U appuser -d appdb -f sql/insert_data.sql

3. Cargar documentos MongoDB (ej. con mongoimport):
   mongoimport --db appdb --collection profiles --file mongodb/inserts.json --jsonArray

4. Usar Redis para caché/colas según los archivos redis/*

Notas:
- Ajusta credenciales en docker-compose si es necesario.
- Si deseas, puedo crear un script de inicialización (entrypoint) para automatizar la importación en el container de Postgres.
