//
//  WelcomeV2VideoBackgroundViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Combine

final class WelcomeV2VideoBackgroundViewModel: ObservableObject {
    @Injected(\.welcomeV2AnalyticsProvider) private var analytics: WelcomeV2AnalyticsProvider

    @Published private(set) var player: AVQueuePlayer?

    /// Kept out of `@Published` so following the playhead doesn't redraw the video layer.
    var playbackTime: AnyPublisher<TimeInterval, Never> {
        playbackTimeSubject.eraseToAnyPublisher()
    }

    private let playbackTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private var looper: AVPlayerLooper?
    private var timeObserver: Any?
    private let videoProvider: WelcomeV2BackgroundVideoProviding
    private var didLogMediaError = false

    init(videoProvider: WelcomeV2BackgroundVideoProviding) {
        self.videoProvider = videoProvider
    }

    func play() {
        if player == nil {
            startPlayback()
        }
        player?.play()
    }

    func pause() {
        player?.pause()
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

        activateAmbientAudioSessionOnce()

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

    private static var ambientConfigured = false

    /// Muting the player is not enough: starting it activates the session under the default
    /// `.soloAmbient` category, which stops whatever the user is already listening to. The
    /// background video is silent by design, so it has no claim on the audio route.
    private func activateAmbientAudioSessionOnce() {
        guard !Self.ambientConfigured else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            Self.ambientConfigured = true
        } catch {
            // Left unlatched so the next appearance tries again instead of playing under `.soloAmbient`.
        }
    }

    /// The asset ships in the bundle, so a missing URL stays missing for the whole process:
    /// the view replays the background on every appearance and must not report it each time.
    private func logMissingVideoAsset() {
        guard !didLogMediaError else { return }
        didLogMediaError = true

        analytics.logWelcomeMediaError(stage: .welcomeV2MediaStageLoad)
    }
}

// MARK: - Constants

private extension WelcomeV2VideoBackgroundViewModel {
    enum Constants {
        static let playbackTimeInterval: TimeInterval = 0.1
    }
}
