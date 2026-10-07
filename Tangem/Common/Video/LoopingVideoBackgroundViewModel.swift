//
//  LoopingVideoBackgroundViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Combine
import TangemUI

final class LoopingVideoBackgroundViewModel: ObservableObject {
    @Published private(set) var player: AVQueuePlayer?

    private let provider: LoopingVideoBackgroundProvider
    private var looper: AVPlayerLooper?

    init(provider: LoopingVideoBackgroundProvider) {
        self.provider = provider
    }

    func play() {
        if player == nil {
            startPlayback()
        }
        player?.play()
    }

    func stop() {
        player?.pause()
        looper?.disableLooping()
        looper = nil
        player?.removeAllItems()
        player = nil
    }

    private func startPlayback() {
        guard let videoURL = provider.videoURL() else {
            provider.handleMissingAsset()
            return
        }

        AmbientAudioSession.configure()

        let item = AVPlayerItem(url: videoURL)
        let queuePlayer = AVQueuePlayer(playerItem: item)
        queuePlayer.isMuted = true

        player = queuePlayer
        looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
    }
}
