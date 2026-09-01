//
//  StoryAssetPrefetchServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
import TangemStories
@testable import Tangem

@Suite("StoryAssetPrefetchServiceTests")
struct StoryAssetPrefetchServiceTests {
    @Test
    func resolvesPosterAndFullAssetWhenIncluded() async {
        let cache = StubAssetCache()
        let result = await StoryAssetPrefetchService(cache: cache).prefetch(
            story(assetChecksum: "sha256:a", posterChecksum: "sha256:p"),
            includeFullAssets: true
        )

        let asset = result.slides[0].asset
        #expect(asset.url == URL(fileURLWithPath: "/local/sha256:a"))
        #expect(asset.posterURL == URL(fileURLWithPath: "/local/sha256:p"))
        let requested = await cache.requestedChecksums
        #expect(Set(requested) == ["sha256:a", "sha256:p"])
    }

    @Test
    func fetchesPosterOnlyWhenFullAssetsExcluded() async {
        let cache = StubAssetCache()
        let result = await StoryAssetPrefetchService(cache: cache).prefetch(
            story(assetChecksum: "sha256:a", posterChecksum: "sha256:p"),
            includeFullAssets: false
        )

        let asset = result.slides[0].asset
        #expect(asset.url == URL(string: "https://h/a.mp4")) // full asset left remote
        #expect(asset.posterURL == URL(fileURLWithPath: "/local/sha256:p"))
        let requested = await cache.requestedChecksums
        #expect(requested == ["sha256:p"])
    }

    // MARK: - Helpers

    private func story(assetChecksum: String, posterChecksum: String) -> StoryV2 {
        let asset = AssetV2(
            type: .video,
            durationMs: 6000,
            url: URL(string: "https://h/a.mp4"),
            checksum: assetChecksum,
            posterURL: URL(string: "https://h/p.webp"),
            posterChecksum: posterChecksum
        )
        return StoryV2(
            id: "s",
            version: 1,
            placements: ["main_upgrade"],
            endBehavior: .finish,
            slides: [SlideV2(id: "s_1", order: 1, title: "t", subtitle: "s", asset: asset)],
            origin: .remote
        )
    }
}

private actor StubAssetCache: StoryAssetCaching {
    private(set) var requestedChecksums: [String] = []

    func localURL(remoteURL url: URL, checksum: String) async -> URL? {
        requestedChecksums.append(checksum)
        return URL(fileURLWithPath: "/local/\(checksum)")
    }
}
