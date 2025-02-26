//
//  TangemStoriesPresenter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import enum TangemStories.TangemStory

protocol TangemStoriesPresenter {
    /// Presents a given story.
    /// - Parameters:
    ///   - story: story model that may be enriched after presentation.
    ///   - analyticsSource: source of the presentation used for analytics reporting.
    ///   - presentCompletion: closure that is executed after presentation has finished or immediately if story was not available for presenting.
    @MainActor
    func present(story: TangemStory, analyticsSource: Analytics.StoriesSource, presentCompletion: @escaping () -> Void)
}
