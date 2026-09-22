//
//  CommonStoryHapticPlayer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import CoreHaptics
import TangemStories

/// A cluster goes to the engine as one pattern: `UIImpactFeedbackGenerator` coalesces impulses
/// closer than roughly 50 ms, while the engine keeps the intervals inside a pattern exactly.
@MainActor
final class CommonStoryHapticPlayer {
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    private var engine: CHHapticEngine?
    private var activePlayer: CHHapticPatternPlayer?
}

// MARK: - StoryHapticPlaying

extension CommonStoryHapticPlayer: StoryHapticPlaying {
    func prepare() {
        guard supportsHaptics else { return }

        guard let engine else {
            startEngine()
            return
        }

        try? engine.start()
    }

    func play(_ cluster: HapticCluster) {
        guard let engine else { return }

        do {
            let pattern = try CHHapticPattern(events: events(for: cluster), parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            activePlayer = player
        } catch {
            activePlayer = nil
        }
    }

    func stopPlayback() {
        try? activePlayer?.stop(atTime: CHHapticTimeImmediate)
        activePlayer = nil
    }

    func shutdown() {
        stopPlayback()
        engine?.stop()
    }
}

// MARK: - Private implementation

private extension CommonStoryHapticPlayer {
    func startEngine() {
        do {
            let engine = try CHHapticEngine()
            engine.playsHapticsOnly = true
            // Without this the first impulse after an idle stretch arrives late, which on a slide
            // synced to video reads as a missed beat.
            engine.isAutoShutdownEnabled = false
            engine.resetHandler = { [weak self] in
                Task { @MainActor in
                    try? self?.engine?.start()
                }
            }
            engine.stoppedHandler = { [weak self] reason in
                Task { @MainActor in
                    self?.handleStop(reason)
                }
            }
            try engine.start()
            self.engine = engine
        } catch {
            engine = nil
        }
    }

    /// Auto-shutdown is off and a slide prepares only once, so an engine the system stopped stays
    /// down for the rest of the story unless it is restarted here.
    func handleStop(_ reason: CHHapticEngine.StoppedReason) {
        activePlayer = nil

        switch reason {
        case .applicationSuspended:
            break
        case .engineDestroyed:
            // A destroyed instance can't be revived, and the slide on screen won't prepare again,
            // so the replacement has to be built right here.
            startEngine()
        default:
            try? engine?.start()
        }
    }

    func events(for cluster: HapticCluster) -> [CHHapticEvent] {
        let intensity = cluster.isBurst ? Constants.burstIntensity : Constants.accentIntensity
        let sharpness = cluster.isBurst ? Constants.burstSharpness : Constants.accentSharpness

        return cluster.offsets.map { offset in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
                ],
                relativeTime: offset
            )
        }
    }
}

// MARK: - Constants

/// Low sharpness reads as a touch rather than a click; a burst is sharper because at 30 ms
/// apart soft impulses smear into one another.
private extension CommonStoryHapticPlayer {
    enum Constants {
        static let accentIntensity: Float = 0.6
        static let accentSharpness: Float = 0.2
        static let burstIntensity: Float = 0.55
        static let burstSharpness: Float = 0.3
    }
}
