#ifndef TORRENT_HANDLER_H
#define TORRENT_HANDLER_H

#include <jni.h>

#ifdef __cplusplus
extern "C" {
#endif

JNIEXPORT void JNICALL Java_com_example_dart_1torrent_1handler_DartTorrentHandlerPlugin_init(JNIEnv *env, jobject obj);
JNIEXPORT jstring JNICALL Java_com_example_dart_1torrent_1handler_DartTorrentHandlerPlugin_start(JNIEnv *env, jobject obj, jstring magnetUrl, jstring downloadPath);
JNIEXPORT jobjectArray JNICALL Java_com_example_dart_1torrent_1handler_DartTorrentHandlerPlugin_getFiles(JNIEnv *env, jobject obj);
JNIEXPORT void JNICALL Java_com_example_dart_1torrent_1handler_DartTorrentHandlerPlugin_stop(JNIEnv *env, jobject obj);

#ifdef __cplusplus
}
#endif

#endif // TORRENT_HANDLER_H