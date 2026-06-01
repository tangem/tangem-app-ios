//
//  EnrichStoryUseCase.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public final class EnrichStoryUseCase {
    private let storyDataCache: any StoryDataCache
    private let storyDataService: any StoryDataService

    public init(storyDataCache: some StoryDataCache, storyDataService: some StoryDataService) {
        self.storyDataCache = storyDataCache
        self.storyDataService = storyDataService
    }

    public func callAsFunction(_ story: TangemStory) async -> TangemStory {
        switch story {
        case .swap(let data):
            return await enrichStoryData(data, storyId: .swap, wrap: TangemStory.swap)
        case .swapLegacy(let data):
            return await enrichStoryData(data, storyId: .swap, wrap: TangemStory.swapLegacy)
        case .yieldFirstActivationAPYBoost(let data):
            return await enrichStoryData(data, storyId: .yieldFirstActivationAPYBoost, wrap: TangemStory.yieldFirstActivationAPYBoost)
        }
    }

    private func enrichStoryData<StoryData: StoryPagesContainer>(
        _ storyData: StoryData,
        storyId: TangemStory.ID,
        wrap: (StoryData) -> TangemStory
    ) async -> TangemStory {
        if let cachedStory = await storyDataCache.retrieveStory(with: storyId) {
            return cachedStory
        }

        do {
            try Task.checkCancellation()

            let storyImages = try await storyDataService.fetchStoryImages(with: storyId)
            var enrichedStoryData = storyData

            for (index, storyImage) in storyImages.prefix(storyData.pagesKeyPaths.count).enumerated() {
                let pageKeyPath = storyData.pagesKeyPaths[index]
                enrichedStoryData[keyPath: pageKeyPath].image = storyImage
            }

            try Task.checkCancellation()

            let enrichedStory = wrap(enrichedStoryData)
            await storyDataCache.store(story: enrichedStory)

            return enrichedStory
        } catch {
            return wrap(storyData)
        }
    }
}
