//
//  CWebmMuxer.cpp
//  swift-webm
//
//  Created by Hovik Melikyan on 02.12.25.
//

#include "CWebM.h"

#include <assert.h>
#include <memory>

#include "../libwebm/mkvmuxer/mkvmuxer.h"
#include "../libwebm/mkvmuxer/mkvwriter.h"

using namespace std;
using namespace mkvmuxer;


// MARK: - MUXER

struct WebMMuxerContext {
    std::unique_ptr<MkvWriter> writer;
    std::unique_ptr<Segment> segment;
    int next_track_number;

    WebMMuxerContext(): writer(make_unique<MkvWriter>()), segment(make_unique<Segment>()), next_track_number(1) { }

    inline static WebMMuxerContext *cast(WebMHandle handle) {
        return static_cast<WebMMuxerContext *>(handle);
    }
};


WebMHandle webm_muxer_create(const char *filename) {
    auto c = make_unique<WebMMuxerContext>();

    if (!c->writer->Open(filename))
        return NULL;

    if (!c->segment->Init(c->writer.get()))
        return NULL;

    SegmentInfo *const info = c->segment->GetSegmentInfo();
    info->set_writing_app("hm-swift-webm");

    return c.release();
}


void webm_muxer_set_max_cluster_duration(WebMHandle handle, unsigned long long duration_ns) {
    auto c = WebMMuxerContext::cast(handle);
    if (!c)
        return;
    c->segment->set_max_cluster_duration(duration_ns);
}


void webm_muxer_destroy(WebMHandle handle) {
    delete WebMMuxerContext::cast(handle);
}


bool webm_muxer_finalize(WebMHandle handle, double duration) {
    auto c = WebMMuxerContext::cast(handle);
    if (!c)
        return false;

    SegmentInfo *const info = c->segment->GetSegmentInfo();
    info->set_duration(duration);

    bool result = c->segment->Finalize();
    c->writer->Close();

    return result;
}


WebMTrackID webm_muxer_add_audio_track(WebMHandle handle, double sampling_frequency, int channels, const char *codec_id) {
    auto c = WebMMuxerContext::cast(handle);
    if (!c)
        return 0;

    int track_number = c->next_track_number++;

    auto result = c->segment->AddAudioTrack(static_cast<int>(sampling_frequency), channels, track_number);

    if (!result)
        return 0;

    AudioTrack *audio_track = static_cast<AudioTrack *>(c->segment->GetTrackByNumber(result));

    if (!audio_track)
        return 0;

    audio_track->set_codec_id(codec_id);
    audio_track->set_bit_depth(16);

    return result;
}


bool webm_muxer_write_audio_frame(WebMHandle handle, WebMTrackID track_id, const CWebMData data) {
    auto c = WebMMuxerContext::cast(handle);
    if (!c)
        return false;

    if (data.size <= 0 || !data.bytes)
        return false;

    Frame muxer_frame;
    if (!muxer_frame.Init(data.bytes, data.size))
        return false;

    muxer_frame.set_track_number(track_id);
    muxer_frame.set_timestamp(data.timestamp);
    muxer_frame.set_is_key(true); // Audio frames should be keyframes

    if (!c->segment->AddGenericFrame(&muxer_frame))
        return false;

    return true;
}
