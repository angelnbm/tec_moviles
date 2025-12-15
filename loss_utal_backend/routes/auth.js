const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const auth = require('../middleware/auth');
const nodemailer = require('nodemailer');
const crypto = require('crypto'); // Librería nativa de Node.js

const router = express.Router();

// Configuración del transporte de correo (GMAIL)
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

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
        profileImage: user.profileImage,
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
        profileImage: user.profileImage,
      },
    });
  } catch (err) {
    console.error('Error en login:', err);
    res.status(500).json({ msg: 'Error en el servidor' });
  }
});

// Obtener perfil del usuario autenticado
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    if (!user) {
      return res.status(404).json({ msg: 'Usuario no encontrado' });
    }
    res.json(user);
  } catch (err) {
    console.error('Error al obtener perfil:', err);
    res.status(500).json({ msg: 'Error en el servidor' });
  }
});

// Actualizar perfil del usuario
router.put('/profile', auth, async (req, res) => {
  const { name, lastName, profileImage } = req.body;
  
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ msg: 'Usuario no encontrado' });
    }

    // Actualizar campos si se proporcionan
    if (name) user.name = name;
    if (lastName) user.lastName = lastName;
    if (profileImage !== undefined) user.profileImage = profileImage;

    await user.save();

    res.json({
      id: user.id,
      name: user.name,
      lastName: user.lastName,
      rut: user.rut,
      email: user.email,
      profileImage: user.profileImage,
    });
  } catch (err) {
    console.error('Error al actualizar perfil:', err);
    res.status(500).json({ msg: 'Error en el servidor' });
  }
});

// Actualizar FCM Token
router.post('/fcm-token', auth, async (req, res) => {
  try {
    const { token } = req.body;
    console.log(`Guardando token FCM para usuario ${req.user.id}:`, token ? 'Token recibido' : 'Token vacío');
    
    await User.findByIdAndUpdate(req.user.id, { fcmToken: token });
    res.json({ success: true });
  } catch (err) {
    console.error('Error guardando token:', err);
    res.status(500).json({ message: 'Error al guardar token' });
  }
});

// 1. Solicitar recuperación (Enviar código)
router.post('/forgot-password', async (req, res) => {
  const { email } = req.body;
  try {
    const user = await User.findOne({ email });

    // Si el usuario no existe, respondemos éxito igual por seguridad (para no revelar correos)
    if (!user) {
      return res.json({ success: true, message: 'Si el correo existe, se envió un código.' });
    }

    // Generar código de 6 dígitos
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Guardar código y expiración (15 minutos)
    user.resetPasswordToken = code;
    user.resetPasswordExpires = Date.now() + 900000; // 15 min
    await user.save();

    // Enviar correo
    const mailOptions = {
      from: 'Soporte Loss UTALCA',
      to: user.email,
      subject: 'Recuperación de contraseña - Loss UTALCA',
      text: `Tu código de recuperación es: ${code}\n\nEste código expira en 15 minutos.`
    };

    transporter.sendMail(mailOptions, (error, info) => {
      if (error) {
        console.log(error);
        // En producción, no devolver el error exacto al cliente
      }
    });

    res.json({ success: true, message: 'Si el correo existe, se envió un código.' });

  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// 2. Verificar código
router.post('/verify-code', async (req, res) => {
  const { email, code } = req.body;
  try {
    const user = await User.findOne({ 
      email, 
      resetPasswordToken: code,
      resetPasswordExpires: { $gt: Date.now() } // Verificar que no haya expirado
    });

    if (!user) {
      return res.status(400).json({ success: false, message: 'Código inválido o expirado' });
    }

    res.json({ success: true, message: 'Código verificado' });
  } catch (err) {
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// 3. Restablecer contraseña
router.post('/reset-password', async (req, res) => {
  const { email, code, newPassword } = req.body;
  try {
    const user = await User.findOne({ 
      email, 
      resetPasswordToken: code,
      resetPasswordExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ success: false, message: 'Solicitud inválida o expirada' });
    }

    // Actualizar contraseña (el middleware pre-save del modelo se encargará de hashear)
    user.password = newPassword;
    user.resetPasswordToken = ''; // Limpiar token
    user.resetPasswordExpires = null;
    
    await user.save();

    res.json({ success: true, message: 'Contraseña actualizada correctamente' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error al actualizar contraseña' });
  }
});

module.exports = router;