//
//  WebM.swift
//  swift-webm
//
//  Created by Hovik Melikyan on 04.11.25.
//

import Foundation
import WebMBridge


public let OneSecNs: Double = 1_000_000_000


public class WebMParser {

    public init(filePath: String) throws {
        guard let handle = webm_parser_create(filePath) else {
            throw WebMError.invalidFile
        }
        self.handle = handle
    }


    public func getDuration() -> TimeInterval { webm_parser_get_duration(handle) }


    // Private

    private let handle: WebMParserHandle

    deinit {
        webm_parser_destroy(handle)
    }
}


public class WebMTrack {

    public enum TrackType: Int {
        case video = 1
        case audio = 2
        case subtitle = 0x11
        case metadata = 0x21
        case unknown = -1
    }

    public let type: TrackType
    public let number: Int
    public let uid: UInt64
    public let name: String
    public let codecId: String
    public let lacing: Bool
    public let defaultDuration: TimeInterval
    public let codecDelay: TimeInterval
    public let seekPreRoll: TimeInterval

    init(_ cTrack: CWebMTrack) {
        self.type = TrackType(rawValue: cTrack.type) ?? .unknown
        self.number = cTrack.number
        self.uid = cTrack.uid
        self.name = String(cString: cTrack.name, encoding: .utf8) ?? ""
        self.codecId = String(cString: cTrack.codecId)
        self.lacing = cTrack.lacing
        self.defaultDuration = Double(cTrack.defaultDuration) / OneSecNs
        self.codecDelay = Double(cTrack.codecDelay) / OneSecNs
        self.seekPreRoll = Double(cTrack.seekPreRoll) / OneSecNs
    }
}


public enum WebMError: LocalizedError {
    case invalidFile

    public var errorDescription: String? {
        switch self {
            case .invalidFile: "Could not open webm file"
        }
    }
}
