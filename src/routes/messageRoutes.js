const express = require('express');
const { 
  getConversations, 
  getMessages, 
  markAsRead, 
  searchUsers 
} = require('../controllers/messageController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// Todas las rutas requieren autenticación
router.use(authMiddleware);

// Obtener lista de conversaciones
router.get('/conversations', getConversations);

// Obtener mensajes de una conversación específica
router.get('/:otherUserId', getMessages);

// Marcar mensajes como leídos
router.post('/read', markAsRead);

// Buscar usuarios
router.get('/search/users', searchUsers);

module.exports = router;