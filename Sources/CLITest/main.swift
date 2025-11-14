import Foundation
@preconcurrency import AVFoundation
import Opus


@globalActor
actor WebMActor {
    static let shared = WebMActor()
}


@WebMActor
final class WebMOpusFileReader {
    let url: URL
    let format: AVAudioFormat
    let duration: TimeInterval


    init(url: URL) throws {
        guard url.isFileURL else {
            throw WebMError.invalidFile
        }
        self.url = url
        self.parser = try .init(filePath: url.path())
        self.duration = parser.duration

        guard let opusTrack = parser.tracks.first(where: { $0.type == .audio && $0.codecId == "A_OPUS" }) else {
            throw WebMError.invalidFile
        }
        self.track = opusTrack

        guard let format = AVAudioFormat(opusPCMFormat: .float32, sampleRate: opusTrack.samplingRate, channels: AVAudioChannelCount(opusTrack.channels)) else {
            throw WebMError.invalidFile
        }
        self.format = format

        self.decoder = try .init(format: format)
    }


    func read() throws -> AVAudioPCMBuffer? {
        try parser.readData(trackNumber: track.number).map {
            try decoder.decode($0.data)
        }
    }


    private let parser: WebMParser
    private let track: WebMTrack
    private let decoder: Opus.Decoder
}



// MARK: - TEST

print("Hello, WebM!")

//let player = try AVAudioPlayer(contentsOf: URL(filePath: "/Users/hovik/Projects/Drop/ios/Drop/Resources/ding2.m4a")!)
//player.play()
//sleep(1)

let filePath = "/Users/hovik/Projects/TalkMachine/audio-a.webm"


@WebMActor
func schedule(reader: WebMOpusFileReader, playerNode: AVAudioPlayerNode) throws {

    @WebMActor
    func scheduleNext() -> Int? {
        do {
            guard let buffer = try reader.read() else {
                return nil
            }
            playerNode.scheduleBuffer(buffer, completionCallbackType: .dataConsumed) { _ in
                Task { @WebMActor in
                    _ = scheduleNext()
                }
            }
            return Int(buffer.frameLength)
        }
        catch {
            print("Scheduler error:", error)
            playerNode.stop()
            return nil
        }
    }

    // Pre-schedule one second of data
    var lookahead = Int(reader.format.sampleRate) // 1s
    while let scheduled = scheduleNext(), lookahead > 0 {
        lookahead -= scheduled
    }
}


do {
    let reader = try await WebMOpusFileReader(url: URL(filePath: filePath))
    print("Duration =", reader.duration)

    let audioEngine = AVAudioEngine()
    let playerNode = AVAudioPlayerNode()
    audioEngine.attach(playerNode)
    audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: reader.format)
    audioEngine.prepare()
    try audioEngine.start()

    print("Playing...")
    playerNode.play()
    try await schedule(reader: reader, playerNode: playerNode)

//    RunLoop.main.run(until: Date.now.addingTimeInterval(max(10, reader.duration)))
//    try await Task.sleep(for: .seconds(reader.duration > 0 ? reader.duration : 20))
    try await Task.sleep(for: .seconds(20))


    //	while let frame = parser.readData(trackNumber: track.number) {
    //        print("    Frame:", frame.data.count, frame.timestamp)
    //		let buffer = try decoder.decode(frame.data)
    //		print("        AVAudioBuffer.frames =", buffer.frameLength)
    //    }

    print("Finished")
}
catch {
    print("ERROR:", error)
}
