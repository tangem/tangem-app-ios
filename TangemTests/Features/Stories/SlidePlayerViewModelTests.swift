//
//  SlidePlayerViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
import Lottie
import TangemFoundation
@testable import TangemStories

@Suite("Stories V2 slide player")
@MainActor
struct SlidePlayerViewModelTests {
    @Test
    func imageSlideProgressAdvancesWithManualClock() {
        let clock = ManualProgressClock()
        let vm = SlidePlayerViewModel(slide: imageSlide(durationMs: 1000), clock: clock)
        vm.play()

        #expect(vm.state == .playing)
        #expect(vm.progress.value < 0.0001)

        clock.advance(by: 0.5) // half of the 1s duration
        #expect(abs(vm.progress.value - 0.5) < 0.05)
        #expect(vm.state == .playing)
    }

    @Test
    func imageSlideCompletesAtDuration() {
        let clock = ManualProgressClock()
        let vm = SlidePlayerViewModel(slide: imageSlide(durationMs: 1000), clock: clock)

        var completed = false
        vm.onCompleted = { completed = true }
        vm.play()

        clock.advance(by: 1.1) // slightly past the 1s duration so the crossing tick fires

        #expect(completed)
        #expect(vm.state == .completed)
        #expect(abs(vm.progress.value - 1) < 0.0001)
    }

    @Test
    func pauseHaltsProgress() {
        let clock = ManualProgressClock()
        let vm = SlidePlayerViewModel(slide: imageSlide(durationMs: 1000), clock: clock)
        vm.play()

        clock.advance(by: 0.3)
        let progressAtPause = vm.progress.value
        vm.pause()
        clock.advance(by: 0.5) // ticks keep firing, but paused → ignored

        #expect(abs(vm.progress.value - progressAtPause) < 0.0001)
    }

    // MARK: - Lottie

    @Test
    func lottieSlideWaitsForTheAnimationBeforeRunningProgress() async {
        let loader = StubAnimationLoader(animation: Self.animation())
        let clock = ManualProgressClock()
        let vm = SlidePlayerViewModel(slide: lottieSlide(durationMs: 1000), clock: clock, animationLoader: loader)

        vm.play()
        #expect(vm.state == .buffering) // nothing to show yet, so the progress bar stays put

        await waitUntil { vm.animation != nil }
        #expect(vm.animation != nil)
        #expect(vm.state == .playing)
        #expect(loader.callCount == 1)
    }

    @Test
    func lottieSlideIsSkippedWhenTheAnimationFailsToLoad() async {
        let loader = StubAnimationLoader(animation: nil)
        let vm = SlidePlayerViewModel(slide: lottieSlide(durationMs: 1000), animationLoader: loader)

        vm.play()
        await waitUntil { vm.state == .completed }

        #expect(vm.state == .completed)
    }

    @Test
    func failedAnimationIsRetriedOnTheNextPlay() async {
        let loader = StubAnimationLoader(animation: nil)
        let vm = SlidePlayerViewModel(slide: lottieSlide(durationMs: 1000), animationLoader: loader)

        vm.play()
        await waitUntil { loader.callCount == 1 }
        vm.restart()
        await waitUntil { loader.callCount == 2 }

        #expect(loader.callCount == 2)
    }

    @Test
    func lottieSlideIsSkippedWhenTheAnimationNeverArrives() async {
        let vm = SlidePlayerViewModel(
            slide: lottieSlide(durationMs: 60_000),
            animationLoader: HangingAnimationLoader(),
            stallTimeout: 0.01
        )

        vm.play()
        #expect(vm.state == .buffering)

        // Only the stall guard can end this wait — the loader outlives its whole window budget.
        await waitOnRealClock(upTo: 2) { vm.state == .completed }

        #expect(vm.state == .completed)
    }

    @Test
    func preparingALottieSlideLoadsItWithoutStartingPlayback() async {
        let loader = StubAnimationLoader(animation: Self.animation())
        let vm = SlidePlayerViewModel(slide: lottieSlide(durationMs: 1000), animationLoader: loader)

        vm.prepare()
        await waitUntil { vm.animation != nil }

        #expect(vm.animation != nil)
        #expect(vm.state == .preparing)
    }

    // MARK: - Helpers

    /// Yields until the view model's load task lands, without sleeping on a wall clock.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0 ..< 100 where !condition() {
            await Task.yield()
        }
    }

    /// The stall guard sleeps on the real clock, so polling it has to advance wall time, not yield.
    private func waitOnRealClock(upTo timeout: TimeInterval, until condition: () -> Bool) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }

    private static func animation() -> LottieAnimation? {
        let json = #"{"v":"5.5.7","fr":60,"ip":0,"op":60,"w":100,"h":100,"nm":"t","ddd":0,"assets":[],"layers":[]}"#
        return try? LottieAnimation.from(data: Data(json.utf8))
    }

    private func lottieSlide(durationMs: Int) -> SlideV2 {
        SlideV2(
            id: "s",
            order: 1,
            title: "t",
            subtitle: "s",
            asset: AssetV2(type: .lottie, durationMs: durationMs, url: URL(string: "https://h/a.json"))
        )
    }

    private func imageSlide(durationMs: Int) -> SlideV2 {
        SlideV2(
            id: "s",
            order: 1,
            title: "t",
            subtitle: "s",
            asset: AssetV2(type: .image, durationMs: durationMs, url: nil)
        )
    }
}

/// Never resolves within the guard's window budget; the sleep is bounded only so the test leaves
/// no long-lived task behind.
private struct HangingAnimationLoader: StoryAnimationLoading {
    func animation(at url: URL) async -> LottieAnimation? {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return nil
    }
}

private final class StubAnimationLoader: StoryAnimationLoading, @unchecked Sendable {
    private let stubbed: LottieAnimation?
    private let state = OSAllocatedUnfairLock(initialState: 0)

    var callCount: Int { state.withLock { $0 } }

    init(animation: LottieAnimation?) {
        stubbed = animation
    }

    func animation(at url: URL) async -> LottieAnimation? {
        state.withLock { $0 += 1 }
        return stubbed
    }
}
