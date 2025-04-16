#include "torrent_handler.h"
#include <libtorrent/session.hpp>
#include <libtorrent/add_torrent_params.hpp>
#include <libtorrent/torrent_handle.hpp>
#include <libtorrent/torrent_info.hpp>
#include <libtorrent/error_code.hpp>
#include <libtorrent/alert_types.hpp>
#include <libtorrent/sha1_hash.hpp>
// Removed: #include <libtorrent/aux_/bytes.hpp>
#include <vector>
#include <string>
#include <thread>
#include <chrono>
#include <android/log.h>
#include <cstdlib>      // for strtol

// Global variables to manage the libtorrent session and torrent handle
static lt::session* session = nullptr;
static lt::torrent_handle torrent;

// Logging macro for Android
#define LOG_TAG "TorrentHandler"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Helper function to convert a hex string (without any whitespace) into a byte array.
// Assumes that the length of the hex string is even.
bool hex_to_bytes(const std::string& hex, char* bytes) {
    if (hex.length() % 2 != 0)
        return false;
    for (size_t i = 0; i < hex.length(); i += 2) {
        std::string byteString = hex.substr(i, 2);
        // Using strtol to convert each pair of hex characters to a byte
        char b = static_cast<char>(strtol(byteString.c_str(), nullptr, 16));
        bytes[i / 2] = b;
    }
    return true;
}

// Helper function to parse info hash from a magnet URI
bool parse_info_hash_from_magnet(const std::string& magnet, lt::sha1_hash& info_hash, lt::error_code& ec) {
    // A simple magnet URI parser to extract the info hash
    // Magnet URI format: magnet:?xt=urn:btih:<info-hash>&...
    const std::string prefix = "magnet:?xt=urn:btih:";
    auto pos = magnet.find(prefix);
    if (pos != 0) {
        ec = lt::error_code(lt::errors::invalid_request, lt::generic_category());
        return false;
    }

    // Extract the info hash (40 characters for SHA-1 in hex)
    std::string hash_str = magnet.substr(prefix.length(), 40);
    if (hash_str.length() != 40) {
        ec = lt::error_code(lt::errors::invalid_request, lt::generic_category());
        return false;
    }

    // Convert hex string to 20-byte array
    char hash_bytes[20];
    if (!hex_to_bytes(hash_str, hash_bytes)) {
        ec = lt::error_code(lt::errors::invalid_request, lt::generic_category());
        return false;
    }

    // Construct sha1_hash from byte array
    info_hash = lt::sha1_hash(hash_bytes);

    if (info_hash.is_all_zeros()) {
        ec = lt::error_code(lt::errors::invalid_request, lt::generic_category());
        return false;
    }

    return true;
}

// JNI initialization: Create the libtorrent session
extern "C" JNIEXPORT void JNICALL Java_com_example_dart_1torrent_1handler_DartTorrentHandlerPlugin_init(JNIEnv *env, jobject obj) {
    LOGI("Initializing libtorrent session");
    if (session == nullptr) {
        lt::settings_pack settings;
        // Set desired alert types (status and error notifications are enabled)
        settings.set_int(lt::settings_pack::alert_mask, lt::alert::error_notification | lt::alert::status_notification);
        session = new lt::session(settings);
        LOGI("libtorrent session initialized");
    } else {
        LOGI("libtorrent session already initialized");
    }
}

// JNI method to start a torrent using a magnet URI and download path.
extern "C" JNIEXPORT jstring JNICALL Java_com_example_dart_1torrent_1handler_DartTorrentHandlerPlugin_start(JNIEnv *env, jobject obj, jstring magnetUrl, jstring downloadPath) {
    const char* magnet = env->GetStringUTFChars(magnetUrl, nullptr);
    const char* path = env->GetStringUTFChars(downloadPath, nullptr);

    LOGI("Starting torrent with magnet URL: %s, download path: %s", magnet, path);

    lt::add_torrent_params params;
    lt::error_code ec;

    // Parse the info hash from the magnet URI using our own helper function
    lt::sha1_hash info_hash;
    if (!parse_info_hash_from_magnet(magnet, info_hash, ec)) {
        LOGE("Failed to parse magnet URI: %s", ec.message().c_str());
        env->ReleaseStringUTFChars(magnetUrl, magnet);
        env->ReleaseStringUTFChars(downloadPath, path);
        return env->NewStringUTF("");
    }

    // Set the info hash and save path in add_torrent_params
    params.info_hashes.v1 = info_hash;
    params.save_path = path;

    // Add the torrent to the session
    torrent = session->add_torrent(params, ec);
    if (ec) {
        LOGE("Failed to add torrent: %s", ec.message().c_str());
        env->ReleaseStringUTFChars(magnetUrl, magnet);
        env->ReleaseStringUTFChars(downloadPath, path);
        return env->NewStringUTF("");
    }

    // Wait for metadata using alerts
    bool metadata_received = false;
    while (!metadata_received && torrent.is_valid()) {
        session->wait_for_alert(std::chrono::milliseconds(100));
        std::vector<lt::alert*> alerts;
        session->pop_alerts(&alerts);
        for (auto const& alert : alerts) {
            // Checking for metadata_received_alert (by comparing alert type)
            if (alert->type() == lt::metadata_received_alert::alert_type) {
                metadata_received = true;
                LOGI("Metadata received for torrent");
                break;
            }
        }
    }

    if (!torrent.is_valid() || !torrent.torrent_file()) {
        LOGE("Failed to retrieve torrent metadata");
        env->ReleaseStringUTFChars(magnetUrl, magnet);
        env->ReleaseStringUTFChars(downloadPath, path);
        return env->NewStringUTF("");
    }

    LOGI("Torrent added successfully");

    env->ReleaseStringUTFChars(magnetUrl, magnet);
    env->ReleaseStringUTFChars(downloadPath, path);

    return env->NewStringUTF(path);
}

// JNI method to get the list of file paths inside the torrent
extern "C" JNIEXPORT jobjectArray JNICALL Java_com_example_dart_1torrent_1handler_DartTorrentHandlerPlugin_getFiles(JNIEnv *env, jobject obj) {
    if (!torrent.is_valid()) {
        LOGE("Torrent handle is invalid");
        return nullptr;
    }

    auto torrentInfo = torrent.torrent_file();
    if (!torrentInfo) {
        LOGE("Torrent info not available");
        return nullptr;
    }

    auto files = torrentInfo->files();
    int numFiles = files.num_files();
    LOGI("Found %d files in torrent", numFiles);

    jclass stringClass = env->FindClass("java/lang/String");
    jobjectArray result = env->NewObjectArray(numFiles, stringClass, nullptr);

    for (int i = 0; i < numFiles; i++) {
        std::string filePath = files.file_path(i);
        jstring fileName = env->NewStringUTF(filePath.c_str());
        env->SetObjectArrayElement(result, i, fileName);
        env->DeleteLocalRef(fileName);
    }

    return result;
}

// JNI method to stop the torrent and clean up the libtorrent session
extern "C" JNIEXPORT void JNICALL Java_com_example_dart_1torrent_1handler_DartTorrentHandlerPlugin_stop(JNIEnv *env, jobject obj) {
    LOGI("Stopping torrent");
    if (session != nullptr && torrent.is_valid()) {
        session->remove_torrent(torrent);
        LOGI("Torrent stopped");
    }

    if (session != nullptr) {
        delete session;
        session = nullptr;
        LOGI("libtorrent session destroyed");
    }
}
