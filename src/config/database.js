const { Pool } = require('pg');

// Configurar pool de conexiones
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' 
    ? { rejectUnauthorized: false } 
    : false,
  max: 20, // Máximo de conexiones en el pool
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

// Event listeners para debugging
pool.on('connect', () => {
  console.log('✅ Nueva conexión a la base de datos');
});

pool.on('error', (err) => {
  console.error('❌ Error inesperado en el pool de base de datos:', err);
});

// Función para crear tablas
const createTables = async () => {
  const client = await pool.connect();
  
  try {
    console.log('📊 Creando tablas en la base de datos...');

    // Tabla de usuarios
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        avatar_url VARCHAR(500),
        bio TEXT,
        phone VARCHAR(20),
        is_online BOOLEAN DEFAULT false,
        last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Índices para búsquedas rápidas
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
      CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
    `);

    // Tabla de mensajes
    await client.query(`
      CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        receiver_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        message_type VARCHAR(20) DEFAULT 'text',
        media_url VARCHAR(500),
        is_read BOOLEAN DEFAULT false,
        is_delivered BOOLEAN DEFAULT false,
        read_at TIMESTAMP,
        delivered_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Índices para mensajes
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_messages_sender ON messages(sender_id);
      CREATE INDEX IF NOT EXISTS idx_messages_receiver ON messages(receiver_id);
      CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);
    `);

    // Tabla de conversaciones (para grupos futuros)
    await client.query(`
      CREATE TABLE IF NOT EXISTS conversations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100),
        is_group BOOLEAN DEFAULT false,
        avatar_url VARCHAR(500),
        created_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Tabla de participantes en conversaciones
    await client.query(`
      CREATE TABLE IF NOT EXISTS conversation_participants (
        id SERIAL PRIMARY KEY,
        conversation_id INTEGER NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(conversation_id, user_id)
      );
    `);

    console.log('✅ Tablas creadas/verificadas exitosamente');
    
  } catch (error) {
    console.error('❌ Error creando tablas:', error);
    throw error;
  } finally {
    client.release();
  }
};

// Función para probar conexión
const testConnection = async () => {
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW()');
    console.log('✅ Conexión a base de datos exitosa:', result.rows[0].now);
    client.release();
    return true;
  } catch (error) {
    console.error('❌ Error conectando a la base de datos:', error.message);
    return false;
  }
};

// Inicializar base de datos
const initDatabase = async () => {
  const isConnected = await testConnection();
  if (isConnected) {
    await createTables();
  } else {
    console.warn('⚠️  No se pudo conectar a la base de datos. Verifica DATABASE_URL en .env');
  }
};

// Ejecutar inicialización
if (process.env.DATABASE_URL && process.env.DATABASE_URL !== 'postgresql://localhost:5432/dunichat') {
  initDatabase();
} else {
  console.warn('⚠️  DATABASE_URL no configurada o usando valor por defecto');
}

module.exports = pool;