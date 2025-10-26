const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');

// Cargar variables de entorno
dotenv.config();

const app = express();

// Middleware
app.use(cors()); // Permitir peticiones de otros orígenes
app.use(express.json()); // Para parsear JSON

// Conectar a MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('MongoDB conectado'))
  .catch(err => console.error(err));

// Rutas
app.use('/api/auth', require('./routes/auth'));

const PORT = process.env.PORT || 5000;
const HOST = '0.0.0.0'; // Escuchar en todas las interfaces de red

app.listen(PORT, HOST, () => console.log(`Servidor corriendo en ${HOST}:${PORT}`));