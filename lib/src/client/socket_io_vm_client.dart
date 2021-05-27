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

import 'package:socket_io_common_client/src/engine/transport/vmv/websocket_transport.dart';
import 'package:socket_io_common_client/src/engine/transport/vmv/xhr_transport.dart';
import 'package:socket_io_common_client/src/manager.dart';
import 'package:socket_io_common_client/src/client/socket_io_basic_client.dart'
    as BasicIO;
export 'package:socket_io_common_client/src/socket.dart';

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
io(uri, [opts]) => BasicIO.io(uri, () {
      return new Manager(
          uri: uri,
          options: opts,
          transportCreator: (String name, options) {
            if ('websocket' == name) {
              return new WebSocketTransport(options);
            } else if ('polling' == name) {
              if (options['forceJSONP'] != true) {
                options["request-header-processer"] =
                    opts["request-header-processer"];
                options["response-header-processer"] =
                    opts["response-header-processer"];
                return new XHRTransport(options);
              } else {
                throw new StateError('JSONP disabled');
              }
            } else {
              throw new UnsupportedError('Unknown transport $name');
            }
          });
    }, opts);
