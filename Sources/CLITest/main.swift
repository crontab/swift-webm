import Foundation
import AVFoundation

print("Hello, WebM!")

//let player = try AVAudioPlayer(contentsOf: URL(filePath: "/Users/hovik/Projects/Drop/ios/Drop/Resources/ding2.m4a")!)
//player.play()
//sleep(1)

let filePath = "/Users/hovik/Projects/TalkMachine/audio-a.webm"

do {
    let parser = try WebMParser(filePath: filePath)
    print("Duration:", parser.getDuration())
    parser.getTracks()
        .forEach {
            print("  Track #\($0.number)", $0.codecId ?? "?")
        }
}
catch {
    print("ERROR:", error)
}
