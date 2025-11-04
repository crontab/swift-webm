//
//  WebM.swift
//  swift-webm
//
//  Created by Hovik Melikyan on 04.11.25.
//

import Foundation
import WebMBridge


public enum WebMError: LocalizedError {
    case invalidFile

    public var errorDescription: String? {
        switch self {
            case .invalidFile: "Could not open webm file"
        }
    }
}


public class WebMParser {

    init(filePath: String) throws {
        guard let handle = webm_parser_create(filePath) else {
            throw WebMError.invalidFile
        }
        self.handle = handle
    }


    func getDuration() -> TimeInterval { webm_parser_get_duration(handle) }


    // Private
    private let handle: WebMParserHandle

    deinit {
        webm_parser_destroy(handle)
    }
}
