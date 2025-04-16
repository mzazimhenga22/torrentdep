package com.example.dart_torrent_handler

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class DartTorrentHandlerPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel

  init {
    System.loadLibrary("torrent_handler")
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "dart_torrent_handler")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "init" -> {
        init()
        result.success(null)
      }
      "start" -> {
        val magnetUrl = call.argument<String>("magnetUrl") ?: return result.error("INVALID_ARGUMENT", "Magnet URL is missing", null)
        val downloadPath = call.argument<String>("downloadPath") ?: return result.error("INVALID_ARGUMENT", "Download path is missing", null)
        val path = start(magnetUrl, downloadPath)
        result.success(path)
      }
      "getFiles" -> {
        val files = getFiles()
        result.success(files?.toList())
      }
      "stop" -> {
        stop()
        result.success(null)
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private external fun init()
  private external fun start(magnetUrl: String, downloadPath: String): String
  private external fun getFiles(): Array<String>?
  private external fun stop()
}