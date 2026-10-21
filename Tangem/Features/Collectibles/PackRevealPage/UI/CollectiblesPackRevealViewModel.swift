//
//  CollectiblesPackRevealViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import SwiftUI

@MainActor
final class CollectiblesPackRevealViewModel: ObservableObject {
    // MARK: - Properties

    private let darkVideoURL: URL?
    private let lightVideoURL: URL?
    private let player: any CollectiblesRevealPlayer

    let prize: CollectiblesPackRevealView.Prize

    // MARK: - Publishers

    @Published private(set) var videoPlayer: AVPlayer?

    // MARK: - Init

    init(
        darkVideoURL: URL?,
        lightVideoURL: URL?,
        prize: CollectiblesPackRevealView.Prize,
        player: any CollectiblesRevealPlayer
    ) {
        self.darkVideoURL = darkVideoURL
        self.lightVideoURL = lightVideoURL
        self.player = player
        self.prize = prize

        self.player.videoPlayerPublisher.assign(to: &$videoPlayer)
    }

    // MARK: - Methods

    func playVideo(for colorScheme: ColorScheme) async throws -> CollectiblesRevealPlayerResult {
        try await player.play(videoURL: colorScheme == .dark ? darkVideoURL : lightVideoURL)
    }

    func skip() {
        player.skip()
    }

    func sellBack() {
        // [REDACTED_TODO_COMMENT]
    }
}
