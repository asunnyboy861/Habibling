import AVFoundation
import Foundation
import UIKit

final class SoundPlayer {
    static let shared = SoundPlayer()
    private var engine: AVAudioEngine?
    private var isPlaying = false

    func playChirp() {
        guard !isPlaying else { return }
        isPlaying = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            self.synthesize(frequency: 880, duration: 0.07) {
                self.synthesize(frequency: 1320, duration: 0.05) {
                    DispatchQueue.main.async { self.isPlaying = false }
                }
            }
        }
    }

    private func synthesize(frequency: Double, duration: Double, completion: @escaping () -> Void) {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)
        let frames = AVAudioFrameCount(44100 * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else {
            completion()
            return
        }
        buffer.frameLength = frames
        if let channel = buffer.floatChannelData?[0] {
            for i in 0..<Int(frames) {
                let t = Double(i) / 44100.0
                let envelope = 1.0 - Double(i) / Double(frames)
                channel[i] = Float(sin(2.0 * .pi * frequency * t) * 0.18 * envelope)
            }
        }
        do {
            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak player] in
                player?.stop()
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
                    engine.stop()
                    completion()
                }
            }
            player.play()
        } catch {
            completion()
        }
    }
}

enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}
