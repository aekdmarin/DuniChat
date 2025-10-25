const express = require('express');
const { 
  register, 
  login, 
  getProfile, 
  updateProfile, 
  logout 
} = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// Rutas públicas (sin autenticación)
router.post('/register', register);
router.post('/login', login);

// Rutas protegidas (requieren autenticación)
router.get('/profile', authMiddleware, getProfile);
router.put('/profile', authMiddleware, updateProfile);
router.post('/logout', authMiddleware, logout);

module.exports = router;