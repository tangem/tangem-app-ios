//
//  WelcomeVideoBackgroundViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Combine
import TangemUI

final class WelcomeVideoBackgroundViewModel: ObservableObject {
    @Injected(\.welcomeAnalyticsProvider) private var analytics: WelcomeAnalyticsProvider

    @Published private(set) var player: AVQueuePlayer?

    /// Kept out of `@Published` so following the playhead doesn't redraw the video layer.
    var playbackTime: AnyPublisher<TimeInterval, Never> {
        playbackTimeSubject.eraseToAnyPublisher()
    }

    private let playbackTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private var looper: AVPlayerLooper?
    private var timeObserver: Any?
    private let videoProvider: WelcomeBackgroundVideoProviding
    private var didLogMediaError = false

    init(videoProvider: WelcomeBackgroundVideoProviding) {
        self.videoProvider = videoProvider
    }

    func play() {
        if player == nil {
            startPlayback()
        }
        player?.play()
    }

    func stop() {
        player?.pause()

        if let timeObserver {
            player?.removeTimeObserver(timeObserver)
        }

        timeObserver = nil
        looper?.disableLooping()
        looper = nil
        player?.removeAllItems()
        player = nil
        playbackTimeSubject.send(0)
    }

    private func startPlayback() {
        guard let videoURL = videoProvider.backgroundVideoURL() else {
            logMissingVideoAsset()
            return
        }

        AmbientAudioSession.configure()

        let item = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true

        player = queuePlayer
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
        observePlaybackTime(of: queuePlayer)
    }

    /// `AVPlayerLooper` plays every lap from a fresh copy of the item, so the observed time runs from zero on each.
    private func observePlaybackTime(of player: AVQueuePlayer) {
        let interval = CMTime(seconds: Constants.playbackTimeInterval, preferredTimescale: .init(NSEC_PER_SEC))

        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.playbackTimeSubject.send(time.seconds)
        }
    }

    /// The asset ships in the bundle, so a missing URL stays missing for the whole process:
    /// the view replays the background on every appearance and must not report it each time.
    private func logMissingVideoAsset() {
        guard !didLogMediaError else { return }
        didLogMediaError = true

        analytics.logWelcomeMediaError(stage: .welcomeMediaStageLoad)
    }
}

// MARK: - Constants

private extension WelcomeVideoBackgroundViewModel {
    enum Constants {
        static let playbackTimeInterval: TimeInterval = 0.1
    }
}
