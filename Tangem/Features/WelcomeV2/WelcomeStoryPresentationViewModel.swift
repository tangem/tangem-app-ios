//
//  WelcomeStoryPresentationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStories

@MainActor
final class WelcomeStoryPresentationViewModel: ObservableObject, Identifiable {
    let id = UUID()
    let player: StoryPlayerViewModel

    private let scanAction: StoryActionV2

    init(player: StoryPlayerViewModel, scanAction: StoryActionV2) {
        self.player = player
        self.scanAction = scanAction
    }

    func setCovered(_ isCovered: Bool) {
        player.setPaused(isCovered, for: .cover)
    }

    func closeAfterScan() {
        player.finish(for: scanAction)
    }

    func cancel() {
        player.cancel()
    }
}
