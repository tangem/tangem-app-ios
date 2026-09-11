//
//  SlidePlayerViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import Foundation
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
        #expect(vm.progress < 0.0001)

        clock.advance(by: 0.5) // half of the 1s duration
        #expect(abs(vm.progress - 0.5) < 0.05)
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
        #expect(abs(vm.progress - 1) < 0.0001)
    }

    @Test
    func pauseHaltsProgress() {
        let clock = ManualProgressClock()
        let vm = SlidePlayerViewModel(slide: imageSlide(durationMs: 1000), clock: clock)
        vm.play()

        clock.advance(by: 0.3)
        let progressAtPause = vm.progress
        vm.pause()
        clock.advance(by: 0.5) // ticks keep firing, but paused → ignored

        #expect(abs(vm.progress - progressAtPause) < 0.0001)
    }

    // MARK: - Helpers

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
