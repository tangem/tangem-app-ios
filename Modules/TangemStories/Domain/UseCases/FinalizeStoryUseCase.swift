//
//  FinalizeStoryUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public final class FinalizeStoryUseCase {
    private let storyAvailabilityService: any StoryAvailabilityService
    private let storyDataCache: any StoryDataCache

    public init(storyAvailabilityService: some StoryAvailabilityService, storyDataCache: some StoryDataCache) {
        self.storyAvailabilityService = storyAvailabilityService
        self.storyDataCache = storyDataCache
    }

    public func callAsFunction(_ story: TangemStory) async {
        guard !story.isRepeatable else { return }

        storyAvailabilityService.markStoryAsShown(storyId: story.id)
        await storyDataCache.removeStory(with: story.id)
    }
}
