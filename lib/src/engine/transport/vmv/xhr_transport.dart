import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:socket_io_common/src/util/event_emitter.dart';
import 'package:socket_io_common_client/src/engine/transport/polling_transport.dart';

/**
 * xhr_transport.dart
 *
 * Purpose:
 *
 * Description:
 *
 * History:
 *   27/04/2017, Created by jumperchen
 *
 * Copyright (C) 2017 Potix Corporation. All Rights Reserved.
 */

final Logger _logger = new Logger('socket_io_client:transport.XHRTransport');

class XHRTransport extends PollingTransport {
  int requestTimeout;
  bool xd;
  bool xs;
  String cookieRef = null;
  Map<String, dynamic> opts;

//  Request sendXhr;
//  Request pollXhr;

  /**
   * XHR Polling constructor.
   *
   * @param {Object} opts
   * @api public
   */
  XHRTransport(Map opts) : super(opts) {
    this.requestTimeout = opts['requestTimeout'];
//    this.extraHeaders = opts.extraHeaders;

    // some user agents have empty `location.port`
    if (port == null) {
      port = 80;
    }

    this.xd = opts['xd'] ?? false;
    this.xs = opts['xs'] ?? false;
    this.opts = opts;
  }

  /**
   * XHR supports binary
   */
  bool supportsBinary = true;

  /**
   * Creates a request.
   *
   * @api private
   */
  request([Map opts]) {
    opts = opts ?? {};
    opts['uri'] = this.uri();
    opts['xd'] = this.xd;
    opts['xs'] = this.xs;
    opts['agent'] = this.agent ?? false;
    opts['supportsBinary'] = this.supportsBinary;
    opts['enablesXDR'] = this.enablesXDR;

    // SSL options for Node.js client
//    opts.pfx = this.pfx;
//    opts.key = this.key;
//    opts.passphrase = this.passphrase;
//    opts.cert = this.cert;
//    opts.ca = this.ca;
//    opts.ciphers = this.ciphers;
//    opts.rejectUnauthorized = this.rejectUnauthorized;
//    opts.requestTimeout = this.requestTimeout;

    // other options for Node.js client
//    opts.extraHeaders = this.extraHeaders;

    return new Request(opts);
  }

  /**
   * Sends data.
   *
   * @param {String} data to send.
   * @param {Function} called upon flush.
   * @api private
   */
  doWrite(data, fn) {
    var isBinary = data is! String;
    var req = this.request({
      'method': 'POST',
      'data': data,
      'isBinary': isBinary,
      'request-header-processer': this.opts['request-header-processer'],
      'response-header-processer': this.opts['response-header-processer']
    });
    req.on('success', fn);
    req.on('error', (err) {
      onError('xhr post error', err);
    });
  }

  /**
   * Starts a poll cycle.
   *
   * @api private
   */
  doPoll() {
    _logger.fine('xhr poll');
    var req = this.request(opts);
    req.on('data', (data) {
      onData(data);
    });
    req.on('error', (err) {
      onError('xhr poll error', err);
    });
  }
}

/**
 * Request constructor
 *
 * @param {Object} options
 * @api public
 */
class Request extends EventEmitter {
  String uri;
  bool xd;
  bool xs;
  bool async;
  var data;
  bool agent;
  bool isBinary;
  bool supportsBinary;
  bool enablesXDR;
  int requestTimeout;
  String method;
  StreamSubscription readyStateChange;
  HttpClientRequest req;
  HttpClientResponse resp;

  Function requestHeaderProcessor;
  Function responseHeaderProcessor;

  Request(Map opts) {
    this.method = opts['method'] ?? 'GET';
    this.uri = opts['uri'];
    this.xd = opts['xd'] == true;
    this.xs = opts['xs'] == true;
    this.async = opts['async'] != false;
    this.data = opts['data'];
    this.agent = opts['agent'];
    this.isBinary = opts['isBinary'];
    this.supportsBinary = opts['supportsBinary'];
    this.enablesXDR = opts['enablesXDR'];
    this.requestTimeout = opts['requestTimeout'];

    this.requestHeaderProcessor = opts['request-header-processer'] ?? (_) => _;
    this.responseHeaderProcessor =
        opts['response-header-processer'] ?? (_) => _;

    this.create();
  }

  /**
   * Creates the XHR object and sends the request.
   *
   * @api private
   */
  create() {
    HttpClient httpClient = HttpClient();

    try {
      _logger.fine('xhr open ${this.method}: ${this.uri}');
      httpClient.openUrl(this.method, Uri.parse(this.uri)).then((req) {
        this.req = req;
//        return req.close();
        if ('POST' == this.method) {
          try {
            if (this.isBinary) {
              this.req.headers.add('Content-type', 'application/octet-stream');
            } else {
              this.req.headers.add('Content-type', 'text/plain;charset=UTF-8');
            }
          } catch (e) {}
        }

        try {
          this.req.headers.add('Accept', '*/*');
        } catch (e) {}

        _logger.fine('xhr data ${this.data}');

        var reqHeader = this.req.headers;
        this.requestHeaderProcessor(reqHeader);
        _logger.fine("make req with header" + reqHeader.toString());

        if (this.data != null) {
          req.add(utf8.encode(this.data));
        }

        return req.close();
      }).then((HttpClientResponse response) {
        this.responseHeaderProcessor(response.headers);
        if (200 == response.statusCode || 1223 == response.statusCode) {
          this.onLoad(response);
        } else {
          Timer.run(() => this.onError(response.statusCode));
        }
      });
    } catch (e) {
      Timer.run(() => onError(e));
      return;
    }
  }

  /**
   * Called upon successful response.
   *
   * @api private
   */
  onSuccess() {
    this.emit('success');
    this.cleanup();
  }

  /**
   * Called if we have data.
   *
   * @api private
   */
  onData(data) {
    this.emit('data', data);
    this.onSuccess();
  }

  /**
   * Called upon error.
   *
   * @api private
   */
  onError(err) {
    this.emit('error', err);
    this.cleanup(true);
  }

  /**
   * Cleans up house.
   *
   * @api private
   */
  cleanup([fromError]) {
    if (this.req == null) {
      return;
    }
    // xmlhttprequest
    if (this.hasXDR()) {
    } else {
      readyStateChange?.cancel();
      readyStateChange = null;
    }

    if (fromError != null) {
      try {
        this.req.close();
      } catch (e) {}
    }

    this.req = null;
  }

  /**
   * Called upon load.
   *
   * @api private
   */
  onLoad(HttpClientResponse resp) {
    var data;
    try {
      var contentType;
      try {
        contentType = resp.headers.contentType;
      } catch (e) {}
      if (contentType == 'application/octet-stream') {
        data = resp;
      } else {
        data = resp.transform(utf8.decoder).join();
      }
    } catch (e) {
      this.onError(e);
    }
    if (null != data) {
      if (data is ByteBuffer) {
        this.onData(data.asUint8List());
      } else {
        data.then((val) {
          this.onData(val);
        });
      }
    }
  }

  /**
   * Check if it has XDomainRequest.
   *
   * @api private
   */
  hasXDR() {
    // Todo: handle it in dart way
    return false;
    //  return 'undefined' !== typeof global.XDomainRequest && !this.xs && this.enablesXDR;
  }

  /**
   * Aborts the request.
   *
   * @api public
   */
  abort() => cleanup();
}
