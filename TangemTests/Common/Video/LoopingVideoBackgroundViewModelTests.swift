//
//  LoopingVideoBackgroundViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
import Combine
@testable import Tangem

@Suite("Looping video background")
@MainActor
struct LoopingVideoBackgroundViewModelTests {
    @Test
    func missingAssetInvokesCallbackAndLeavesPlayerNil() {
        let provider = StubProvider(url: nil)
        let viewModel = LoopingVideoBackgroundViewModel(provider: provider)

        viewModel.play()

        #expect(provider.missingAssetCallCount == 1)
        #expect(viewModel.player == nil)
    }

    @Test
    func missingAssetIsRetriedOnEveryPlayWhilePlayerStaysNil() {
        let provider = StubProvider(url: nil)
        let viewModel = LoopingVideoBackgroundViewModel(provider: provider)

        viewModel.play()
        viewModel.play()

        #expect(provider.missingAssetCallCount == 2)
        #expect(viewModel.player == nil)
    }

    @Test
    func availableAssetStartsPlayerWithoutMissingAssetCallback() {
        let provider = StubProvider(url: URL(string: "file:///tmp/looping-video-background-test.mp4")!)
        let viewModel = LoopingVideoBackgroundViewModel(provider: provider)

        viewModel.play()

        #expect(provider.missingAssetCallCount == 0)
        #expect(viewModel.player != nil)
    }

    @Test
    func playbackTimeStartsAtZero() {
        let viewModel = LoopingVideoBackgroundViewModel(provider: StubProvider(url: nil))

        var received: [TimeInterval] = []
        let subscription = viewModel.playbackTime.sink { received.append($0) }
        subscription.cancel()

        #expect(received == [0])
    }

    @Test
    func stopResetsPlaybackTimeAndReleasesPlayer() {
        let provider = StubProvider(url: URL(string: "file:///tmp/looping-video-background-test.mp4")!)
        let viewModel = LoopingVideoBackgroundViewModel(provider: provider)

        var received: [TimeInterval] = []
        let subscription = viewModel.playbackTime.sink { received.append($0) }

        viewModel.play()
        let emissionCountBeforeStop = received.count
        viewModel.stop()
        subscription.cancel()

        #expect(viewModel.player == nil)
        #expect(received.count == emissionCountBeforeStop + 1)
        #expect(received.last == 0)
    }

    @Test
    func playAfterStopStartsNewPlayer() {
        let provider = StubProvider(url: URL(string: "file:///tmp/looping-video-background-test.mp4")!)
        let viewModel = LoopingVideoBackgroundViewModel(provider: provider)

        viewModel.play()
        let firstPlayer = viewModel.player
        viewModel.stop()
        viewModel.play()

        #expect(viewModel.player != nil)
        #expect(viewModel.player !== firstPlayer)
        #expect(provider.missingAssetCallCount == 0)
    }
}

private final class StubProvider: LoopingVideoBackgroundProvider {
    private let url: URL?
    private(set) var missingAssetCallCount = 0

    init(url: URL?) {
        self.url = url
    }

    func videoURL() -> URL? {
        url
    }

    func handleMissingAsset() {
        missingAssetCallCount += 1
    }
}
