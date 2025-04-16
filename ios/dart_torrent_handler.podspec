Pod::Spec.new do |s|
  s.name             = 'dart_torrent_handler'
  s.version          = '1.0.0'
  s.summary          = 'A Dart package for torrent handling on Android and iOS.'
  s.description      = <<-DESC
    A Flutter plugin for handling torrent downloads and streaming, supporting Android and iOS via native libraries (libtorrent for Android, Transmission for iOS).
  DESC
  s.homepage         = 'https://github.com/yourusername/dart_torrent_handler'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Name' => 'your.email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Transmission', '~> 3.0'  # Hypothetical Transmission dependency
  s.platform         = :ios, '12.0'

  # Flutter-specific settings
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end