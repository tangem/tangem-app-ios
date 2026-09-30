//
//  CollectiblesCoordinator+Stories.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
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
        overlayViewPresenter.dismiss()
    }

    private func presentStories() {
        let analytics = storiesAnalyticsProvider

        let viewModel = CollectiblesStoriesViewModel(
            slides: CollectiblesStoriesView.Slide.content,
            engine: {
                StoryPlayerViewModel(
                    story: $0,
                    source: .collectibles,
                    analytics: analytics,
                    hapticPlayer: CommonStoryHapticPlayer(),
                    holdsLastSlide: true,
                    onFinished: { _, _ in }
                )
            }
        )

        overlayViewPresenter.present(
            OverlayView(
                id: Constants.storiesOverlayID,
                view: CollectiblesStoriesOverlayView(viewModel: viewModel, onDismiss: { [weak self] in self?.closeStories() }),
                style: .fullScreenCover,
                animated: false
            )
        )
    }
}

// MARK: - Constants

private extension CollectiblesCoordinator {
    enum Constants {
        static let storiesOverlayID = "collectibles_stories"
    }
}
