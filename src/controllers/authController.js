const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');

// Registrar nuevo usuario
const register = async (req, res) => {
  try {
    const { username, email, password, phone } = req.body;

    // Validación de campos
    if (!username || !email || !password) {
      return res.status(400).json({ 
        error: 'Username, email y password son requeridos' 
      });
    }

    // Validar formato de email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ 
        error: 'Formato de email inválido' 
      });
    }

    // Validar longitud de username
    if (username.length < 3 || username.length > 50) {
      return res.status(400).json({ 
        error: 'El username debe tener entre 3 y 50 caracteres' 
      });
    }

    // Validar longitud de password
    if (password.length < 6) {
      return res.status(400).json({ 
        error: 'La contraseña debe tener al menos 6 caracteres' 
      });
    }

    // Verificar si el usuario ya existe
    const userExists = await pool.query(
      'SELECT id FROM users WHERE email = $1 OR username = $2',
      [email.toLowerCase(), username.toLowerCase()]
    );

    if (userExists.rows.length > 0) {
      return res.status(409).json({ 
        error: 'El email o username ya está registrado' 
      });
    }

    // Encriptar contraseña
    const hashedPassword = await bcrypt.hash(password, 10);

    // Crear usuario
    const newUser = await pool.query(
      `INSERT INTO users (username, email, password, phone) 
       VALUES ($1, $2, $3, $4) 
       RETURNING id, username, email, phone, created_at`,
      [username.toLowerCase(), email.toLowerCase(), hashedPassword, phone]
    );

    const user = newUser.rows[0];

    // Crear token JWT
    const token = jwt.sign(
      { 
        userId: user.id,
        username: user.username,
        email: user.email
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    // Respuesta exitosa
    res.status(201).json({
      success: true,
      message: 'Usuario registrado exitosamente',
      data: {
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          phone: user.phone,
          createdAt: user.created_at
        },
        token
      }
    });

  } catch (error) {
    console.error('Error en registro:', error);
    res.status(500).json({ 
      error: 'Error al registrar usuario',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Login de usuario
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validación de campos
    if (!email || !password) {
      return res.status(400).json({ 
        error: 'Email y password son requeridos' 
      });
    }

    // Buscar usuario
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ 
        error: 'Credenciales inválidas' 
      });
    }

    const user = result.rows[0];

    // Verificar contraseña
    const validPassword = await bcrypt.compare(password, user.password);

    if (!validPassword) {
      return res.status(401).json({ 
        error: 'Credenciales inválidas' 
      });
    }

    // Actualizar estado online
    await pool.query(
      'UPDATE users SET is_online = true, last_seen = CURRENT_TIMESTAMP WHERE id = $1',
      [user.id]
    );

    // Crear token JWT
    const token = jwt.sign(
      { 
        userId: user.id,
        username: user.username,
        email: user.email
      },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    // Respuesta exitosa
    res.json({
      success: true,
      message: 'Login exitoso',
      data: {
        user: {
          id: user.id,
          username: user.username,
          email: user.email,
          phone: user.phone,
          avatarUrl: user.avatar_url,
          bio: user.bio,
          isOnline: true
        },
        token
      }
    });

  } catch (error) {
    console.error('Error en login:', error);
    res.status(500).json({ 
      error: 'Error al iniciar sesión',
      details: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};

// Obtener perfil del usuario actual
const getProfile = async (req, res) => {
  try {
    const userId = req.userId; // Viene del middleware

    const result = await pool.query(
      `SELECT id, username, email, phone, avatar_url, bio, is_online, last_seen, created_at 
       FROM users WHERE id = $1`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Usuario no encontrado' });
    }

    const user = result.rows[0];

    res.json({
      success: true,
      data: {
        id: user.id,
        username: user.username,
        email: user.email,
        phone: user.phone,
        avatarUrl: user.avatar_url,
        bio: user.bio,
        isOnline: user.is_online,
        lastSeen: user.last_seen,
        createdAt: user.created_at
      }
    });

  } catch (error) {
    console.error('Error obteniendo perfil:', error);
    res.status(500).json({ error: 'Error al obtener perfil' });
  }
};

// Actualizar perfil
const updateProfile = async (req, res) => {
  try {
    const userId = req.userId;
    const { username, bio, phone, avatarUrl } = req.body;

    const updates = [];
    const values = [];
    let paramCount = 1;

    if (username) {
      updates.push(`username = $${paramCount++}`);
      values.push(username.toLowerCase());
    }
    if (bio !== undefined) {
      updates.push(`bio = $${paramCount++}`);
      values.push(bio);
    }
    if (phone !== undefined) {
      updates.push(`phone = $${paramCount++}`);
      values.push(phone);
    }
    if (avatarUrl !== undefined) {
      updates.push(`avatar_url = $${paramCount++}`);
      values.push(avatarUrl);
    }

    if (updates.length === 0) {
      return res.status(400).json({ error: 'No hay campos para actualizar' });
    }

    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    values.push(userId);

    const query = `
      UPDATE users 
      SET ${updates.join(', ')}
      WHERE id = $${paramCount}
      RETURNING id, username, email, phone, avatar_url, bio
    `;

    const result = await pool.query(query, values);

    res.json({
      success: true,
      message: 'Perfil actualizado exitosamente',
      data: result.rows[0]
    });

  } catch (error) {
    console.error('Error actualizando perfil:', error);
    res.status(500).json({ error: 'Error al actualizar perfil' });
  }
};

// Logout
const logout = async (req, res) => {
  try {
    const userId = req.userId;

    await pool.query(
      'UPDATE users SET is_online = false, last_seen = CURRENT_TIMESTAMP WHERE id = $1',
      [userId]
    );

    res.json({
      success: true,
      message: 'Logout exitoso'
    });

  } catch (error) {
    console.error('Error en logout:', error);
    res.status(500).json({ error: 'Error al cerrar sesión' });
  }
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  logout
};