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

@Suite("CommonStoryAssetCacheTests", .timeLimit(.minutes(1)))
final class CommonStoryAssetCacheTests {
    /// Own directory per test, removed in `deinit`: a shared one would let an earlier case answer a later one.
    private let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    /// The contract sends no checksum, so without a URL key nothing is ever cached.
    @Test
    func cachesAssetServedWithoutChecksum() async throws {
        let loader = SpyDataLoader()
        let cache = CommonStoryAssetCache(directory: directory, dataLoader: loader)
        let url = try #require(URL(string: "https://h/stories/promo/1.mp4"))

        let first = try await cache.localURL(remoteURL: url, checksum: "")
        let second = try await cache.localURL(remoteURL: url, checksum: "")

        #expect(first == second)
        #expect(first.pathExtension == "mp4")
        #expect(loader.downloadedURLs == [url])
    }

    @Test
    func keepsAssetsWithDifferentURLsApart() async throws {
        let loader = SpyDataLoader()
        let cache = CommonStoryAssetCache(directory: directory, dataLoader: loader)
        let first = try #require(URL(string: "https://h/stories/promo/1.mp4"))
        let second = try #require(URL(string: "https://h/stories/promo/2.mp4"))

        let firstLocal = try await cache.localURL(remoteURL: first, checksum: "")
        let secondLocal = try await cache.localURL(remoteURL: second, checksum: "")

        #expect(firstLocal != secondLocal)
        #expect(loader.downloadedURLs == [first, second])
    }

    @Test
    func prefersChecksumOverURLSoNewContentGetsANewFile() async throws {
        let loader = SpyDataLoader()
        let cache = CommonStoryAssetCache(directory: directory, dataLoader: loader)
        let url = try #require(URL(string: "https://h/stories/promo/1.mp4"))

        let old = try await cache.localURL(remoteURL: url, checksum: "sha256:aaa")
        let new = try await cache.localURL(remoteURL: url, checksum: "sha256:bbb")

        #expect(old != new)
        #expect(loader.downloadedURLs == [url, url])
    }

    @Test
    func joinsDownloadAlreadyInFlight() async throws {
        let loader = GatedDataLoader()
        let cache = CommonStoryAssetCache(directory: directory, dataLoader: loader)
        let url = try #require(URL(string: "https://h/stories/promo/1.mp4"))

        async let first = cache.localURL(remoteURL: url, checksum: "")
        await loader.waitUntilDownloadStarted()

        async let second = cache.localURL(remoteURL: url, checksum: "")
        // Should the second caller arrive late, it hits the finished file and the join goes untested
        // rather than failing
        try await Task.sleep(for: .milliseconds(50))

        loader.finishDownloads()

        let results = try await [first, second]

        #expect(results[0] == results[1])
        #expect(loader.downloadedURLs == [url])
    }

    @Test
    func failedDownloadLeavesTheAssetFreeForTheNextCall() async throws {
        let loader = FailingOnceDataLoader()
        let cache = CommonStoryAssetCache(directory: directory, dataLoader: loader)
        let url = try #require(URL(string: "https://h/stories/promo/1.mp4"))

        await #expect(throws: (any Error).self) {
            try await cache.localURL(remoteURL: url, checksum: "")
        }

        let recovered = try await cache.localURL(remoteURL: url, checksum: "")

        #expect(recovered.pathExtension == "mp4")
        #expect(loader.attempts == 2)
    }

    @Test
    func evictsTheOldestFileOverTheCap() async throws {
        let loader = SpyDataLoader()
        // Every stub asset is 5 bytes, so the third one pushes the cache over the cap
        let cache = CommonStoryAssetCache(directory: directory, maxBytes: 12, dataLoader: loader)
        let first = try #require(URL(string: "https://h/stories/promo/1.mp4"))
        let second = try #require(URL(string: "https://h/stories/promo/2.mp4"))
        let third = try #require(URL(string: "https://h/stories/promo/3.mp4"))

        // The pauses keep the modification dates apart, so the eviction order is not left to chance
        let oldest = try await cache.localURL(remoteURL: first, checksum: "")
        try await Task.sleep(for: .milliseconds(10))
        let middle = try await cache.localURL(remoteURL: second, checksum: "")
        try await Task.sleep(for: .milliseconds(10))
        let newest = try await cache.localURL(remoteURL: third, checksum: "")

        #expect(!FileManager.default.fileExists(atPath: oldest.path))
        #expect(FileManager.default.fileExists(atPath: middle.path))
        #expect(FileManager.default.fileExists(atPath: newest.path))
    }
}

private final class FailingOnceDataLoader: StoriesDataLoader {
    private let state = OSAllocatedUnfairLock(initialState: 0)

    var attempts: Int { state.withLock { $0 } }

    func downloadFile(from url: URL) async throws -> URL {
        let attempt = state.withLock { count -> Int in
            count += 1
            return count
        }

        guard attempt > 1 else { throw StoriesDataLoaderError.unacceptableStatusCode(500) }

        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("asset".utf8).write(to: temp)
        return temp
    }
}

private final class GatedDataLoader: StoriesDataLoader {
    private let state = OSAllocatedUnfairLock(initialState: State())

    private struct State {
        var downloadedURLs: [URL] = []
        var pending: [CheckedContinuation<Void, Never>] = []
        var isFinished = false
    }

    var downloadedURLs: [URL] { state.withLock { $0.downloadedURLs } }

    func downloadFile(from url: URL) async throws -> URL {
        state.withLock { $0.downloadedURLs.append(url) }

        await withCheckedContinuation { continuation in
            let isFinished = state.withLock { state -> Bool in
                guard !state.isFinished else { return true }

                state.pending.append(continuation)
                return false
            }

            if isFinished {
                continuation.resume()
            }
        }

        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try Data("asset".utf8).write(to: temp)
        return temp
    }

    func finishDownloads() {
        let pending = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            state.isFinished = true
            defer { state.pending = [] }
            return state.pending
        }

        pending.forEach { $0.resume() }
    }

    func waitUntilDownloadStarted() async {
        while downloadedURLs.isEmpty {
            await Task.yield()
        }
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
