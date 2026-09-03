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

    init(player: StoryPlayerViewModel) {
        self.player = player
    }
}
