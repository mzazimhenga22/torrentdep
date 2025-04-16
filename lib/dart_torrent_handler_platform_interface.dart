import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart_torrent_handler_method_channel.dart';

/// The abstract interface for platform-specific implementations of DartTorrentHandler.
abstract class DartTorrentHandlerPlatform extends PlatformInterface {
  /// Constructs a DartTorrentHandlerPlatform.
  DartTorrentHandlerPlatform() : super(token: _token);

  static final Object _token = Object();

  static DartTorrentHandlerPlatform _instance = MethodChannelDartTorrentHandler();

  /// The default instance of [DartTorrentHandlerPlatform] to use.
  ///
  /// Defaults to [MethodChannelDartTorrentHandler].
  static DartTorrentHandlerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [DartTorrentHandlerPlatform] when
  /// they register themselves.
  static set instance(DartTorrentHandlerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initializes the torrent handler.
  Future<void> init();

  /// Starts downloading a torrent from a magnet URL.
  /// Returns the base path where files are downloaded.
  Future<String> start(String magnetUrl, String downloadPath);

  /// Gets the list of files in the torrent.
  Future<List<String>> getFiles();

  /// Stops the torrent download.
  Future<void> stop();
}