const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const auth = require('../middleware/auth');

const router = express.Router();

//Registrar un usuario
router.post('/register', async (req, res) => {
  const { name, lastName, rut, email, password } = req.body;
  try {
    // Validar que todos los campos estén presentes
    if (!name || !lastName || !rut || !email || !password) {
      return res.status(400).json({ msg: 'Por favor completa todos los campos' });
    }

    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ msg: 'El correo ya está registrado' });
    }

    user = new User({ name, lastName, rut, email, password });
    await user.save();

    // Generar token para el nuevo usuario
    const payload = { user: { id: user.id } };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '5h' });

    res.status(201).json({
      token,
      user: {
        id: user.id,
        name: user.name,
        lastName: user.lastName,
        rut: user.rut,
        email: user.email,
      },
    });
  } catch (err) {
    console.error('Error en registro:', err);
    res.status(500).json({ msg: 'Error en el servidor' });
  }
});

// Iniciar sesión y obtener token
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ msg: 'Credenciales inválidas' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ msg: 'Credenciales inválidas' });
    }

    const payload = { user: { id: user.id } };
    const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '5h' });

    res.json({
      token,
      user: {
        id: user.id,
        name: user.name,
        lastName: user.lastName,
        rut: user.rut,
        email: user.email,
        profilePhoto: user.profilePhoto || '',
      },
    });
  } catch (err) {
    console.error('Error en login:', err);
    res.status(500).json({ msg: 'Error en el servidor' });
  }
});

// @route   GET /api/auth/profile
// @desc    Obtener perfil del usuario autenticado
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }
    res.json({
      id: user.id,
      name: user.name,
      lastName: user.lastName,
      rut: user.rut,
      email: user.email,
      profilePhoto: user.profilePhoto || '',
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Error en el servidor');
  }
});

// @route   PUT /api/auth/profile
// @desc    Actualizar perfil del usuario
router.put('/profile', auth, async (req, res) => {
  const { name, lastName, profilePhoto } = req.body;
  
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    // Actualizar campos si se proporcionan
    if (name) user.name = name;
    if (lastName) user.lastName = lastName;
    if (profilePhoto !== undefined) user.profilePhoto = profilePhoto;

    await user.save();

    // Devolver el usuario actualizado completo
    res.json({
      message: 'Perfil actualizado exitosamente',
      user: {
        id: user.id,
        name: user.name,
        lastName: user.lastName,
        email: user.email,
        profilePhoto: user.profilePhoto || '',
      },
    });
  } catch (err) {
    console.error('Error al actualizar perfil:', err.message);
    res.status(500).json({ message: 'Error en el servidor al actualizar el perfil' });
  }
});

module.exports = router;