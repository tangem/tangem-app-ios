//
//  CardImageProviderCache.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit
import Kingfisher

struct CardImageProviderCache {
    private let kingfisherCache = KingfisherManager.shared.cache

    func cacheImage(_ image: UIImage, for key: String) {
        kingfisherCache.store(image, forKey: key)
    }

    func getImageFromCache(for key: String) -> UIImage? {
        if let cachedImage = kingfisherCache.memoryStorage.value(forKey: key) {
            return cachedImage
        }

        guard
            let diskImageData = try? kingfisherCache.diskStorage.value(forKey: key),
            let image = UIImage(data: diskImageData)
        else {
            return nil
        }

        kingfisherCache.memoryStorage.store(value: image, forKey: key)

        return image
    }
}
