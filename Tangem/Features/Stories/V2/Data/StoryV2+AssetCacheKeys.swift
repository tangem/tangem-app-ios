//
//  StoryV2+AssetCacheKeys.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStories

extension StoryV2 {
    var assetCacheKeys: [FileAssetCacheKey] {
        slides.flatMap { slide -> [FileAssetCacheKey] in
            let asset = slide.asset
            return [
                asset.url.map { FileAssetCacheKey(url: $0, checksum: asset.checksum) },
                asset.posterURL.map { FileAssetCacheKey(url: $0, checksum: asset.posterChecksum) },
            ].compactMap { $0 }
        }
    }
}
