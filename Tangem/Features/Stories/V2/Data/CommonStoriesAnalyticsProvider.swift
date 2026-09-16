//
//  CommonStoriesAnalyticsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemStories

struct CommonStoriesAnalyticsProvider: StoriesAnalyticsProvider {
    func logStoryOpened(storyId: String, slidesTotal: Int, source: StorySource, origin: ContentOrigin) {
        Analytics.log(event: .storiesStoryOpened, params: [
            .storyId: storyId,
            .slidesTotal: "\(slidesTotal)",
            .source: source.parameterValue.rawValue,
            .contentOrigin: origin.rawValue,
        ])
    }

    func logSlideViewed(
        storyId: String,
        slideId: String,
        slideIndex: Int,
        assetType: AssetType,
        assetDurationMs: Int,
        watchedMs: Int,
        completed: Bool,
        advanceReason: StoryAdvanceReason,
        source: StorySource
    ) {
        Analytics.log(event: .storiesSlideViewed, params: [
            .storyId: storyId,
            .slideId: slideId,
            .slideIndex: "\(slideIndex)",
            .assetType: assetType.rawValue,
            .assetDurationMs: "\(assetDurationMs)",
            .watchedMs: "\(watchedMs)",
            .slideCompleted: Analytics.ParameterValue.boolState(for: completed).rawValue,
            .advanceReason: advanceReason.rawValue,
            .source: source.parameterValue.rawValue,
        ])
    }

    func logStoryClosed(
        storyId: String,
        slidesTotal: Int,
        watched: Int,
        loopsWatched: Int,
        completed: Bool,
        exitReason: StoryExitReason,
        action: StoryActionV2?,
        source: StorySource
    ) {
        var params: [Analytics.ParameterKey: String] = [
            .storyId: storyId,
            .slidesTotal: "\(slidesTotal)",
            .slidesWatched: "\(watched)",
            .loopsWatched: "\(loopsWatched)",
            .storyCompleted: Analytics.ParameterValue.boolState(for: completed).rawValue,
            .exitReason: exitReason.rawValue,
            .source: source.parameterValue.rawValue,
        ]

        // A story that simply runs out reports its first action, which nobody pressed, so the
        // action properties travel only with an exit the button actually caused.
        if exitReason == .action, let action {
            params[.actionId] = action.id
            params[.actionTargetType] = action.target.analyticsType.rawValue
            params[.actionDestination] = action.target.destination
        }

        Analytics.log(event: .storiesStoryClosed, params: params)
    }
}

// MARK: - Wire values

/// `Source` is the one enum the analytics contract spells in Title Case; the rest go out as the
/// lower_snake_case raw values the module already stores.
private extension StorySource {
    var parameterValue: Analytics.StoriesSource {
        switch self {
        case .main: .main
        case .walletSettings: .walletSettings
        case .token: .token
        case .markets: .markets
        case .tangemPay: .tangemPay
        case .longTap: .tokenListContextMenu
        case .onboarding: .onboarding
        case .collectibles: .collectibles
        }
    }
}
