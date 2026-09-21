//
//  SlidePlayerHapticsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
import UIKit
@testable import TangemStories

@Suite("Stories V2 slide haptics")
@MainActor
struct SlidePlayerHapticsTests {
    @Test
    func marksFireAsThePlayheadPassesThem() {
        let haptics = HapticPlayerSpy()
        let clock = ManualProgressClock()
        let vm = makeViewModel(hapticAtMs: [200, 600], clock: clock, haptics: haptics)
        vm.play()

        clock.advance(by: 0.25)
        #expect(haptics.played.map(\.startMs) == [200])

        clock.advance(by: 0.4)
        #expect(haptics.played.map(\.startMs) == [200, 600])
    }

    @Test
    func aMarkFiresOnlyOnce() {
        let haptics = HapticPlayerSpy()
        let clock = ManualProgressClock()
        let vm = makeViewModel(hapticAtMs: [200], clock: clock, haptics: haptics)
        vm.play()

        clock.advance(by: 0.9)

        #expect(haptics.played.count == 1)
    }

    @Test
    func aFastSeriesArrivesAsOnePattern() {
        let haptics = HapticPlayerSpy()
        let clock = ManualProgressClock()
        let marks = (0 ..< 8).map { 250 + $0 * 30 }
        let vm = makeViewModel(hapticAtMs: marks, clock: clock, haptics: haptics)
        vm.play()

        clock.advance(by: 0.6)

        #expect(haptics.played.count == 1)
        #expect(haptics.played[0].offsets.count == 8)
    }

    @Test
    func pauseSilencesTheRunningPatternAndWhatWouldFollow() {
        let haptics = HapticPlayerSpy()
        let clock = ManualProgressClock()
        let vm = makeViewModel(hapticAtMs: [200, 600], clock: clock, haptics: haptics)
        vm.play()

        clock.advance(by: 0.25)
        vm.pause()
        clock.advance(by: 0.5)

        #expect(haptics.stopPlaybackCount == 1)
        #expect(haptics.played.map(\.startMs) == [200])
    }

    @Test
    func replayingTheSlideFiresItsMarksAgain() {
        let haptics = HapticPlayerSpy()
        let clock = ManualProgressClock()
        let vm = makeViewModel(hapticAtMs: [200], clock: clock, haptics: haptics)
        vm.play()
        clock.advance(by: 0.5)

        vm.restart()
        clock.advance(by: 0.5)

        #expect(haptics.played.count == 2)
    }

    @Test
    func aSlideWithoutMarksNeverWarmsTheEngine() {
        let haptics = HapticPlayerSpy()
        let vm = makeViewModel(hapticAtMs: [], clock: ManualProgressClock(), haptics: haptics)

        vm.prepare()

        #expect(haptics.prepareCount == 0)
    }

    @Test
    func aSlideWithMarksWarmsTheEngineBeforeItPlays() {
        let haptics = HapticPlayerSpy()
        let vm = makeViewModel(hapticAtMs: [200], clock: ManualProgressClock(), haptics: haptics)

        vm.prepare()

        #expect(haptics.prepareCount == 1)
        #expect(haptics.played.isEmpty)
    }

    // MARK: - Helpers

    private func makeViewModel(
        hapticAtMs: [Int],
        clock: ManualProgressClock,
        haptics: HapticPlayerSpy
    ) -> SlidePlayerViewModel {
        let slide = SlideV2(
            id: "s",
            order: 1,
            title: "t",
            subtitle: "s",
            asset: AssetV2(type: .image, durationMs: 1000, url: nil),
            hapticAtMs: hapticAtMs
        )

        return SlidePlayerViewModel(slide: slide, clock: clock, hapticPlayer: haptics)
    }
}

@Suite("Stories V2 story haptics")
@MainActor
struct StoryPlayerHapticsTests {
    @Test
    func foregroundingWarmsTheEngineForAStoryThatVibrates() {
        let haptics = HapticPlayerSpy()
        let player = makePlayer(hapticAtMs: [200], haptics: haptics)

        postDidBecomeActive()

        #expect(haptics.prepareCount == 1)
        withExtendedLifetime(player) {}
    }

    @Test
    func foregroundingLeavesTheEngineDownForAStoryWithoutMarks() {
        let haptics = HapticPlayerSpy()
        let player = makePlayer(hapticAtMs: [], haptics: haptics)

        postDidBecomeActive()

        #expect(haptics.prepareCount == 0)
        withExtendedLifetime(player) {}
    }

    @Test
    func foregroundingLeavesTheEngineDownOnceTheStoryEnded() {
        let haptics = HapticPlayerSpy()
        let player = makePlayer(hapticAtMs: [200], haptics: haptics)
        player.closeButtonTapped()

        postDidBecomeActive()

        #expect(haptics.prepareCount == 0)
        #expect(haptics.shutdownCount == 1)
    }

    // MARK: - Helpers

    private func postDidBecomeActive() {
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func makePlayer(hapticAtMs: [Int], haptics: HapticPlayerSpy) -> StoryPlayerViewModel {
        let slide = SlideV2(
            id: "s",
            order: 1,
            title: "t",
            subtitle: "s",
            asset: AssetV2(type: .image, durationMs: 1000, url: nil),
            hapticAtMs: hapticAtMs
        )

        let story = StoryV2(
            id: "story",
            endBehavior: .finish,
            slides: [slide],
            origin: .bundled
        )

        return StoryPlayerViewModel(
            story: story,
            source: .main,
            hapticPlayer: haptics,
            clock: ManualProgressClock(),
            onFinished: { _, _ in }
        )
    }
}

@MainActor
private final class HapticPlayerSpy: StoryHapticPlaying {
    private(set) var played: [HapticCluster] = []
    private(set) var prepareCount = 0
    private(set) var stopPlaybackCount = 0
    private(set) var shutdownCount = 0

    func prepare() {
        prepareCount += 1
    }

    func play(_ cluster: HapticCluster) {
        played.append(cluster)
    }

    func stopPlayback() {
        stopPlaybackCount += 1
    }

    func shutdown() {
        shutdownCount += 1
    }
}
