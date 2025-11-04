//
//  WebMBridge.h
//  swift-webm
//
//  Created by Hovik Melikyan on 04.11.25.
//

#ifndef WebMBridge_h
#define WebMBridge_h

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle for Swift interop
typedef void *WebMParserHandle;

// Parser
WebMParserHandle webm_parser_create(const char *filepath);
void webm_parser_destroy(WebMParserHandle handle);
double webm_parser_get_duration(WebMParserHandle handle);

#ifdef __cplusplus
}
#endif

#endif /* WebMBridge_h */
