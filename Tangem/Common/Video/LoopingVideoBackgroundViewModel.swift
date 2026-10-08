//
//  LoopingVideoBackgroundViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Combine
import UIKit
import TangemUI

final class LoopingVideoBackgroundViewModel: ObservableObject {
    @Published private(set) var player: AVQueuePlayer?

    private let provider: LoopingVideoBackgroundProvider
    private var looper: AVPlayerLooper?
    private var autoplayPreferenceObserver: AnyCancellable?

    init(provider: LoopingVideoBackgroundProvider) {
        self.provider = provider
    }

    func play() {
        if player == nil {
            startPlayback()
        }

        observeAutoplayPreference()
        applyAutoplayPreference()
    }

    func stop() {
        autoplayPreferenceObserver = nil
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

    private func observeAutoplayPreference() {
        guard autoplayPreferenceObserver == nil else { return }

        autoplayPreferenceObserver = NotificationCenter.default
            .publisher(for: UIAccessibility.videoAutoplayStatusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyAutoplayPreference()
            }
    }

    private func applyAutoplayPreference() {
        if UIAccessibility.isVideoAutoplayEnabled {
            player?.play()
        } else {
            player?.pause()
        }
    }
}
