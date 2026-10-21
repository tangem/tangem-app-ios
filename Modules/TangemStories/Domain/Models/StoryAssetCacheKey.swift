//
//  StoryAssetCacheKey.swift
//  TangemStories
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public struct StoryAssetCacheKey: Hashable, Sendable {
    public let url: URL
    public let checksum: String

    public init(url: URL, checksum: String) {
        self.url = url
        self.checksum = checksum
    }
}

public extension StoryV2 {
    var assetCacheKeys: [StoryAssetCacheKey] {
        slides.flatMap { slide -> [StoryAssetCacheKey] in
            let asset = slide.asset
            return [
                asset.url.map { StoryAssetCacheKey(url: $0, checksum: asset.checksum) },
                asset.posterURL.map { StoryAssetCacheKey(url: $0, checksum: asset.posterChecksum) },
            ].compactMap { $0 }
        }
    }
}
