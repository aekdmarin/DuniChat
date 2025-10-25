# DuniChat Backend

Backend para aplicación de mensajería en tiempo real tipo WhatsApp/Telegram.

## Tecnologías

- Node.js + Express
- Socket.io (mensajería en tiempo real)
- PostgreSQL (base de datos)
- JWT (autenticación)

## Instalación
```bash
npm install
```

## Desarrollo
```bash
npm run dev
```

## Producción
```bash
npm start
```

## Variables de entorno necesarias

- `PORT`: Puerto del servidor
- `DATABASE_URL`: URL de conexión a PostgreSQL
- `JWT_SECRET`: Secreto para tokens JWT
- `NODE_ENV`: Entorno (development/production)