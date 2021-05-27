import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:socket_io_common_client/socket_io_client.dart' as IO;
import 'package:logging/logging.dart';

class ReadSender implements StreamConsumer<List<int>> {
  IO.Socket socket;

  ReadSender(IO.Socket this.socket);

  @override
  Future addStream(Stream<List<int>> stream) {
    return stream.transform(utf8.decoder).forEach((content) {
      print(content);
      this.socket.emit("chat message", content);
    }).timeout(Duration(days: 30));
  }

  @override
  Future close() {
    return null;
  }
}

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  stdout.writeln('Type something');

  List<String> cookie = null;

  IO.Socket socket = IO.io('https://localhost:3000', {
    'secure': false,
    'path': '/socket.io',
    'transports': ['polling'],
    'request-header-processer': (requestHeader) {
      print("get request header " + requestHeader.toString());
      if (cookie != null) {
        requestHeader.add('cookie', cookie);
        print("set cookie success");
      }else{
        print("set cookie faield");
      }
    },
    'response-header-processer': (responseHeader) {
      print("get response header " + responseHeader.toString());
      if (responseHeader['set-cookie'] != null) {
        cookie = responseHeader['set-cookie'];
        print("receive cookie success");
      } else {
        print("receive cookie failed");
      }
    },
  });
  socket.on('connect', (_) {
    print('connect happened');
    socket.emit('chat message', 'init');
  });
  socket.on('req-header-event', (data) {
    print("req-header-event " + data.toString());
  });
  socket.on('resp-header-event', (data) {
    print("resp-header-event " + data.toString());
  });
  socket.on('event', (data) => print("received " + data));
  socket.on('disconnect', (_) => print('disconnect'));
  socket.on('fromServer', (_) => print(_));
  await stdin.pipe(ReadSender(socket));
}
