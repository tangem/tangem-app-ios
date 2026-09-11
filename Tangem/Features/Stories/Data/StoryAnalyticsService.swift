//
//  StoryAnalyticsService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemStories

final class StoryAnalyticsService {
    func reportShown(_ storyId: TangemStory.ID, lastViewedPageIndex: Int, source: Analytics.StoriesSource) {
        let event = switch storyId {
        case .swap: Analytics.Event.storiesSwapStory
        case .yieldFirstActivationAPYBoost: Analytics.Event.storiesYieldPromoStory
        }

        reportStoryShown(event: event, lastViewedPageIndex: lastViewedPageIndex, source: source)
    }

    func reportLoadingFailed(_ storyId: TangemStory.ID) {
        let event = Analytics.Event.storiesError
        let params = [
            Analytics.ParameterKey.type: storyId.asAnalyticsType.rawValue,
        ]

        Analytics.log(event: event, params: params)
    }

    private func reportStoryShown(event: Analytics.Event, lastViewedPageIndex: Int, source: Analytics.StoriesSource) {
        let humanReadablePageIndex = lastViewedPageIndex + 1
        let params = [
            Analytics.ParameterKey.source: source.rawValue,
            Analytics.ParameterKey.watched: "\(humanReadablePageIndex)",
        ]

        Analytics.log(event: event, params: params)
    }
}

private extension TangemStory.ID {
    var asAnalyticsType: Analytics.StoryType {
        switch self {
        case .swap: .swap
        case .yieldFirstActivationAPYBoost: .yieldFirstActivationAPYBoost
        }
    }
}
