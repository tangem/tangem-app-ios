//
//  CollectiblesCoordinator+Stories.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStories

@MainActor
extension CollectiblesCoordinator {
    func openStories() {
        openMain()
        presentStories()
    }

    func openHowItWorks() {
        Task { [weak self] in self?.presentStories() }
    }

    func closeStories() {
        storiesViewModel = nil
    }

    private func presentStories() {
        let analytics = storiesAnalyticsProvider

        storiesViewModel = CollectiblesStoriesViewModel(
            slides: CollectiblesStoriesView.Slide.content,
            engine: {
                StoryPlayerViewModel(
                    story: $0,
                    source: .collectibles,
                    analytics: analytics,
                    hapticPlayer: CommonStoryHapticPlayer(),
                    onFinished: { _, _ in }
                )
            }
        )
    }
}
