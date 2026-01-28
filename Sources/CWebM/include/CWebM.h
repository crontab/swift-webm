//
//  CWebM.h
//  swift-webm
//
//  Created by Hovik Melikyan on 04.11.25.
//

#ifndef CWebM_h
#define CWebM_h

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
    unsigned char *bytes;
    long size;
    unsigned long long timestamp;
} CWebMData;


typedef unsigned long long WebMTrackID;


// Parser methods

WebMHandle  webm_parser_create(const char *filepath);
void        webm_parser_destroy(WebMHandle handle);
double      webm_parser_get_duration(WebMHandle handle);
long        webm_parser_track_count(WebMHandle handle);
bool        webm_parser_track_info(WebMHandle handle, long index, CWebMTrack *out);
CWebMData  *webm_parser_read(WebMHandle handle, long trackNumber);
bool        webm_parser_eos(WebMHandle handle);
void        webm_parser_reset(WebMHandle handle);
bool        webm_parser_seek(WebMHandle handle, long trackNumber, double timestamp_seconds);


// Muxer methods

WebMHandle  webm_muxer_create(const char *filepath);
void        webm_muxer_set_max_cluster_duration(WebMHandle handle, unsigned long long duration_ns);
void        webm_muxer_destroy(WebMHandle handle);
bool        webm_muxer_finalize(WebMHandle handle, double duration);
WebMTrackID webm_muxer_add_audio_track(WebMHandle handle, double sampling_frequency, int channels, const char *codec_id, const void* codec_private, long codec_private_size);
bool        webm_muxer_write_audio_frame(WebMHandle handle, WebMTrackID track_id, const CWebMData data);

#ifdef __cplusplus
}
#endif

#endif /* CWebM_h */
