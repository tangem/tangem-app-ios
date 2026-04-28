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
            return await enrichSwapStoryData(data, wrap: { enrichedData in TangemStory.swap(enrichedData) })
        case .swapLegacy(let data):
            return await enrichSwapStoryData(data, wrap: { enrichedData in TangemStory.swapLegacy(enrichedData) })
        }
    }

    private func enrichSwapStoryData<StoryData: SwapStoryDataPagesContainer>(
        _ swapStoryData: StoryData,
        wrap: (StoryData) -> TangemStory
    ) async -> TangemStory {
        if let cachedStory = await storyDataCache.retrieveStory(with: .swap) {
            return cachedStory
        }

        do {
            try Task.checkCancellation()

            let storyImages = try await storyDataService.fetchStoryImages(with: .swap)
            var enrichedSwapStoryData = swapStoryData

            for (index, storyImage) in storyImages.prefix(swapStoryData.pagesKeyPaths.count).enumerated() {
                let pageKeyPath = swapStoryData.pagesKeyPaths[index]
                enrichedSwapStoryData[keyPath: pageKeyPath].image = storyImage
            }

            try Task.checkCancellation()

            let enrichedSwapStory = wrap(enrichedSwapStoryData)
            await storyDataCache.store(story: enrichedSwapStory)

            return enrichedSwapStory
        } catch {
            return wrap(swapStoryData)
        }
    }
}
