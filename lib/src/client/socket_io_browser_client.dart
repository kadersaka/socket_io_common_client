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

export 'package:socket_io_common_client/src/socket.dart';

import 'package:socket_io_common_client/src/client/socket_io_basic_client.dart' as BasicIO;
import 'package:socket_io_common_client/src/engine/transport/fe/fe_websocket_transport.dart';
import 'package:socket_io_common_client/src/engine/transport/fe/fe_xhr_transport.dart';
import 'package:socket_io_common_client/src/engine/transport/fe/jsonp_transport.dart';
import 'package:socket_io_common_client/src/manager.dart';

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
ioBrowser(uri, [opts]) => BasicIO.io(uri, () {
      return new Manager(
          uri: uri,
          options: opts,
          transportCreator: (String name, options) {
            if ('websocket' == name) {
              return new FEWebSocketTransport(options);
            } else if ('polling' == name) {
              if (options['forceJSONP'] != true) {
                return new FEXHRTransport(options);
              } else {
                if (options['jsonp'] != false)
                  return new JSONPTransport(options);
                throw new StateError('JSONP disabled');
              }
            } else {
              throw new UnsupportedError('Unknown transport $name');
            }
          });
    }, opts);
