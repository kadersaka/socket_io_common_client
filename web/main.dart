/**
 * main.dart
 *
 * Purpose:
 *
 * Description:
 *
 * History:
 *   26/07/2017, Created by jumperchen
 *
 * Copyright (C) 2017 Potix Corporation. All Rights Reserved.
 */
import 'package:socket_io_common_client/socket_io_client_for_browser.dart' as BrowserIO;
import 'package:logging/logging.dart';

main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });

  BrowserIO.Socket socket = BrowserIO.ioBrowser('ws://localhost:3000', {
    'transports': ['polling','websocket'],
    'secure': false
  });

  socket.on('connect', (_) {
    print('connect happened');
    socket.emit('chat message', 'init');
  });
  socket.on('event', (data) => print("received "+data));
  socket.on('disconnect', (_) => print('disconnect'));
  socket.on('fromServer', (_) => print(_));
}
