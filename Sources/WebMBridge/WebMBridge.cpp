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


// MARK: - PARSER

struct WebMParserContext {
    std::unique_ptr<mkvparser::MkvReader> reader;
    std::unique_ptr<mkvparser::Segment> segment;

    inline static WebMParserContext *cast(WebMParserHandle handle) {
        return static_cast<WebMParserContext *>(handle);
    }

    ~WebMParserContext() {
        if (reader)
            reader->Close();
    }
};


WebMParserHandle webm_parser_create(const char *filename) {
    auto context = std::make_unique<WebMParserContext>();

    // Create reader
    context->reader = std::make_unique<mkvparser::MkvReader>();

    // Open file
    if (context->reader->Open(filename) != 0)
        return NULL;

    // Parse the WebM header
    long long pos = 0;
    mkvparser::EBMLHeader ebmlHeader;
    if (ebmlHeader.Parse(context->reader.get(), pos) < 0)
        return NULL;

    // Create & load segment
    mkvparser::Segment *segment = NULL;
    if (mkvparser::Segment::CreateInstance(context->reader.get(), pos, segment) != 0)
        return NULL;

    if (segment->Load() < 0)
        return NULL;

    context->segment.reset(segment);

    return context.release();
}


void webm_parser_destroy(WebMParserHandle handle) {
    delete WebMParserContext::cast(handle);
}


double webm_parser_get_duration(WebMParserHandle handle) {
    auto context = WebMParserContext::cast(handle);
    if (!context)
        return 0;

    if (!context->segment)
        return 0;

    const mkvparser::SegmentInfo *info = context->segment->GetInfo();
    if (!info)
        return 0;

    long long duration_ns = info->GetDuration();
    if (duration_ns < 0)
        return 0;

    return static_cast<double>(duration_ns) / 1000000000.0;
}


// MARK: - TRACK PARSING


long webm_parser_track_count(WebMParserHandle handle) {
    auto context = WebMParserContext::cast(handle);
    if (!context)
        return 0;

    if (!context->segment)
        return 0;

    const mkvparser::Tracks *tracks = context->segment->GetTracks();
    if (!tracks)
        return 0;

    return static_cast<int>(tracks->GetTracksCount());
}


bool webm_parser_track_info(WebMParserHandle handle, long index, CWebMTrack* out) {
    if (!out)
        return false;

    auto context = WebMParserContext::cast(handle);
    if (!context)
        return false;

    if (!context->segment)
        return false;

    const mkvparser::Tracks *tracks = context->segment->GetTracks();
    if (!tracks)
        return false;

    if (index < 0 || index >= tracks->GetTracksCount())
        return false;

    const mkvparser::Track *track = tracks->GetTrackByIndex(index);
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

    return true;
}
