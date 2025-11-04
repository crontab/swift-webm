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
        if (reader != nullptr)
            reader->Close();
    }
};


WebMParserHandle webm_parser_create(const char *filename) {
    auto context = std::make_unique<WebMParserContext>();

    // Create reader
    context->reader = std::make_unique<mkvparser::MkvReader>();

    // Open file
    if (context->reader->Open(filename) != 0)
        return nullptr;

    // Parse the WebM header
    long long pos = 0;
    mkvparser::EBMLHeader ebmlHeader;
    if (ebmlHeader.Parse(context->reader.get(), pos) < 0)
        return nullptr;

    // Create & load segment
    mkvparser::Segment *segment = nullptr;
    if (mkvparser::Segment::CreateInstance(context->reader.get(), pos, segment) != 0)
        return nullptr;

    if (segment->Load() < 0)
        return nullptr;

    context->segment.reset(segment);

    return context.release();
}


void webm_parser_destroy(WebMParserHandle handle) {
    delete WebMParserContext::cast(handle);
}


double webm_parser_get_duration(WebMParserHandle handle) {
    auto context = WebMParserContext::cast(handle);
    if (context == nullptr)
        return 0;

    const mkvparser::SegmentInfo *info = context->segment->GetInfo();
    if (!info)
        return 0;

    long long duration_ns = info->GetDuration();
    if (duration_ns < 0)
        return 0;

    return static_cast<double>(duration_ns) / 1000000000.0;
}


// MARK: - TRACK

void cwebm_track_from_track(struct CWebMTrack* out, const mkvparser::Track* track) {
    if (!out || !track)
        return;

    out->type = track->GetType();
    out->number = track->GetNumber();
    out->uid = track->GetUid();
    out->name = track->GetNameAsUTF8();
    out->codecId = track->GetCodecId();
    out->lacing = track->GetLacing();
    out->defaultDuration = track->GetDefaultDuration();
    out->codecDelay = track->GetCodecDelay();
    out->seekPreRoll = track->GetSeekPreRoll();
}
