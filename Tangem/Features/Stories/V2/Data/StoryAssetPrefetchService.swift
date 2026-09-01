//
//  StoryAssetPrefetchService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemStories

/// Warms the disk cache for a story and rewrites its assets to local files, slide by slide.
/// Posters are always fetched; full assets only when `includeFullAssets` is set (control users
/// get posters only).
struct StoryAssetPrefetchService {
    private let cache: StoryAssetCaching

    init(cache: StoryAssetCaching) {
        self.cache = cache
    }

    func prefetch(_ story: StoryV2, includeFullAssets: Bool = true) async -> StoryV2 {
        var slides: [SlideV2] = []
        for slide in story.slides {
            let asset = slide.asset
            let localPoster = await localFile(asset.posterURL, checksum: asset.posterChecksum)
            let localAsset = includeFullAssets ? await localFile(asset.url, checksum: asset.checksum) : nil

            let resolved = asset.resolvingLocal(url: localAsset, poster: localPoster)
            slides.append(
                SlideV2(
                    id: slide.id, order: slide.order, title: slide.title, subtitle: slide.subtitle,
                    asset: resolved, hapticAtMs: slide.hapticAtMs, actions: slide.actions
                )
            )
        }
        return story.replacingSlides(slides)
    }

    private func localFile(_ url: URL?, checksum: String) async -> URL? {
        guard let url else { return nil }
        return await cache.localURL(remoteURL: url, checksum: checksum)
    }
}
