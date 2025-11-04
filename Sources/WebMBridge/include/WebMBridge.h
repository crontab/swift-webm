//
//  WebMBridge.h
//  swift-webm
//
//  Created by Hovik Melikyan on 04.11.25.
//

#ifndef WebMBridge_h
#define WebMBridge_h

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif


// Opaque handle for Swift interop
typedef void *WebMHandle;


// Intermediary structures for creating Swift-friendly ones

typedef struct CWebMTrack {
    long type;
    long number;
    unsigned long long uid;
    const char* name;
    const char* codecId;
    bool lacing;
    unsigned long long defaultDuration;
    unsigned long long codecDelay;
    unsigned long long seekPreRoll;

    // For audio tracks:
    double samplingRate;
    long long channels;
    long long bitDepth;
} CWebMTrack;


typedef struct CWebMData {
    unsigned char *data;
    long size;
    unsigned long long timestamp;
} CWebMData;


// Parser methods

WebMHandle  webm_parser_create(const char *filepath);
void        webm_parser_destroy(WebMHandle handle);
double      webm_parser_get_duration(WebMHandle handle);
long        webm_parser_track_count(WebMHandle handle);
bool        webm_parser_track_info(WebMHandle handle, long index, CWebMTrack *out);
CWebMData   *webm_parser_read_audio(WebMHandle handle, long number);
void        webm_free_data(CWebMData *data);

#ifdef __cplusplus
}
#endif

#endif /* WebMBridge_h */
