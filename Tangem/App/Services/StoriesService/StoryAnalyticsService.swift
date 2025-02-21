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
        switch storyId {
        case .swap:
            reportSwapStoryShown(lastViewedPageIndex: lastViewedPageIndex, source: source)
        }
    }

    func reportLoadingFailed(_ storyId: TangemStory.ID) {
        let event = Analytics.Event.storiesError
        let params = [
            Analytics.ParameterKey.commonType: storyId.asAnalyticsType.rawValue,
        ]

        Analytics.log(event: event, params: params)
    }

    private func reportSwapStoryShown(lastViewedPageIndex: Int, source: Analytics.StoriesSource) {
        let humanReadablePageIndex = lastViewedPageIndex + 1

        let event = Analytics.Event.storiesSwapShown
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
        }
    }
}
