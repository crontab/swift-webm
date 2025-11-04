import Foundation
import AVFoundation

print("Hello, WebM!")

//let player = try AVAudioPlayer(contentsOf: URL(filePath: "/Users/hovik/Projects/Drop/ios/Drop/Resources/ding2.m4a")!)
//player.play()
//sleep(1)

let filePath = "/Users/hovik/Projects/TalkMachine/audio-a.webm"

do {
    let parser = try WebMParser(filePath: filePath)
    print("Duration:", parser.duration)
    parser.tracks
        .forEach { track in
            print("  Track #\(track.number)", track.codecId ?? "?", " sampling rate:", track.samplingRate, " channels:", track.channels, " bit depth:", track.bitDepth)
        }

    let trackNumber = parser.tracks
        .first { $0.type == .audio }
        .map { $0.number }

    guard let trackNumber else {
        throw WebMError.invalidFile
    }

    while let frame = parser.readData(trackNumber: trackNumber) {
        print("    Frame:", frame.data.count, frame.timestamp)
    }
}
catch {
    print("ERROR:", error)
}
