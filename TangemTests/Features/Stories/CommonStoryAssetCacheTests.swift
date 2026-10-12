//
//  CommonStoryAssetCacheTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
import TangemFoundation
@testable import Tangem

@Suite("CommonStoryAssetCacheTests")
struct CommonStoryAssetCacheTests {
    /// The contract sends no checksum, so without a URL key nothing is ever cached.
    @Test
    func cachesAssetServedWithoutChecksum() async throws {
        let loader = SpyDataLoader()
        let cache = CommonStoryAssetCache(directory: Self.temporaryDirectory(), dataLoader: loader)
        let url = try #require(URL(string: "https://h/stories/promo/1.mp4"))

        let first = await cache.localURL(remoteURL: url, checksum: "")
        let second = await cache.localURL(remoteURL: url, checksum: "")

        #expect(first != nil)
        #expect(first == second)
        #expect(first?.pathExtension == "mp4")
        #expect(loader.downloadedURLs == [url])
    }

    @Test
    func keepsAssetsWithDifferentURLsApart() async throws {
        let loader = SpyDataLoader()
        let cache = CommonStoryAssetCache(directory: Self.temporaryDirectory(), dataLoader: loader)
        let first = try #require(URL(string: "https://h/stories/promo/1.mp4"))
        let second = try #require(URL(string: "https://h/stories/promo/2.mp4"))

        let firstLocal = await cache.localURL(remoteURL: first, checksum: "")
        let secondLocal = await cache.localURL(remoteURL: second, checksum: "")

        #expect(firstLocal != secondLocal)
        #expect(loader.downloadedURLs == [first, second])
    }

    @Test
    func prefersChecksumOverURLSoNewContentGetsANewFile() async throws {
        let loader = SpyDataLoader()
        let cache = CommonStoryAssetCache(directory: Self.temporaryDirectory(), dataLoader: loader)
        let url = try #require(URL(string: "https://h/stories/promo/1.mp4"))

        let old = await cache.localURL(remoteURL: url, checksum: "sha256:aaa")
        let new = await cache.localURL(remoteURL: url, checksum: "sha256:bbb")

        #expect(old != new)
        #expect(loader.downloadedURLs == [url, url])
    }

    /// Own directory per case: a shared one would let an earlier case answer a later one.
    private static func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}

private final class SpyDataLoader: StoriesDataLoader {
    private let state = OSAllocatedUnfairLock(initialState: [URL]())

    var downloadedURLs: [URL] { state.withLock { $0 } }

    func downloadFile(from url: URL) async throws -> URL {
        state.withLock { $0.append(url) }

        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("asset".utf8).write(to: temp)
        return temp
    }
}
