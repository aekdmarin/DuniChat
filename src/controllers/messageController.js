const pool = require('../config/database');

// Obtener conversaciones del usuario
const getConversations = async (req, res) => {
  try {
    const userId = req.userId;

    const query = `
      SELECT DISTINCT ON (other_user.id)
        other_user.id,
        other_user.username,
        other_user.avatar_url,
        other_user.is_online,
        other_user.last_seen,
        m.content as last_message,
        m.created_at as last_message_time,
        m.is_read,
        m.sender_id as last_sender_id
      FROM users other_user
      INNER JOIN messages m ON (
        (m.sender_id = $1 AND m.receiver_id = other_user.id) OR
        (m.receiver_id = $1 AND m.sender_id = other_user.id)
      )
      WHERE other_user.id != $1
      ORDER BY other_user.id, m.created_at DESC
    `;

    const result = await pool.query(query, [userId]);

    res.json({
      success: true,
      data: result.rows.map(row => ({
        userId: row.id,
        username: row.username,
        avatarUrl: row.avatar_url,
        isOnline: row.is_online,
        lastSeen: row.last_seen,
        lastMessage: row.last_message,
        lastMessageTime: row.last_message_time,
        isRead: row.is_read,
        isSentByMe: row.last_sender_id === userId
      }))
    });

  } catch (error) {
    console.error('Error obteniendo conversaciones:', error);
    res.status(500).json({ error: 'Error al obtener conversaciones' });
  }
};

// Obtener mensajes entre dos usuarios
const getMessages = async (req, res) => {
  try {
    const userId = req.userId;
    const { otherUserId } = req.params;
    const { limit = 50, offset = 0 } = req.query;

    const query = `
      SELECT 
        m.*,
        sender.username as sender_username,
        sender.avatar_url as sender_avatar,
        receiver.username as receiver_username
      FROM messages m
      INNER JOIN users sender ON m.sender_id = sender.id
      INNER JOIN users receiver ON m.receiver_id = receiver.id
      WHERE 
        (m.sender_id = $1 AND m.receiver_id = $2) OR
        (m.sender_id = $2 AND m.receiver_id = $1)
      ORDER BY m.created_at DESC
      LIMIT $3 OFFSET $4
    `;

    const result = await pool.query(query, [userId, otherUserId, limit, offset]);

    res.json({
      success: true,
      data: result.rows.reverse() // Más recientes al final
    });

  } catch (error) {
    console.error('Error obteniendo mensajes:', error);
    res.status(500).json({ error: 'Error al obtener mensajes' });
  }
};

// Marcar mensajes como leídos
const markAsRead = async (req, res) => {
  try {
    const userId = req.userId;
    const { senderId } = req.body;

    await pool.query(
      `UPDATE messages 
       SET is_read = true, read_at = CURRENT_TIMESTAMP 
       WHERE receiver_id = $1 AND sender_id = $2 AND is_read = false`,
      [userId, senderId]
    );

    res.json({
      success: true,
      message: 'Mensajes marcados como leídos'
    });

  } catch (error) {
    console.error('Error marcando mensajes como leídos:', error);
    res.status(500).json({ error: 'Error al marcar mensajes' });
  }
};

// Buscar usuarios
const searchUsers = async (req, res) => {
  try {
    const userId = req.userId;
    const { query } = req.query;

    if (!query || query.trim().length < 2) {
      return res.status(400).json({ 
        error: 'La búsqueda debe tener al menos 2 caracteres' 
      });
    }

    const result = await pool.query(
      `SELECT id, username, email, avatar_url, bio, is_online 
       FROM users 
       WHERE id != $1 AND (
         username ILIKE $2 OR 
         email ILIKE $2
       )
       LIMIT 20`,
      [userId, `%${query}%`]
    );

    res.json({
      success: true,
      data: result.rows
    });

  } catch (error) {
    console.error('Error buscando usuarios:', error);
    res.status(500).json({ error: 'Error al buscar usuarios' });
  }
};

module.exports = {
  getConversations,
  getMessages,
  markAsRead,
  searchUsers
};