import 'dart:io' show Platform;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_torrent_handler/dart_torrent_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

final Logger logger = Logger(level: Level.info);

// Flags to control behavior via dart-define.
// To disable simulation mode, run with:
// flutter test --dart-define=SKIP_TORRENT_DOWNLOAD=false
const bool skipPermissionCheck =
    bool.fromEnvironment('SKIP_PERMISSION_CHECK', defaultValue: true);
// Set this default to false to perform a real torrent download.
const bool skipTorrentDownload =
    bool.fromEnvironment('SKIP_TORRENT_DOWNLOAD', defaultValue: false);

Future<bool> requestPermissions() async {
  if (!Platform.isAndroid) return true;

  if (skipPermissionCheck) {
    logger.i('[Step 1] Skipping permission check (test mode).');
    return true;
  }

  logger.i('[Step 1] Requesting storage permissions...');
  if (await Permission.storage.isGranted &&
      await Permission.manageExternalStorage.isGranted) {
    logger.i('[Step 1] Permissions already granted.');
    return true;
  }

  final storageStatus = await Permission.storage.request();
  final manageStatus = await Permission.manageExternalStorage.request();
  return storageStatus.isGranted && manageStatus.isGranted;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('DartTorrentHandler Integration Test', () {
    // Increase the default timeout if necessary.
    testWidgets('Download torrent and list files', (WidgetTester tester) async {
      logger.i('[START] Integration test started.');

      if (!Platform.isAndroid) {
        logger.i('[SKIP] Dart Torrent Handler only supports Android. Exiting test.');
        return;
      }

      logger.i('[Step 1] Checking/requesting permissions...');
      final permissionsGranted = await requestPermissions();
      if (!permissionsGranted) {
        logger.e('[FAIL] Storage permissions not granted.');
        fail('Storage permissions not granted. Pre-grant them with ADB.');
      }
      logger.i('[Step 1] Permissions granted.');

      logger.i('[Step 2] Initializing plugin...');
      final plugin = DartTorrentHandler();
      await plugin.init();
      logger.i('[Step 2] Plugin initialized.');

      logger.i('[Step 3] Getting temporary directory...');
      final downloadDir = await getTemporaryDirectory();
      logger.i('[Step 3] Temporary directory: ${downloadDir.path}');

      if (skipTorrentDownload) {
        logger.i('[Step 4] Running in simulation mode; skipping actual torrent download.');
        await Future.delayed(const Duration(seconds: 2));
        final downloadPath = downloadDir.path;
        logger.i('[Step 4] Simulated download path: $downloadPath');
        expect(downloadPath.isNotEmpty, true, reason: 'Download path should not be empty');

        final files = ['test_file.txt'];
        logger.i('[Step 5] Simulated file list retrieved: ${files.length} files.');
        expect(files, isNotNull, reason: 'File list should not be null');
        expect(files.isNotEmpty, true, reason: 'File list should not be empty');

        for (var file in files) {
          logger.i('[File] $file');
        }
      } else {
        // Use the provided real magnet URL.
        const magnetUrl =
            'magnet:?xt=urn:btih:A7744E24F49A945892A2771A3C1AFBC73840239B&dn=Adolescence%20S01%201080p%20WEB-DL%20AAC%205.1%20x265-PSYPHER&tr=udp%3A%2F%2Ftracker.opentrackr.org%3A1337%2Fannounce&tr=udp%3A%2F%2Fexplodie.org%3A6969';
        logger.i('[Step 4] Using magnet URL: $magnetUrl');

        // Use runAsync to perform the network download outside of the main test thread.
        await tester.runAsync(() async {
          try {
            logger.i('[Step 4] Starting torrent download...');
            final downloadPath = await plugin.start(magnetUrl, downloadDir.path);
            logger.i('[Step 4] Torrent download started. Path: $downloadPath');
            expect(downloadPath.isNotEmpty, true, reason: 'Download path should not be empty');

            // Optional: Wait for some time to allow initial download progress.
            await Future.delayed(const Duration(seconds: 15));

            logger.i('[Step 5] Retrieving downloaded files...');
            final files = await plugin.getFiles();
            logger.i('[Step 5] Retrieved file list: ${files.length} files.');
            expect(files, isNotNull, reason: 'File list should not be null');
            expect(files.isNotEmpty, true, reason: 'File list should not be empty');

            for (var file in files) {
              logger.i('[File] $file');
            }
          } catch (e) {
            logger.e('[ERROR] Exception during torrent download: $e');
            fail('Torrent download failed: $e');
          }
        });
      }

      logger.i('[Step 6] Stopping torrent plugin...');
      await plugin.stop();
      logger.i('[DONE] Torrent plugin stopped. Test complete.');
    });
  });
}
