import 'dart:async';
import 'dart_torrent_handler_platform_interface.dart';

/// A Dart package for handling torrent downloads and streaming.
class DartTorrentHandler {
  DartTorrentHandler() {
    _platform = DartTorrentHandlerPlatform.instance;
  }

  late final DartTorrentHandlerPlatform _platform;

  /// Initializes the torrent handler.
  Future<void> init() async {
    await _platform.init();
  }

  /// Starts downloading a torrent from a magnet URL.
  /// Returns the base path where files are downloaded.
  Future<String> start(String magnetUrl, String downloadPath) async {
    return await _platform.start(magnetUrl, downloadPath);
  }

  /// Gets the list of files in the torrent.
  Future<List<String>> getFiles() async {
    return await _platform.getFiles();
  }

  /// Stops the torrent download.
  Future<void> stop() async {
    await _platform.stop();
  }
}