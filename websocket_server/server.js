
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: '*',
  },
  transports: ['websocket'],
});

const PORT = 3000;

app.get('/', (req, res) => {
  res.send('Servidor WebSocket de DeclaraHorario funcionando');
});


io.on('connection', (socket) => {
  console.log('Cliente conectado:', socket.id);

  socket.emit('conexion_exitosa', {
    mensaje: 'Conexión con DeclaraHorario establecida',
  });

  // Prueba de notificaciones en tiempo real.
  socket.on('probar_notificacion', () => {
    socket.emit('nueva_notificacion', {
      titulo: 'Notificación de prueba',
      mensaje: 'WebSocket está funcionando correctamente.',
    });
  });

  socket.on('disconnect', () => {
    console.log('Cliente desconectado:', socket.id);
  });
});


server.listen(PORT, () => {
  console.log(`Servidor WebSocket iniciado en http://localhost:${PORT}`);
});
