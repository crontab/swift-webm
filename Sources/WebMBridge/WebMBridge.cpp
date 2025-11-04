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


template <typename T, typename... Args>
std::unique_ptr<T> make_unique_compat(Args &&...args) {
    return std::unique_ptr<T>(new T(std::forward<Args>(args)...));
}


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
    auto context = make_unique_compat<WebMParserContext>();

    // Create reader
    context->reader = make_unique_compat<mkvparser::MkvReader>();

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
