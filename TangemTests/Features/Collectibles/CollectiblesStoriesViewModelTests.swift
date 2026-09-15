//
//  CollectiblesStoriesViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import CoreGraphics
import Testing
import TangemTestKit
@testable import Tangem

@Suite("CollectiblesStoriesViewModel", .timeLimit(.minutes(1)))
@MainActor
final class CollectiblesStoriesViewModelTests: LeakTrackingTestSuite {
    typealias SUT = CollectiblesStoriesViewModel

    @Test("Continue advances the story while slides are left")
    func continueAdvances() {
        let engine = StoriesEngineStub()

        let sut = makeSUT(slidesCount: 3, engine: engine)
        sut.onContinueTap()

        #expect(engine.nextSlideCallsCount == 1)
        #expect(sut.isFinished == false)
    }

    @Test("Continue on the last slide finishes instead of advancing")
    func continueFinishesOnLastSlide() {
        let engine = StoriesEngineStub()

        let sut = makeSUT(slidesCount: 1, engine: engine)
        sut.onContinueTap()

        #expect(sut.isFinished)
        #expect(engine.nextSlideCallsCount == 0)
    }

    @Test("Close finishes the story")
    func closeFinishes() {
        let sut = makeSUT()
        sut.onCloseTap()

        #expect(sut.isFinished)
    }

    @Test("Backward and pause are left to the engine")
    func engineDrivenControls() {
        let engine = StoriesEngineStub()

        let sut = makeSUT(engine: engine)
        sut.onBackwardTap()
        sut.onPressingChanged(true)

        #expect(engine.previousSlideCallsCount == 1)
        #expect(engine.pausedStates == [true])
    }

    @Test("The slides drive the progress bar and the first slide is shown")
    func exposesSlides() {
        let sut = makeSUT(slidesCount: 3)

        #expect(sut.slidesCount == 3)
        #expect(sut.currentSlide.title == "Slide 0")
    }
}

// MARK: - Helpers

private extension CollectiblesStoriesViewModelTests {
    func makeSUT(slidesCount: Int = 3, engine: StoriesEngineStub? = nil) -> SUT {
        let engine = engine ?? StoriesEngineStub()
        let sut = SUT(
            slides: (0 ..< slidesCount).map { .init(title: "Slide \($0)", subtitle: "", buttonTitle: "Next") },
            engine: { _ in engine }
        )

        return trackForMemoryLeaks(sut)
    }
}

// MARK: - Stubs

private final class StoriesEngineStub: CollectiblesStoriesEngine {
    private(set) var nextSlideCallsCount = 0
    private(set) var previousSlideCallsCount = 0
    private(set) var pausedStates: [Bool] = []

    var slideIndexPublisher: AnyPublisher<Int, Never> {
        Empty().eraseToAnyPublisher()
    }

    var slideProgressPublisher: AnyPublisher<CGFloat, Never> {
        Empty().eraseToAnyPublisher()
    }

    func start() {}

    func showNextSlide() {
        nextSlideCallsCount += 1
    }

    func showPreviousSlide() {
        previousSlideCallsCount += 1
    }

    func setPaused(_ isPaused: Bool) {
        pausedStates.append(isPaused)
    }
}
