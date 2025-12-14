const express = require('express');
const Conversation = require('../models/Conversation');
const Report = require('../models/Report');
const auth = require('../middleware/auth');
const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Inicializar Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
}

const router = express.Router();

// Iniciar una conversación o obtener una existente
router.post('/', auth, async (req, res) => {
  const { reportId, initialMessage } = req.body;

  try {
    // Verificar que el reporte existe
    const report = await Report.findById(reportId).populate('userId', 'name lastName email profileImage');
    if (!report) {
      return res.status(404).json({ message: 'Reporte no encontrado' });
    }

    // No permitir que el autor del reporte se contacte a sí mismo
    if (report.userId._id.toString() === req.user.id) {
      return res.status(400).json({ message: 'No puedes contactarte a ti mismo' });
    }

    // Buscar si ya existe una conversación
    let conversation = await Conversation.findOne({
      reportId,
      interestedUserId: req.user.id
    }).populate('reportAuthorId', 'name lastName email profileImage')
      .populate('interestedUserId', 'name lastName email profileImage')
      .populate('reportId', 'title category imageUrl');

    if (conversation) {
      // Si ya existe y hay un mensaje inicial, agregarlo
      if (initialMessage && initialMessage.trim()) {
        conversation.messages.push({
          senderId: req.user.id,
          message: initialMessage,
          isRead: false
        });
        conversation.lastMessageAt = new Date();
        await conversation.save();
      }
      return res.json(conversation);
    }

    // Crear nueva conversación
    const newConversation = new Conversation({
      reportId,
      reportAuthorId: report.userId._id,
      interestedUserId: req.user.id,
      messages: initialMessage && initialMessage.trim() ? [{
        senderId: req.user.id,
        message: initialMessage,
        isRead: false
      }] : []
    });

    await newConversation.save();

    // Poblar los datos antes de enviar
    const populatedConversation = await Conversation.findById(newConversation._id)
      .populate('reportAuthorId', 'name lastName email profileImage')
      .populate('interestedUserId', 'name lastName email profileImage')
      .populate('reportId', 'title category imageUrl');

    res.status(201).json(populatedConversation);
  } catch (err) {
    console.error('Error al crear conversación:', err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// Verificar si existe una conversación para un reporte específico (desde la vista del usuario interesado)
router.get('/check/:reportId', auth, async (req, res) => {
  try {
    const conversation = await Conversation.findOne({
      reportId: req.params.reportId,
      $or: [
        { interestedUserId: req.user.id },
        { reportAuthorId: req.user.id }
      ]
    }).populate('reportAuthorId', 'name lastName email profileImage')
      .populate('interestedUserId', 'name lastName email profileImage')
      .populate('reportId', 'title category imageUrl');

    if (conversation) {
      // Calcular mensajes no leídos
      const unreadCount = conversation.messages.filter(
        msg => !msg.isRead && msg.senderId.toString() !== req.user.id
      ).length;
      
      const convObj = conversation.toObject();
      convObj.unreadCount = unreadCount;
      
      return res.json({ exists: true, conversation: convObj });
    }
    
    res.json({ exists: false, conversation: null });
  } catch (err) {
    console.error('Error al verificar conversación:', err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// Obtener todas las conversaciones del usuario autenticado
router.get('/my-conversations', auth, async (req, res) => {
  try {
    const conversations = await Conversation.find({
      $or: [
        { reportAuthorId: req.user.id },
        { interestedUserId: req.user.id }
      ]
    })
      .populate('reportAuthorId', 'name lastName email profileImage')
      .populate('interestedUserId', 'name lastName email profileImage')
      .populate('reportId', 'title category imageUrl location')
      .sort({ lastMessageAt: -1 });

    // Calcular mensajes no leídos para cada conversación
    const conversationsWithUnread = conversations.map(conv => {
      const convObj = conv.toObject();
      
      // Contar mensajes no leídos que NO fueron enviados por el usuario actual
      const unreadCount = conv.messages.filter(
        msg => !msg.isRead && msg.senderId.toString() !== req.user.id
      ).length;

      convObj.unreadCount = unreadCount;
      return convObj;
    });

    res.json(conversationsWithUnread);
  } catch (err) {
    console.error('Error al obtener conversaciones:', err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// Obtener conversaciones de un reporte específico (para el autor del reporte)
router.get('/report/:reportId', auth, async (req, res) => {
  try {
    const report = await Report.findById(req.params.reportId);
    if (!report) {
      return res.status(404).json({ message: 'Reporte no encontrado' });
    }

    // Verificar que el usuario es el autor del reporte
    if (report.userId.toString() !== req.user.id) {
      return res.status(403).json({ message: 'No autorizado' });
    }

    const conversations = await Conversation.find({ reportId: req.params.reportId })
      .populate('reportAuthorId', 'name lastName email profileImage')
      .populate('interestedUserId', 'name lastName email profileImage')
      .populate('reportId', 'title category imageUrl')
      .sort({ lastMessageAt: -1 });

    // Calcular mensajes no leídos
    const conversationsWithUnread = conversations.map(conv => {
      const convObj = conv.toObject();
      const unreadCount = conv.messages.filter(
        msg => !msg.isRead && msg.senderId.toString() !== req.user.id
      ).length;
      convObj.unreadCount = unreadCount;
      return convObj;
    });

    res.json(conversationsWithUnread);
  } catch (err) {
    console.error('Error al obtener conversaciones del reporte:', err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// Obtener una conversación específica
router.get('/:id', auth, async (req, res) => {
  try {
    const conversation = await Conversation.findById(req.params.id)
      .populate('reportAuthorId', 'name lastName email profileImage')
      .populate('interestedUserId', 'name lastName email profileImage')
      .populate('reportId', 'title category imageUrl location');

    if (!conversation) {
      return res.status(404).json({ message: 'Conversación no encontrada' });
    }

    // Verificar que el usuario es parte de la conversación
    if (
      conversation.reportAuthorId._id.toString() !== req.user.id &&
      conversation.interestedUserId._id.toString() !== req.user.id
    ) {
      return res.status(403).json({ message: 'No autorizado' });
    }

    res.json(conversation);
  } catch (err) {
    console.error('Error al obtener conversación:', err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// Enviar un mensaje en una conversación
router.post('/:id/messages', auth, async (req, res) => {
  const { message } = req.body;

  if (!message || !message.trim()) {
    return res.status(400).json({ message: 'El mensaje no puede estar vacío' });
  }

  try {
    const conversation = await Conversation.findById(req.params.id);

    if (!conversation) {
      return res.status(404).json({ message: 'Conversación no encontrada' });
    }

    // Verificar que el usuario es parte de la conversación
    if (
      conversation.reportAuthorId.toString() !== req.user.id &&
      conversation.interestedUserId.toString() !== req.user.id
    ) {
      return res.status(403).json({ message: 'No autorizado' });
    }

    // Agregar el mensaje
    conversation.messages.push({
      senderId: req.user.id,
      message: message.trim(),
      isRead: false
    });

    conversation.lastMessageAt = new Date();
    await conversation.save();

    // Poblar y devolver la conversación actualizada
    const updatedConversation = await Conversation.findById(conversation._id)
      .populate('reportAuthorId', 'name lastName email profileImage')
      .populate('interestedUserId', 'name lastName email profileImage')
      .populate('reportId', 'title category imageUrl location');

    // --- LÓGICA DE NOTIFICACIÓN ---
    
    // Determinar el destinatario (el que NO es el remitente)
    const recipientId = conversation.reportAuthorId.toString() === req.user.id 
      ? conversation.interestedUserId 
      : conversation.reportAuthorId;

    // Buscar al usuario destinatario para obtener su token
    const User = require('../models/User'); // Asegúrate de importar el modelo
    const recipient = await User.findById(recipientId);

    if (recipient && recipient.fcmToken) {
      const sender = await User.findById(req.user.id);
      
      const messagePayload = {
        notification: {
          title: `Nuevo mensaje de ${sender.name}`,
          body: message,
        },
        data: {
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
          type: 'chat_message',
          conversationId: conversation._id.toString(),
          otherUserName: `${sender.name} ${sender.lastName}`,
          reportTitle: conversation.reportId.title,
          
        },
        token: recipient.fcmToken
      };

      try {
        await admin.messaging().send(messagePayload);
      } catch (error) {
        console.error('Error enviando notificación FCM:', error);
      }
    }

    res.json(updatedConversation);
  } catch (err) {
    console.error('Error al enviar mensaje:', err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// Marcar mensajes como leídos
router.put('/:id/mark-read', auth, async (req, res) => {
  try {
    const conversation = await Conversation.findById(req.params.id);

    if (!conversation) {
      return res.status(404).json({ message: 'Conversación no encontrada' });
    }

    // Verificar que el usuario es parte de la conversación
    if (
      conversation.reportAuthorId.toString() !== req.user.id &&
      conversation.interestedUserId.toString() !== req.user.id
    ) {
      return res.status(403).json({ message: 'No autorizado' });
    }

    // Marcar como leídos todos los mensajes que NO fueron enviados por el usuario actual
    conversation.messages.forEach(msg => {
      if (msg.senderId.toString() !== req.user.id) {
        msg.isRead = true;
      }
    });

    await conversation.save();

    const updatedConversation = await Conversation.findById(conversation._id)
      .populate('reportAuthorId', 'name lastName email profileImage')
      .populate('interestedUserId', 'name lastName email profileImage')
      .populate('reportId', 'title category imageUrl location');

    res.json(updatedConversation);
  } catch (err) {
    console.error('Error al marcar mensajes como leídos:', err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// Obtener conteo de conversaciones con mensajes no leídos
router.get('/unread/count', auth, async (req, res) => {
  try {
    const conversations = await Conversation.find({
      $or: [
        { reportAuthorId: req.user.id },
        { interestedUserId: req.user.id }
      ]
    });

    let totalUnread = 0;
    conversations.forEach(conv => {
      const unreadCount = conv.messages.filter(
        msg => !msg.isRead && msg.senderId.toString() !== req.user.id
      ).length;
      totalUnread += unreadCount;
    });

    res.json({ unreadCount: totalUnread });
  } catch (err) {
    console.error('Error al obtener conteo de no leídos:', err);
    res.status(500).json({ message: 'Error en el servidor' });
  }
});

// Actualizar FCM Token
router.post('/fcm-token', auth, async (req, res) => {
  try {
    const { token } = req.body;
    await User.findByIdAndUpdate(req.user.id, { fcmToken: token });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: 'Error al guardar token' });
  }
});

module.exports = router;
