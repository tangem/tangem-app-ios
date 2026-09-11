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

    private var looper: AVPlayerLooper?
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
        looper?.disableLooping()
        looper = nil
        player?.removeAllItems()
        player = nil
    }

    private func startPlayback() {
        guard let videoURL = videoProvider.backgroundVideoURL() else {
            logMissingVideoAsset()
            return
        }

        let item = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true

        player = queuePlayer
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
    }

    /// The asset ships in the bundle, so a missing URL stays missing for the whole process:
    /// the view replays the background on every appearance and must not report it each time.
    private func logMissingVideoAsset() {
        guard !didLogMediaError else { return }
        didLogMediaError = true

        analytics.logWelcomeMediaError(stage: .welcomeV2MediaStageLoad)
    }
}
