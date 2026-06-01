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
        cacheStoryImagesInKingfisher(story.pages)
    }

    public func retrieveStory(with storyId: TangemStory.ID) -> TangemStory? {
        cache[storyId]
    }

    public func removeStory(with storyId: TangemStory.ID) async {
        guard let storyToClean = cache.removeValue(forKey: storyId) else { return }
        removeStoryImagesFromKingfisher(storyToClean.pages)
    }

    // MARK: - Kingfisher

    private func cacheStoryImagesInKingfisher(_ pages: [TangemStory.Page]) {
        for page in pages {
            guard let backgroundImage = page.image,
                  let uiImage = UIImage(data: backgroundImage.rawData)
            else {
                continue
            }

            kingfisherCache.store(uiImage, original: backgroundImage.rawData, forKey: backgroundImage.url.absoluteString, toDisk: false)
        }
    }

    private func removeStoryImagesFromKingfisher(_ pages: [TangemStory.Page]) {
        for page in pages {
            guard let backgroundImage = page.image else { continue }
            kingfisherCache.removeImage(forKey: backgroundImage.url.absoluteString)
        }
    }
}
