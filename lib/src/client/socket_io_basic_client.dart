/**
 * socket_io_client.dart
 *
 * Purpose:
 *
 * Description:
 *
 * History:
 *   26/04/2017, Created by jumperchen
 *
 * Copyright (C) 2017 Potix Corporation. All Rights Reserved.
 */

library socket_io_client;

import 'package:logging/logging.dart';
import 'package:socket_io_common/src/engine/parser/parser.dart' as Parser;
import 'package:socket_io_common_client/src/engine/parseqs.dart';
import 'package:socket_io_common_client/src/manager.dart';

export 'package:socket_io_common_client/src/socket.dart';

// Protocol version
final protocol = Parser.protocol;

final Map<String, dynamic> cache = {};

final Logger _logger = new Logger('socket_io_client');

/**
 * Looks up an existing `Manager` for multiplexing.
 * If the user summons:
 *
 *   `io('http://localhost/a');`
 *   `io('http://localhost/b');`
 *
 * We reuse the existing instance based on same scheme/port/host,
 * and we initialize sockets for each namespace.
 *
 * @api public
 */
io(uri, Manager managerCreator(), [opts]) => _lookup(uri, opts, managerCreator);

_lookup(uri, opts, Manager managerCreator()) {
  opts = opts ?? <dynamic, dynamic>{};

  Uri parsed = Uri.parse(uri);
  var id = '${parsed.scheme}://${parsed.host}:${parsed.port}';
  var path = parsed.path;
  var sameNamespace = cache.containsKey(id) && cache[id].nsps.containsKey(path);
  var newConnection = opts['forceNew'] == true ||
      opts['force new connection'] == true ||
      false == opts['multiplex'] ||
      sameNamespace;

  var io;

  if (newConnection) {
    _logger.fine('ignoring socket cache for $uri');
    io = managerCreator();
  } else {
    io = cache[id] ??= managerCreator();
  }
  if (parsed.query.isNotEmpty && opts['query'] == null) {
    opts['query'] = parsed.query;
  } else if (opts != null && opts['query'] is Map) {
    opts['query'] = encode(opts['query']);
  }
  return io.socket(parsed.path.isEmpty ? '/' : parsed.path, opts);
}
