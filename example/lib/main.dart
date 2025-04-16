import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dart_torrent_handler/dart_torrent_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

// Logger helps trace each step; useful for real-device debugging.
final Logger logger = Logger(level: Level.info);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Not started';
  List<String> _torrentFiles = [];
  final DartTorrentHandler _torrentHandler = DartTorrentHandler();

  @override
  void initState() {
    super.initState();
    // Use a slight delay before starting so the UI is rendered first.
    Future.delayed(const Duration(milliseconds: 500), initTorrentHandler);
  }

  // The main method that performs each step of the torrent operation.
  Future<void> initTorrentHandler() async {
    try {
      // STEP 1: Request necessary storage permissions
      setState(() {
        _status = 'Requesting storage permissions...';
      });
      logger.i('[Step 1] Requesting storage permissions.');
      bool hasPermission = await _requestStoragePermissions();
      if (!hasPermission) {
        setState(() {
          _status = 'Storage permission denied';
        });
        logger.e('[Step 1] Storage permission denied.');
        return;
      }
      logger.i('[Step 1] Storage permissions granted.');

      // STEP 2: Initialize the torrent handler plugin.
      setState(() {
        _status = 'Initializing torrent handler...';
      });
      logger.i('[Step 2] Initializing torrent handler plugin.');
      await _torrentHandler.init().timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Plugin initialization timed out.');
      });
      setState(() {
        _status = 'Torrent handler initialized';
      });
      logger.i('[Step 2] Torrent handler initialized.');

      // STEP 3: Get download directory from the device.
      setState(() {
        _status = 'Obtaining download directory...';
      });
      final downloadDir = await getTemporaryDirectory().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Failed to retrieve temporary directory.');
        },
      );
      final downloadPath = downloadDir.path;
      logger.i('[Step 3] Download directory: $downloadPath');
      
      // STEP 4: Start the torrent download.
      // Replace the below magnet URL with a valid one for your real test.
      const magnetUrl =
          'magnet:?xt=urn:btih:example-hash&dn=example-torrent';
      setState(() {
        _status = 'Starting torrent download...';
      });
      logger.i('[Step 4] Starting torrent download using magnet URL: $magnetUrl');
      String path = await _torrentHandler.start(magnetUrl, downloadPath).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Torrent download start timed out.');
        },
      );
      setState(() {
        _status = 'Downloading to: $path';
      });
      logger.i('[Step 4] Torrent download started. Download path: $path');

      // STEP 5: Retrieve the list of downloaded files.
      setState(() {
        _status = 'Retrieving torrent files...';
      });
      List<String> files = await _torrentHandler.getFiles().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Retrieving torrent files timed out.');
        },
      );
      setState(() {
        _torrentFiles = files;
        _status = 'Torrent download complete with ${files.length} file(s)';
      });
      logger.i('[Step 5] Retrieved ${files.length} torrent file(s).');
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
      logger.e('[Error] $e');
    }
  }

  // Requests the necessary permissions for storage (and manage external storage for Android 13+).
  Future<bool> _requestStoragePermissions() async {
    // Check storage permission for Android.
    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      storageStatus = await Permission.storage.request();
    }
    
    // For Android 13 and above, request manage external storage if needed.
    if (!storageStatus.isGranted) {
      var manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        manageStatus = await Permission.manageExternalStorage.request();
      }
      return manageStatus.isGranted;
    }

    return storageStatus.isGranted;
  }

  // Ensure that the torrent download is stopped when the widget is disposed.
  @override
  void dispose() {
    _torrentHandler.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dart Torrent Handler Example',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Dart Torrent Handler Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status: $_status',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text('Torrent Files:'),
              const SizedBox(height: 8),
              Expanded(
                child: _torrentFiles.isEmpty
                    ? const Center(child: Text('No files found.'))
                    : ListView.builder(
                        itemCount: _torrentFiles.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(_torrentFiles[index]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
