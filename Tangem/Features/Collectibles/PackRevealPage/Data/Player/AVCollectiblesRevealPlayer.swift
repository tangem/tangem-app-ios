//
//  AVCollectiblesRevealPlayer.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Combine
import TangemUI
import UIKit

@MainActor
final class AVCollectiblesRevealPlayer: CollectiblesRevealPlayer {
    // MARK: - Properties

    private let skipAudioURL: URL?

    private var skipAudioPlayer: AVPlayer?
    private var isSkipped = false
    private var isFinished = false

    // MARK: - Publishers

    @Published private var videoPlayer: AVPlayer?

    var videoPlayerPublisher: AnyPublisher<AVPlayer?, Never> {
        $videoPlayer.eraseToAnyPublisher()
    }

    // MARK: - Init

    init(skipAudioURL: URL?) {
        self.skipAudioURL = skipAudioURL
    }

    // MARK: - Methods

    func play(videoURL: URL?) async throws -> CollectiblesRevealPlayerResult {
        isFinished = false
        defer { isFinished = true }

        AmbientAudioSession.configure()

        guard let videoURL else {
            playSkipAudio()
            return CollectiblesRevealPlayerResult(isSkipped: isSkipped)
        }

        let player = AVPlayer(url: videoURL)
        videoPlayer = player
        player.play()

        let hasReachedBurst = try await waitForBurst(of: player)

        if !hasReachedBurst {
            player.pause()
            videoPlayer = nil
            playSkipAudio()
        }

        return CollectiblesRevealPlayerResult(isSkipped: isSkipped)
    }

    func skip() {
        guard !isFinished, let player = videoPlayer else { return }

        let time = player.currentTime().seconds

        guard time >= Constants.skipAvailableFrom, time < Constants.skipTarget else { return }

        let target = CMTime(seconds: Constants.skipTarget, preferredTimescale: Constants.seekTimescale)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
        isSkipped = true

        guard skipAudioURL != nil else { return }

        player.isMuted = true
        playSkipAudio()
    }
}

// MARK: - Private logic

private extension AVCollectiblesRevealPlayer {
    func waitForBurst(of player: AVPlayer) async throws -> Bool {
        var lastTime = player.currentTime().seconds
        var lastProgress = ContinuousClock.now
        let loadingDeadline = ContinuousClock.now + Constants.loadingTimeout

        while player.currentTime().seconds < burstTime(of: player) {
            guard player.currentItem?.status != .failed else { return false }

            try await Task.sleep(for: Constants.pollInterval)

            let time = player.currentTime().seconds
            let isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
            let isLoading = isBuffering && ContinuousClock.now < loadingDeadline

            if time != lastTime || isLoading || UIApplication.shared.applicationState != .active {
                lastTime = time
                lastProgress = .now
            } else if ContinuousClock.now - lastProgress >= Constants.stallTimeout {
                return false
            }
        }

        return true
    }

    func burstTime(of player: AVPlayer) -> Double {
        guard let duration = player.currentItem?.duration.seconds, duration.isFinite else {
            return Constants.burstTime
        }

        return min(Constants.burstTime, duration - Constants.endTolerance)
    }

    func playSkipAudio() {
        guard let skipAudioURL, skipAudioPlayer == nil else { return }

        let player = AVPlayer(url: skipAudioURL)
        skipAudioPlayer = player
        player.play()
    }
}

// MARK: - Constants

private extension AVCollectiblesRevealPlayer {
    enum Constants {
        static let burstTime: Double = 7
        static let skipTarget: Double = 6.1
        static let skipAvailableFrom: Double = 0.8
        static let seekTimescale: Int32 = 600
        static let endTolerance: Double = 0.1
        static let pollInterval: Duration = .milliseconds(30)
        static let stallTimeout: Duration = .seconds(3)
        static let loadingTimeout: Duration = .seconds(10)
    }
}
