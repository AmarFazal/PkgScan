import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {

  void joinRoom({required IO.Socket socket, required String roomId}) {
    socket.emit('join_room', {'room_id': roomId});
  }
}
