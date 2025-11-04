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

    public let duration: TimeInterval
    public let tracks: [WebMTrack]


    public init(filePath: String) throws {
        guard let handle = webm_parser_create(filePath) else {
            throw WebMError.invalidFile
        }
        self.handle = handle
        self.duration = webm_parser_get_duration(handle)
        self.tracks = (0..<webm_parser_track_count(handle))
            .compactMap { index -> WebMTrack? in
                var cTrack = CWebMTrack()
                let result = webm_parser_track_info(handle, index, &cTrack)
                return result ? WebMTrack(cTrack) : nil
            }
    }


    // Private

    private let handle: WebMHandle

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
    public let name: String?
    public let codecId: String?
    public let lacing: Bool
    public let defaultDuration: TimeInterval
    public let codecDelay: TimeInterval
    public let seekPreRoll: TimeInterval

    // For audio tracks
    let samplingRate: Double
    let channels: Int
    let bitDepth: Int

    // TODO: videoInfo

    init(_ cTrack: CWebMTrack) {
        self.type = TrackType(rawValue: cTrack.type) ?? .unknown
        self.number = cTrack.number
        self.uid = cTrack.uid
        self.name = cTrack.name.flatMap { String(cString: $0, encoding: .utf8) }
        self.codecId = cTrack.codecId.map { String(cString: $0) }
        self.lacing = cTrack.lacing
        self.defaultDuration = Double(cTrack.defaultDuration) / OneSecNs
        self.codecDelay = Double(cTrack.codecDelay) / OneSecNs
        self.seekPreRoll = Double(cTrack.seekPreRoll) / OneSecNs

        self.samplingRate = cTrack.samplingRate
        self.channels = Int(cTrack.channels)
        self.bitDepth = Int(cTrack.bitDepth)
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
