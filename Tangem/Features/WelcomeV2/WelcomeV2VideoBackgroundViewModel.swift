//
//  WelcomeV2VideoBackgroundViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import AVFoundation

final class WelcomeV2VideoBackgroundViewModel: ObservableObject {
    @Published private(set) var player: AVQueuePlayer?

    private var looper: AVPlayerLooper?
    private let videoProvider: WelcomeV2BackgroundVideoProviding

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
        guard let videoURL = videoProvider.backgroundVideoURL() else { return }

        let item = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true

        player = queuePlayer
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
    }
}
