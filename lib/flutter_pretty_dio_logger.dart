import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PrettyDioLogger extends Interceptor {
  /// Print request header [Options.headers]
  final bool requestHeader;

  /// Print request data [Options.data]
  final bool requestBody;

  /// Print [Response.data]
  final bool responseBody;

  /// Print [Response.headers]
  final bool responseHeader;

  /// Print error message
  final bool error;

  /// Print processing time from request to complete in [inMilliseconds]
  final bool showProcessingTime;

  /// Print error message only in debug mode [kDebugMode]
  final bool debugOnly;

  /// Log printer; defaults logPrint log to console.
  /// In flutter, you'd better use debugPrint.
  /// you can also write log in a file.
  final void Function(String msg) logPrint;

  final JsonEncoder _encoder = const JsonEncoder.withIndent('\t');

  PrettyDioLogger({
    this.requestHeader = false,
    this.requestBody = false,
    this.responseHeader = false,
    this.responseBody = true,
    this.error = true,
    this.showProcessingTime = true,
    this.logPrint = log,
    this.debugOnly = true,
  });

  bool get _canShowLog => ((debugOnly && kDebugMode) || !debugOnly);

  late DateTime _startTime;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_canShowLog) {
      _startTime = DateTime.now();
      _logBlock(isBegin: true, type: 'onRequest');
      final uri = options.uri;
      final method = options.method;
      _defaultLog('Request ║ $method ');
      _defaultLog('Uri ║ ${uri.toString()}');
      if (requestHeader) {
        log('[---requestHeader---]');
        final requestHeaders = <String, dynamic>{};
        requestHeaders.addAll(options.headers);
        requestHeaders['contentType'] = options.contentType?.toString();
        requestHeaders['responseType'] = options.responseType.toString();
        requestHeaders['followRedirects'] = options.followRedirects;
        requestHeaders['connectTimeout'] = options.connectTimeout;
        requestHeaders['receiveTimeout'] = options.receiveTimeout;
        String json = _encoder.convert(requestHeaders);
        _defaultLog(json);
      }
      if (requestBody) {
        log('[---requestBody---]');
        final dynamic data = options.data;
        if (data is Map) {
          String json = _encoder.convert(options.data);
          _defaultLog(json);
        }
        if (data is FormData) {
          final formDataMap = <String, dynamic>{}
            ..addEntries(data.fields)
            ..addEntries(data.files);
          String json = _encoder.convert(formDataMap);
          _defaultLog(json);
        } else {
          _defaultLog(data.toString());
        }
      }
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (_canShowLog) {
      _logBlock(isBegin: true, type: 'onError');
      if (error) {
        _defaultLog(
            'DioError ║ Status: ${err.response?.statusCode} ${err.response?.statusMessage}');
        if (err.response != null && err.response?.data != null) {
          _defaultLog(err.response.toString());
        }
      }
      _logProcessingTime();
      _logBlock(isBegin: false);
    }
    super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_canShowLog) {
      _logBlock(isBegin: true, type: 'onResponse');
      final uri = response.requestOptions.uri;
      final method = response.requestOptions.method;
      _defaultLog(
          'Response ║ $method ║ Status: ${response.statusCode} ${response.statusMessage}');
      _defaultLog('Uri ║ ${uri.toString()}');

      if (responseHeader) {
        log('[---responseHeader---]');
        final responseHeaders = <String, String>{};
        response.headers
            .forEach((k, list) => responseHeaders[k] = list.toString());
        String json = _encoder.convert(responseHeaders);
        _defaultLog(json);
      }

      if (responseBody) {
        log('[---responseBody---]');
        String json = _encoder.convert(response.data);
        _defaultLog(json);
      }
      _logProcessingTime();
      _logBlock(isBegin: false);
    }
    super.onResponse(response, handler);
  }

  void _defaultLog(String msg) {
    log(msg);
  }

  void _logBlock({
    bool isBegin = true,
    String type = '',
  }) {
    log('=============================================$type=========${isBegin ? 'BEGIN' : 'END'}=====================================================================');
  }

  void _logProcessingTime() {
    if (showProcessingTime) {
      log('Processing Time: ${DateTime.now().difference(_startTime).inMilliseconds.toString()} Milliseconds');
    }
  }
}
