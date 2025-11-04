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
            print("  Track #\(track.number)", track.codecId ?? "?")
            if let audioInfo = track.audioInfo {
                print("    Sampling rate:", audioInfo.samplingRate, " channels:", audioInfo.channels, " bit depth:", audioInfo.bitDepth)
            }
        }
}
catch {
    print("ERROR:", error)
}
