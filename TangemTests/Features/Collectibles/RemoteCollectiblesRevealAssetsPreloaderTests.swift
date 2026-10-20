//
//  RemoteCollectiblesRevealAssetsPreloaderTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Testing
import TangemFoundation
import TangemTestKit
@testable import Tangem

@Suite("RemoteCollectiblesRevealAssetsPreloader", .timeLimit(.minutes(1)))
@MainActor
final class RemoteCollectiblesRevealAssetsPreloaderTests: LeakTrackingTestSuite {
    typealias SUT = RemoteCollectiblesRevealAssetsPreloader

    @Test("Preloads the video of the current theme together with the skip audio", arguments: Self.themeArguments)
    func preloadsThemeVideo(colorScheme: ColorScheme, videoURL: URL) async {
        let (sut, provider) = makeSUT()

        sut.preload(for: colorScheme)
        let assets = await sut.assets(prefetchingImages: [])

        let expectedDarkVideoURL = colorScheme == .dark ? Self.localURL(for: Constants.darkVideoURL) : nil
        let expectedLightVideoURL = colorScheme == .light ? Self.localURL(for: Constants.lightVideoURL) : nil
        #expect(Set(provider.loadedURLs) == [videoURL, Constants.skipAudioURL])
        #expect(provider.loadedURLs.count == 2)
        #expect(assets.darkVideoURL == expectedDarkVideoURL)
        #expect(assets.lightVideoURL == expectedLightVideoURL)
        #expect(assets.skipAudioURL == Self.localURL(for: Constants.skipAudioURL))
    }

    @Test("A media file that fails to load is left out while the rest is kept", arguments: Self.loadErrors)
    func failedLoadLeavesAssetOut(error: any Error) async {
        let (sut, _) = makeSUT(failures: [Constants.skipAudioURL: error])

        sut.preload(for: .dark)
        let assets = await sut.assets(prefetchingImages: [])

        #expect(assets.darkVideoURL == Self.localURL(for: Constants.darkVideoURL))
        #expect(assets.skipAudioURL == nil)
    }

    @Test("Media already on disk is not requested again")
    func cachedMediaIsNotReloaded() async {
        let (sut, provider) = makeSUT()

        sut.preload(for: .dark)
        _ = await sut.assets(prefetchingImages: [])
        sut.preload(for: .dark)
        _ = await sut.assets(prefetchingImages: [])

        #expect(provider.loadedURLs.count == 2)
    }

    @Test("A theme switched during the load is preloaded right after it", arguments: Self.queuedThemeArguments)
    func queuedThemeIsPreloadedAfterwards(queuedColorScheme: ColorScheme, expectedLoadsCount: Int) async {
        let (sut, provider) = makeSUT(isGated: true)

        sut.preload(for: .dark)
        sut.preload(for: queuedColorScheme)
        provider.gate.open()
        let assets = await sut.assets(prefetchingImages: [])

        let expectedLightVideoURL = queuedColorScheme == .light ? Self.localURL(for: Constants.lightVideoURL) : nil
        #expect(provider.loadedURLs.count == expectedLoadsCount)
        #expect(assets.darkVideoURL == Self.localURL(for: Constants.darkVideoURL))
        #expect(assets.lightVideoURL == expectedLightVideoURL)
    }

    @Test("Assets wait for the media that is still loading")
    func assetsAwaitInFlightMedia() async {
        let (sut, provider) = makeSUT(isGated: true)
        sut.preload(for: .dark)

        async let assets = sut.assets(prefetchingImages: [])
        await provider.gate.waitForArrival()
        provider.gate.open()
        let loadedAssets = await assets

        #expect(loadedAssets.darkVideoURL == Self.localURL(for: Constants.darkVideoURL))
        #expect(loadedAssets.skipAudioURL == Self.localURL(for: Constants.skipAudioURL))
    }

    @Test("Assets give up on media that does not arrive in time")
    func assetsGiveUpOnLateMedia() async {
        let (sut, provider) = makeSUT(isGated: true, openingMediaWaitTimeout: .milliseconds(10))
        sut.preload(for: .dark)
        let start = ContinuousClock.now

        let assets = await sut.assets(prefetchingImages: [])
        let elapsed = ContinuousClock.now - start
        provider.gate.open()

        #expect(elapsed >= .milliseconds(10))
        #expect(assets.darkVideoURL == nil)
        #expect(assets.skipAudioURL == nil)
    }

    @Test("A machine without media requests nothing")
    func emptyMediaRequestsNothing() async {
        let (sut, provider) = makeSUT(openingMedia: .empty)

        sut.preload(for: .dark)
        let assets = await sut.assets(prefetchingImages: [])

        #expect(provider.loadedURLs.isEmpty)
        #expect(assets.darkVideoURL == nil)
        #expect(assets.lightVideoURL == nil)
        #expect(assets.skipAudioURL == nil)
    }
}

// MARK: - Arguments

extension RemoteCollectiblesRevealAssetsPreloaderTests {
    nonisolated static let themeArguments: [(colorScheme: ColorScheme, videoURL: URL)] = [
        (colorScheme: .dark, videoURL: Constants.darkVideoURL),
        (colorScheme: .light, videoURL: Constants.lightVideoURL),
    ]

    nonisolated static let queuedThemeArguments: [(queuedColorScheme: ColorScheme, expectedLoadsCount: Int)] = [
        (queuedColorScheme: .dark, expectedLoadsCount: 2),
        (queuedColorScheme: .light, expectedLoadsCount: 3),
    ]

    nonisolated static let loadErrors: [any Error] = [URLError(.timedOut), CancellationError()]
}

// MARK: - Helpers

private extension RemoteCollectiblesRevealAssetsPreloaderTests {
    enum Constants {
        static let darkVideoURL = URL(string: "https://example.com/dark.mp4")!
        static let lightVideoURL = URL(string: "https://example.com/light.mp4")!
        static let skipAudioURL = URL(string: "https://example.com/skip.m4a")!
        static let neverExpiringTimeout: Duration = .seconds(60)
        static let openingMedia = CollectiblesMachine.OpeningMedia(
            darkVideoURL: darkVideoURL,
            lightVideoURL: lightVideoURL,
            skipAudioURL: skipAudioURL
        )
    }

    nonisolated static func localURL(for remoteURL: URL) -> URL {
        URL(filePath: "/media/\(remoteURL.lastPathComponent)")
    }

    func makeSUT(
        openingMedia: CollectiblesMachine.OpeningMedia = Constants.openingMedia,
        failures: [URL: any Error] = [:],
        isGated: Bool = false,
        openingMediaWaitTimeout: Duration = Constants.neverExpiringTimeout
    ) -> (SUT, MediaProviderStub) {
        let provider = MediaProviderStub(failures: failures, isGated: isGated)
        let sut = SUT(
            openingMedia: openingMedia,
            openingMediaProvider: provider,
            openingMediaWaitTimeout: openingMediaWaitTimeout,
            wonCardImagesWaitTimeout: Constants.neverExpiringTimeout
        )
        return (trackForMemoryLeaks(sut), provider)
    }
}

// MARK: - Stubs

private final class MediaProviderStub: CollectiblesOpeningMediaProvider {
    let gate = YieldAsyncGate()

    private let failures: [URL: any Error]
    private let recordedURLs = OSAllocatedUnfairLock(initialState: [URL]())

    init(failures: [URL: any Error], isGated: Bool) {
        self.failures = failures

        if !isGated {
            gate.open()
        }
    }

    var loadedURLs: [URL] {
        recordedURLs.withLock { $0 }
    }

    func load(from url: URL) async throws -> URL {
        recordedURLs.withLock { $0.append(url) }
        await gate.wait()

        if let failure = failures[url] {
            throw failure
        }

        return RemoteCollectiblesRevealAssetsPreloaderTests.localURL(for: url)
    }
}
