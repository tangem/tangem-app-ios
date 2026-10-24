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
    func resolvesPosterAndFullAssetWhenIncluded() async throws {
        let cache = StubAssetCache()
        let result = try await StoryAssetPrefetchService(cache: cache).prefetch(
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
    func fetchesPosterOnlyWhenFullAssetsExcluded() async throws {
        let cache = StubAssetCache()
        let result = try await StoryAssetPrefetchService(cache: cache).prefetch(
            story(assetChecksum: "sha256:a", posterChecksum: "sha256:p"),
            includeFullAssets: false
        )

        let asset = result.slides[0].asset
        #expect(asset.url == URL(string: "https://h/a.mp4")) // full asset left remote
        #expect(asset.posterURL == URL(fileURLWithPath: "/local/sha256:p"))
        let requested = await cache.requestedChecksums
        #expect(requested == ["sha256:p"])
    }

    /// A story pulls megabytes of video slide by slide, so a cancelled walk must not start the next
    /// download.
    @Test
    func cancellationStopsTheWalkBeforeTheCache() async {
        let cache = StubAssetCache()
        let service = StoryAssetPrefetchService(cache: cache)

        let task = Task {
            while !Task.isCancelled {
                await Task.yield()
            }

            return try await service.prefetch(
                story(assetChecksum: "sha256:a", posterChecksum: "sha256:p"),
                includeFullAssets: true
            )
        }

        task.cancel()

        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }

        let requested = await cache.requestedChecksums
        #expect(requested.isEmpty)
    }

    @Test
    func cancellationBetweenTheAssetsOfASlideStopsTheWalk() async {
        let cache = StubAssetCache(cancelsCallerOnRequest: true)
        let service = StoryAssetPrefetchService(cache: cache)

        let task = Task {
            try await service.prefetch(
                story(assetChecksum: "sha256:a", posterChecksum: "sha256:p"),
                includeFullAssets: true
            )
        }

        await #expect(throws: CancellationError.self) {
            _ = try await task.value
        }

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
            placements: ["main_upgrade"],
            endBehavior: .finish,
            slides: [SlideV2(id: "s_1", order: 1, title: "t", subtitle: "s", asset: asset)],
            origin: .remote
        )
    }
}

private actor StubAssetCache: StoryAssetCaching {
    private(set) var requestedChecksums: [String] = []

    private let cancelsCallerOnRequest: Bool

    init(cancelsCallerOnRequest: Bool = false) {
        self.cancelsCallerOnRequest = cancelsCallerOnRequest
    }

    func localURL(remoteURL url: URL, checksum: String) async throws -> URL {
        requestedChecksums.append(checksum)

        if cancelsCallerOnRequest {
            withUnsafeCurrentTask { $0?.cancel() }
        }

        return URL(fileURLWithPath: "/local/\(checksum)")
    }
}
