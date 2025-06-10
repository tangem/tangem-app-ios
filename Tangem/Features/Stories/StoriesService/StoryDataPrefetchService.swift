//
//  StoryDataPrefetchService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemStories

final class StoryDataPrefetchService {
    @Injected(\.enrichStoryUseCase) private var enrichStoryUseCase: EnrichStoryUseCase
    @Injected(\.storyAvailabilityService) private var storyAvailableService: any StoryAvailabilityService

    func prefetchStoryIfNeeded(_ story: TangemStory) {
        guard storyAvailableService.checkStoryAvailability(storyId: story.id) else {
            return
        }

        TangemFoundation.runTask(in: self, isDetached: true, priority: .medium) { strongSelf in
            _ = await strongSelf.enrichStoryUseCase(story)
        }
    }
}
