import Flutter
import UIKit
import Transmission  // Hypothetical import

@objc class DartTorrentHandlerPlugin: NSObject, FlutterPlugin {
  private var session: TransmissionSession?
  private var torrent: Torrent?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "dart_torrent_handler", binaryMessenger: registrar.messenger())
    let instance = DartTorrentHandlerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "init":
      session = TransmissionSession()
      result(nil)
    case "start":
      guard let args = call.arguments as? [String: String],
            let magnetUrl = args["magnetUrl"],
            let downloadPath = args["downloadPath"] else {
        result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        return
      }
      torrent = session?.addTorrent(magnetUrl, downloadPath: downloadPath)
      result(downloadPath)
    case "getFiles":
      let files = torrent?.files.map { $0.path } ?? []
      result(files)
    case "stop":
      torrent?.stop()
      session?.stop()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}