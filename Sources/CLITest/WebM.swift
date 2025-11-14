//
//  WebM.swift
//  swift-webm
//
//  Created by Hovik Melikyan on 04.11.25.
//

import Foundation
import WebMBridge


let OneSecNs: Double = 1_000_000_000


final class WebMParser {

    let duration: TimeInterval
    let tracks: [WebMTrack]


    init(filePath: String) throws {
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


    func readFrame(trackNumber: Int) -> WebMFrame? {
        guard let cData = webm_parser_read(handle, trackNumber)?.pointee else {
            return nil
        }
        return WebMFrame(
            data: Data(bytes: cData.bytes, count: cData.size),
            timestamp: Double(cData.timestamp) / OneSecNs)
    }


    var isEOS: Bool {
        webm_parser_eos(handle)
    }


    func reset() {
        webm_parser_reset(handle);
    }


    // Private

    private let handle: WebMHandle

    deinit {
        webm_parser_destroy(handle)
    }
}


final class WebMTrack: Sendable {

    enum TrackType: Int {
        case video = 0x01
        case audio = 0x02
        case subtitle = 0x11
        case metadata = 0x21
        case unknown = 0
    }

    let type: TrackType
    let number: Int
    let uid: UInt64
    let name: String?
    let codecId: String?
    let lacing: Bool
    let defaultDuration: TimeInterval
    let codecDelay: TimeInterval
    let seekPreRoll: TimeInterval

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


struct WebMFrame {
    let data: Data
    let timestamp: TimeInterval
}


enum WebMError: LocalizedError {
    case invalidFile

    public var errorDescription: String? {
        switch self {
            case .invalidFile: "Could not open webm file"
        }
    }
}
