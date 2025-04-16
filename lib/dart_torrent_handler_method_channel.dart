import 'dart:async';
import 'package:flutter/services.dart';
import 'dart_torrent_handler_platform_interface.dart';

/// An implementation of [DartTorrentHandlerPlatform] that uses method channels.
class MethodChannelDartTorrentHandler extends DartTorrentHandlerPlatform {
  /// The method channel used to interact with the native platform.
  static const MethodChannel _channel = MethodChannel('dart_torrent_handler');

  @override
  Future<void> init() async {
    await _channel.invokeMethod('init');
  }

  @override
  Future<String> start(String magnetUrl, String downloadPath) async {
    return await _channel.invokeMethod('start', {
      'magnetUrl': magnetUrl,
      'downloadPath': downloadPath,
    });
  }

  @override
  Future<List<String>> getFiles() async {
    return (await _channel.invokeMethod('getFiles')).cast<String>();
  }

  @override
  Future<void> stop() async {
    await _channel.invokeMethod('stop');
  }
}