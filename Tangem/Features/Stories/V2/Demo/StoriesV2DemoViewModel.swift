//
//  StoriesV2DemoViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemStories

/// Dev-only preview of the Stories V2 player from the Environment screen. A local sample keeps the
/// player visible without a backend.
@MainActor
final class StoriesV2DemoViewModel: ObservableObject, Identifiable {
    let id = UUID()

    @Published private(set) var player: StoryPlayerViewModel?

    private let storyFactory = StoriesV2DemoStoryFactory()

    nonisolated init() {}

    func openSample() {
        player = StoryPlayerViewModel(story: storyFactory.makeSampleStory()) { [weak self] _, _ in
            self?.closePlayer()
        }
    }

    func closePlayer() {
        player = nil
    }
}
