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


    func schedule(on playerNode: AVAudioPlayerNode) throws {
        // Pre-schedule one second of data
        var lookahead = Int(format.sampleRate) // 1s
        while let scheduled = scheduleNext(playerNode: playerNode), lookahead > 0 {
            lookahead -= scheduled
        }
    }


    private func scheduleNext(playerNode: AVAudioPlayerNode) -> Int? {
        do {
            guard let buffer = try read() else {
                return nil
            }
            playerNode.scheduleBuffer(buffer, completionCallbackType: .dataConsumed) { _ in
                Task { @WebMActor [weak self] in
                    _ = self?.scheduleNext(playerNode: playerNode)
                }
            }
            return Int(buffer.frameLength)
        }
        catch {
            playerNode.stop()
            return nil
        }
    }


    private func read() throws -> AVAudioPCMBuffer? {
        guard let frame = parser.readFrame(trackNumber: track.number) else {
            return nil
        }
        return try decoder.decode(frame.data)
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
    try await reader.schedule(on: playerNode)

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
