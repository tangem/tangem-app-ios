//
//  InMemoryStoryDataCache.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import class UIKit.UIImage
import Kingfisher

public actor InMemoryStoryDataCache: StoryDataCache {
    private let kingfisherCache: ImageCache
    private var cache: [TangemStory.ID: TangemStory]

    public init(kingfisherCache: ImageCache) {
        self.kingfisherCache = kingfisherCache
        cache = [:]
    }

    public func store(story: TangemStory) {
        cache[story.id] = story

        switch story {
        case .swap(let swapStoryData):
            cacheSwapStoryImagesInKingfisher(swapStoryData)
        }
    }

    public func retrieveStory(with storyId: TangemStory.ID) -> TangemStory? {
        cache[storyId]
    }

    public func removeStory(with storyId: TangemStory.ID) async {
        guard let storyToClean = cache.removeValue(forKey: storyId) else { return }

        switch storyToClean {
        case .swap(let swapStoryData):
            removeSwapStoryImagesFromKingfisher(swapStoryData)
        }
    }

    // MARK: - Kingfisher

    private func cacheSwapStoryImagesInKingfisher(_ swapStoryData: TangemStory.SwapStoryData) {
        for pageKeyPath in swapStoryData.pagesKeyPaths {
            guard
                let backgroundImage = swapStoryData[keyPath: pageKeyPath].image,
                let uiImage = UIImage(data: backgroundImage.rawData)
            else {
                continue
            }

            kingfisherCache.store(uiImage, original: backgroundImage.rawData, forKey: backgroundImage.url.absoluteString, toDisk: false)
        }
    }

    private func removeSwapStoryImagesFromKingfisher(_ swapStoryData: TangemStory.SwapStoryData) {
        for pageKeyPath in swapStoryData.pagesKeyPaths {
            guard let backgroundImage = swapStoryData[keyPath: pageKeyPath].image else { continue }
            kingfisherCache.removeImage(forKey: backgroundImage.url.absoluteString)
        }
    }
}
