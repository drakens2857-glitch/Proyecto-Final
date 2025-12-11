Pipeline 1: Obtener número de reservas y total pagado por usuario (lookup entre booking/payment almacenados en SQL — simulación con colección booking_histories que contiene payment array)

// pipeline: agrupar por user_id, contar reservas, sumar pagos
[
  { $match: { "events.0": { $exists: true } } },
  { $unwind: "$events" },
  { $match: { "events.type": "payment" } },
  { $group: { _id: "$user_id", total_paid: { $sum: "$events.amount" }, payments_count: { $sum: 1 } } },
  { $sort: { total_paid: -1 } }
]
Pipeline 2: Perfil con último evento y lista de servicios frecuentes

[
  { $match: { user_id: 1 } },
  { $project: { user_id:1, preferences:1, last_event: { $arrayElemAt: ["$events", -1] }, services: "$events.service_name" } },
  { $unwind: { path: "$services", preserveNullAndEmptyArrays: true } },
  { $group: { _id: "$user_id", servicesList: { $push: "$services" }, last_event: { $first: "$last_event" } } }
]
Nota: Si quiere usarse $lookup entre MongoDB y SQL, en la práctica se realiza en el nivel de la API/backend (ej: Node.js) o usando herramientas ETL.
