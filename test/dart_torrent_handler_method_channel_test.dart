import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_torrent_handler/dart_torrent_handler_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel('dart_torrent_handler');
  MethodChannelDartTorrentHandler platform = MethodChannelDartTorrentHandler();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'init':
          return null;
        case 'start':
          return '/mock/download/path';
        case 'getFiles':
          return ['file1.mp4', 'file2.mp4'];
        case 'stop':
          return null;
        default:
          throw UnimplementedError('Method ${methodCall.method} not mocked');
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('init', () async {
    await platform.init();
    // Since init returns void, we just verify it doesn't throw
    expect(true, true);
  });

  test('start', () async {
    const magnetUrl = 'magnet:?xt=urn:btih:example-hash';
    const downloadPath = '/mock/download/path';
    expect(await platform.start(magnetUrl, downloadPath), downloadPath);
  });

  test('getFiles', () async {
    expect(await platform.getFiles(), ['file1.mp4', 'file2.mp4']);
  });

  test('stop', () async {
    await platform.stop();
    // Since stop returns void, we just verify it doesn't throw
    expect(true, true);
  });
}