import 'package:dart_torrent_handler/dart_torrent_handler.dart';
import 'package:dart_torrent_handler/dart_torrent_handler_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DartTorrentHandler', () {
    late DartTorrentHandler dartTorrentHandler;
    late TestDartTorrentHandlerPlatform platform;

    setUp(() {
      platform = TestDartTorrentHandlerPlatform();
      DartTorrentHandlerPlatform.instance = platform;
      dartTorrentHandler = DartTorrentHandler();
    });

    test('init', () async {
      await dartTorrentHandler.init();
      expect(platform.initCalled, true);
    });

    test('start', () async {
      const magnetUrl = 'magnet:?xt=urn:btih:example-hash';
      const downloadPath = '/mock/download/path';
      expect(await dartTorrentHandler.start(magnetUrl, downloadPath), downloadPath);
    });

    test('getFiles', () async {
      expect(await dartTorrentHandler.getFiles(), ['file1.mp4', 'file2.mp4']);
    });

    test('stop', () async {
      await dartTorrentHandler.stop();
      expect(platform.stopCalled, true);
    });
  });
}

class TestDartTorrentHandlerPlatform extends DartTorrentHandlerPlatform {
  bool initCalled = false;
  bool stopCalled = false;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  Future<String> start(String magnetUrl, String downloadPath) async {
    return downloadPath;
  }

  @override
  Future<List<String>> getFiles() async {
    return ['file1.mp4', 'file2.mp4'];
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }
}