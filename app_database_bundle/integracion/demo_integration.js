// Demo Node.js que muestra la integración conceptual entre PostgreSQL, MongoDB y Redis
// Ejecutar: node demo_integration.js (aseurar npm i pg mongodb ioredis)

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
  const res = await pg.query(`SELECT u.user_id, u.name FROM app."user" u LIMIT 1`);
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
