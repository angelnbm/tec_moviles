const express = require('express');
const Report = require('../models/Report');
const auth = require('../middleware/auth');

const router = express.Router();

//Obtener todos los reportes (público)
router.get('/', async (req, res) => {
  try {
    const reports = await Report.find()
      .populate('userId', 'name lastName email')
      .sort({ createdAt: -1 });
    res.json(reports);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// Obtener reportes del usuario autenticado
router.get('/my-reports', auth, async (req, res) => {
  try {
    const reports = await Report.find({ userId: req.user.id })
      .sort({ createdAt: -1 });
    res.json(reports);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

//Crear un nuevo reporte
router.post('/', auth, async (req, res) => {
  const { title, description, category, location, latitude, longitude, imageUrl } = req.body;
  
  try {
    const newReport = new Report({
      title,
      description,
      category,
      location,
      latitude,
      longitude,
      imageUrl,
      audioUrl,
      userId: req.user.id
    });

    const report = await newReport.save();
    res.status(201).json(report);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// Actualizar un reporte
router.put('/:id', auth, async (req, res) => {
  try {
    const report = await Report.findById(req.params.id);
    
    if (!report) {
      return res.status(404).json({ message: 'Reporte no encontrado' });
    }

    if (report.userId.toString() !== req.user.id) {
      return res.status(403).json({ message: 'No autorizado' });
    }

    const { title, description, category, location, latitude, longitude, imageUrl, status } = req.body;
    
    if (title) report.title = title;
    if (description) report.description = description;
    if (category) report.category = category;
    if (location) report.location = location;
    if (latitude !== undefined) report.latitude = latitude;
    if (longitude !== undefined) report.longitude = longitude;
    if (imageUrl) report.imageUrl = imageUrl;
    if (audioUrl) report.audioUrl = audioUrl;
    if (status) report.status = status;

    await report.save();
    res.json(report);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});


// Eliminar un reporte
router.delete('/:id', auth, async (req, res) => {
  try {
    const report = await Report.findById(req.params.id);
    
    if (!report) {
      return res.status(404).json({ message: 'Reporte no encontrado' });
    }

    if (report.userId.toString() !== req.user.id) {
      return res.status(403).json({ message: 'No autorizado' });
    }

    await report.deleteOne();
    res.json({ message: 'Reporte eliminado' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

module.exports = router;
