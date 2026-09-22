//
//  StoriesAnalyticsProvider.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// The player only reports what happened; the integration layer maps these calls onto the app's
/// analytics events.
public protocol StoriesAnalyticsProvider {
    func logStoryOpened(
        storyId: String,
        slidesTotal: Int,
        source: StorySource,
        origin: ContentOrigin
    )

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
    )

    func logStoryClosed(
        storyId: String,
        slidesTotal: Int,
        watched: Int,
        loopsWatched: Int,
        completed: Bool,
        exitReason: StoryExitReason,
        action: StoryActionV2?,
        source: StorySource
    )
}

/// Why a slide was left, reported with the view it ends.
public enum StoryAdvanceReason: String {
    case auto
    case tapForward = "tap_forward"
    case tapBack = "tap_back"
    case loopRestart = "loop_restart"
    case storyClosed = "story_closed"
}

public enum StorySource {
    case main
    case walletSettings
    case token
    case markets
    case tangemPay
    case longTap
    case onboarding
    case collectibles
}
