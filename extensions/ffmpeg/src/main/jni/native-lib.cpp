#include <jni.h>
#include <string>
#include <android/log.h>
#include "libavcodec/avcodec.h"

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_myapplication_MainActivity_stringFromJNI(
        JNIEnv* env,
        jobject /* this */) {
    std::string hello = "Hello from C++";
    AVCodec avCodec = AVCodec();
    return env->NewStringUTF(hello.c_str());
}