//
//  WebMBridge.cpp
//  swift-webm
//
//  Created by Hovik Melikyan on 04.11.25.
//

#include "WebMBridge.h"

#include "../libwebm/mkvmuxer/mkvmuxer.h"
#include "../libwebm/mkvmuxer/mkvwriter.h"
#include "../libwebm/mkvparser/mkvparser.h"
#include "../libwebm/mkvparser/mkvreader.h"

using namespace std;
using namespace mkvparser;


// MARK: - PARSER

struct WebMParserContext {
    unique_ptr<MkvReader> reader; // should be retained for the entire duration of parsing
    unique_ptr<const Segment> segment; // initialized in constructor, guaranteed non-null

    // Current reading pointer
    const Cluster *cluster;
    const BlockEntry *block;
    int frameNumber;
    bool eos;

    inline static WebMParserContext *cast(WebMHandle handle) {
        return static_cast<WebMParserContext *>(handle);
    }

    WebMParserContext(): reader(make_unique<MkvReader>()), segment(), cluster(NULL), block(NULL), frameNumber(0), eos(false) {
    }

    ~WebMParserContext() {
        if (reader)
            reader->Close();
    }
};


WebMHandle webm_parser_create(const char *filename) {
    auto c = make_unique<WebMParserContext>();

    // Open file
    if (c->reader->Open(filename) != 0)
        return NULL;

    // Parse the WebM header
    long long pos = 0;
    EBMLHeader ebmlHeader;
    if (ebmlHeader.Parse(c->reader.get(), pos) < 0)
        return NULL;

    // Create & load segment
    Segment *segment = NULL;
    if (Segment::CreateInstance(c->reader.get(), pos, segment) != 0)
        return NULL;

    if (!segment || segment->Load() < 0)
        return NULL;

    c->segment.reset(segment);

    return c.release();
}


void webm_parser_destroy(WebMHandle handle) {
    delete WebMParserContext::cast(handle);
}


double webm_parser_get_duration(WebMHandle handle) {
    auto c = WebMParserContext::cast(handle);
    if (!c)
        return 0;

    const SegmentInfo *info = c->segment->GetInfo();
    if (!info)
        return 0;

    long long duration_ns = info->GetDuration();
    if (duration_ns < 0)
        return 0;

    return static_cast<double>(duration_ns) / 1000000000.0;
}


// MARK: - TRACK PARSING

long webm_parser_track_count(WebMHandle handle) {
    auto c = WebMParserContext::cast(handle);
    if (!c)
        return 0;

    const Tracks *tracks = c->segment->GetTracks();
    if (!tracks)
        return 0;

    return static_cast<int>(tracks->GetTracksCount());
}


bool webm_parser_track_info(WebMHandle handle, long index, CWebMTrack *out) {
    if (!out)
        return false;

    auto c = WebMParserContext::cast(handle);
    if (!c)
        return false;

    const Tracks *tracks = c->segment->GetTracks();
    if (!tracks)
        return false;

    if (index < 0 || index >= tracks->GetTracksCount())
        return false;

    const Track *track = tracks->GetTrackByIndex(index);
    if (!track)
        return false;

    out->type = track->GetType();
    out->number = track->GetNumber();
    out->uid = track->GetUid();
    out->name = track->GetNameAsUTF8();
    out->codecId = track->GetCodecId();
    out->lacing = track->GetLacing();
    out->defaultDuration = track->GetDefaultDuration();
    out->codecDelay = track->GetCodecDelay();
    out->seekPreRoll = track->GetSeekPreRoll();

    if (out->type == Track::kAudio) {
        const AudioTrack *audioTrack = static_cast<const AudioTrack *>(track);
        out->samplingRate = audioTrack->GetSamplingRate();
        out->channels = audioTrack->GetChannels();
        out->bitDepth = audioTrack->GetBitDepth();
    }
    else {
        out->samplingRate = 0;
        out->channels = 0;
        out->bitDepth = 0;
    }

    return true;
}
