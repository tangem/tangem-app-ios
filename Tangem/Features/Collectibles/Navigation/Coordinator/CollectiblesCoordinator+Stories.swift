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
                    onFinished: { _, _ in }
                )
            }
        )

        let presenter = overlayViewPresenter

        let view = CollectiblesStoriesOverlayView(
            viewModel: viewModel,
            onDismiss: { presenter.dismiss() }
        )

        presenter.present(
            OverlayView(id: Constants.storiesOverlayID, view: view, style: .fullScreenCover, animated: false)
        )
    }
}

// MARK: - Constants

private extension CollectiblesCoordinator {
    enum Constants {
        static let storiesOverlayID = "collectibles_stories"
    }
}
