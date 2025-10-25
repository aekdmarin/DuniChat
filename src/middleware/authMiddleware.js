const jwt = require('jsonwebtoken');

const authMiddleware = (req, res, next) => {
  try {
    // Obtener token del header
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({ 
        error: 'Token no proporcionado',
        message: 'Se requiere autenticación para acceder a este recurso'
      });
    }

    // Verificar formato: "Bearer TOKEN"
    const parts = authHeader.split(' ');
    
    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      return res.status(401).json({ 
        error: 'Formato de token inválido',
        message: 'El token debe tener el formato: Bearer <token>'
      });
    }

    const token = parts[1];

    // Verificar token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Agregar información del usuario al request
    req.userId = decoded.userId;
    req.userEmail = decoded.email;
    req.username = decoded.username;

    next();

  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ 
        error: 'Token inválido',
        message: 'El token proporcionado no es válido'
      });
    }

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ 
        error: 'Token expirado',
        message: 'Tu sesión ha expirado. Por favor inicia sesión nuevamente'
      });
    }

    console.error('Error en autenticación:', error);
    return res.status(500).json({ 
      error: 'Error en autenticación',
      message: 'Ocurrió un error al verificar tu token'
    });
  }
};

module.exports = authMiddleware;