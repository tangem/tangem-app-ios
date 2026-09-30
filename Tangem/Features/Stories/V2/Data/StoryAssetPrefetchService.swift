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
struct StoryAssetPrefetchService {
    private let cache: StoryAssetCaching

    init(cache: StoryAssetCaching) {
        self.cache = cache
    }

    func prefetch(_ story: StoryV2, includeFullAssets: Bool = true) async throws -> StoryV2 {
        var slides: [SlideV2] = []
        for slide in story.slides {
            let asset = slide.asset
            let localPoster = try await localFile(asset.posterURL, checksum: asset.posterChecksum)
            let localAsset = try await localFile(includeFullAssets ? asset.url : nil, checksum: asset.checksum)

            let resolved = asset.resolvingLocal(url: localAsset, poster: localPoster)
            slides.append(
                SlideV2(
                    id: slide.id, order: slide.order, title: slide.title, subtitle: slide.subtitle,
                    asset: resolved, hapticAtMs: slide.hapticAtMs, actions: slide.actions
                )
            )
        }
        // The last asset has nothing after it to notice a cancellation that landed mid-download.
        try Task.checkCancellation()

        return story.replacingSlides(slides)
    }

    /// The cache never cancels a shared download for one caller, so the walk checks for itself. A failed
    /// asset leaves its slide without media instead of failing the story.
    private func localFile(_ url: URL?, checksum: String) async throws -> URL? {
        guard let url else { return nil }

        try Task.checkCancellation()

        return try? await cache.localURL(remoteURL: url, checksum: checksum)
    }
}
