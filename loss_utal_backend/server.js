const express = require('express');
const mongoose = require('mongoose');
const dotenv = require('dotenv');
const cors = require('cors');

// Cargar variables de entorno
dotenv.config();

const app = express();

// Middleware
app.use(cors()); // Permitir peticiones de otros orígenes
app.use(express.json({ limit: '50mb' })); // Cambia de 100kb (default) a 50mb
app.use(express.urlencoded({ limit: '50mb', extended: true })); // Para formularios

// Conectar a MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('MongoDB conectado'))
  .catch(err => console.error(err));

// Rutas
app.use('/api/auth', require('./routes/auth'));
app.use('/api/reports', require('./routes/reports'));

const PORT = process.env.PORT || 5000;

app.listen(PORT, '0.0.0.0', () => console.log(`Servidor corriendo en el puerto ${PORT}, accesible en la red local`));