
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebSocketService {
  IO.Socket? socket;

  void conectar({
    required void Function(String titulo, String mensaje)
        onNotificacion,
  }) {
    socket = IO.io(
      'http://localhost:3000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.onConnect((_) {
      debugPrint('Conectado al servidor WebSocket');
    });

    socket!.on('conexion_exitosa', (datos) {
      debugPrint('Mensaje del servidor: $datos');
    });

    socket!.on('nueva_notificacion', (datos) {
      final titulo = datos['titulo'] ?? 'Notificación';
      final mensaje = datos['mensaje'] ?? 'Sin mensaje';

      onNotificacion(
        titulo.toString(),
        mensaje.toString(),
      );
    });

    socket!.onConnectError((error) {
      debugPrint('Error de conexión WebSocket: $error');
    });

    socket!.onDisconnect((_) {
      debugPrint('Desconectado del servidor WebSocket');
    });

    socket!.connect();
  }

  void probarNotificacion() {
    if (socket?.connected == true) {
      socket!.emit('probar_notificacion');
    } else {
      debugPrint('No hay conexión con WebSocket');
    }
  }

  void desconectar() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
  }
}
