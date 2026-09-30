//
//  StoryPlayerAnalyticsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
import TangemStories
@testable import Tangem

@MainActor
@Suite("StoryPlayerAnalyticsTests")
struct StoryPlayerAnalyticsTests {
    @Test
    func opensOnceAndReportsSlidesAndClose() {
        let spy = SpyStoriesAnalyticsProvider()
        let player = Self.makePlayer(spy: spy, source: .onboarding, clock: ManualProgressClock())

        player.start()
        player.start()
        player.tapForward()
        player.closeButtonTapped()

        #expect(spy.opened.count == 1)
        #expect(spy.opened.first?.source == .onboarding)
        #expect(spy.viewed.map(\.slideId) == ["s1", "s2"])
        #expect(spy.viewed.map(\.slideIndex) == [1, 2])
        #expect(spy.viewed.map(\.advanceReason) == [.tapForward, .storyClosed])
        #expect(spy.closed.count == 1)
        #expect(spy.closed.first?.watched == 2)
        #expect(spy.closed.first?.exitReason == .closeButton)
        #expect(spy.closed.first?.completed == false)
    }

    /// The analytics contract counts a manual return as a fresh view, unlike an unattended loop.
    @Test
    func manualRevisitReportsTheSlideAgain() {
        let spy = SpyStoriesAnalyticsProvider()
        let player = Self.makePlayer(spy: spy, source: .main, clock: ManualProgressClock())

        player.start()
        player.tapForward()
        player.tapBackward()
        player.tapForward()
        player.swipeDown()

        #expect(spy.viewed.map(\.slideId) == ["s1", "s2", "s1", "s2"])
        #expect(spy.viewed.map(\.advanceReason) == [.tapForward, .tapBack, .tapForward, .storyClosed])
        #expect(spy.closed.first?.watched == 2)
        #expect(spy.closed.first?.exitReason == .swipeDown)
    }

    @Test
    func tapBackOnTheFirstSlideStartsANewView() {
        let spy = SpyStoriesAnalyticsProvider()
        let player = Self.makePlayer(spy: spy, source: .main, clock: ManualProgressClock())

        player.start()
        player.tapBackward()
        player.closeButtonTapped()

        #expect(spy.viewed.map(\.slideId) == ["s1", "s1"])
        #expect(spy.viewed.map(\.advanceReason) == [.tapBack, .storyClosed])
        #expect(spy.closed.first?.watched == 1)
    }

    @Test
    func autoLoopCountsLoopsWithoutRepeatingSlides() {
        let spy = SpyStoriesAnalyticsProvider()
        let clock = ManualProgressClock()
        let player = Self.makePlayer(spy: spy, source: .main, endBehavior: .loop, clock: clock)

        player.start()
        // Two slides play themselves out, which wraps the story, then the first one plays again.
        clock.advance(by: Self.slideDurationSeconds * 3)
        player.closeButtonTapped()

        #expect(spy.viewed.map(\.slideId) == ["s1", "s2"])
        #expect(spy.viewed.map(\.advanceReason) == [.auto, .loopRestart])
        #expect(spy.closed.first?.loopsWatched == 1)
        #expect(spy.closed.first?.completed == true)
        #expect(spy.closed.first?.watched == 2)
    }

    @Test
    func tapBackOnTheFirstSlideAfterAnAutoLoopReportsItOnce() {
        let spy = SpyStoriesAnalyticsProvider()
        let clock = ManualProgressClock()
        let player = Self.makePlayer(spy: spy, source: .main, endBehavior: .loop, clock: clock)

        player.start()
        // Both slides play themselves out, which wraps the story back onto the first one.
        clock.advance(by: Self.slideDurationSeconds * 3)
        #expect(player.currentIndex == 0)

        player.tapBackward()

        #expect(spy.viewed.map(\.slideId) == ["s1", "s2"])
    }

    @Test
    func repeatedExitReportsTheStoryClosedOnce() {
        let spy = SpyStoriesAnalyticsProvider()
        var finishedCount = 0
        let player = Self.makePlayer(spy: spy, source: .main, clock: ManualProgressClock(), onFinished: { _, _ in
            finishedCount += 1
        })

        player.start()
        player.closeButtonTapped()
        player.closeButtonTapped()
        player.swipeDown()

        #expect(finishedCount == 1)
        #expect(spy.closed.count == 1)
        #expect(spy.viewed.map(\.slideId) == ["s1"])
    }

    @Test
    func actionExitCarriesTheAction() {
        let spy = SpyStoriesAnalyticsProvider()
        let player = Self.makePlayer(spy: spy, source: .main, clock: ManualProgressClock())
        let action = Self.makeStory(endBehavior: .finish).actions[0]

        player.start()
        player.actionTapped(action)

        #expect(spy.closed.first?.action?.id == action.id)
        #expect(spy.closed.first?.exitReason == .action)
    }

    /// A host that opens the action over the story reports the close itself, once that destination
    /// has taken the user away.
    @Test
    func handledActionDefersTheClose() {
        let spy = SpyStoriesAnalyticsProvider()
        let action = Self.makeStory(endBehavior: .finish).actions[0]
        var handled: [String] = []
        let player = Self.makePlayer(
            spy: spy,
            source: .onboarding,
            clock: ManualProgressClock(),
            onAction: { handled.append($0.id) }
        )

        player.start()
        player.actionTapped(action)

        #expect(handled == [action.id])
        #expect(spy.closed.isEmpty)

        player.finish(for: action)

        #expect(spy.closed.count == 1)
        #expect(spy.closed.first?.exitReason == .action)
        #expect(spy.closed.first?.action?.id == action.id)
    }

    @Test
    func aTapAfterTheFinishIsIgnored() {
        let spy = SpyStoriesAnalyticsProvider()
        let action = Self.makeStory(endBehavior: .finish).actions[0]
        var handled = 0
        let player = Self.makePlayer(
            spy: spy,
            source: .onboarding,
            clock: ManualProgressClock(),
            onAction: { _ in handled += 1 }
        )

        player.start()
        player.actionTapped(action)
        player.finish(for: action)
        player.actionTapped(action)

        #expect(handled == 1)
        #expect(spy.closed.count == 1)
    }

    /// Closing is the player's own business: a host routing the other targets must not have to
    /// remember this one.
    @Test
    func closeTargetEndsTheStoryEvenWhenAHostHandlesActions() {
        let spy = SpyStoriesAnalyticsProvider()
        let close = StoryActionV2(id: "close", label: "Got it", style: .secondary, target: .close)
        var handled: [String] = []
        let player = Self.makePlayer(
            spy: spy,
            source: .onboarding,
            clock: ManualProgressClock(),
            onAction: { handled.append($0.id) }
        )

        player.start()
        player.actionTapped(close)

        #expect(handled.isEmpty)
        #expect(spy.closed.count == 1)
        #expect(spy.closed.first?.exitReason == .action)
        #expect(spy.closed.first?.action?.id == close.id)
    }

    @Test
    func completionReportsNoAction() {
        let spy = SpyStoriesAnalyticsProvider()
        let clock = ManualProgressClock()
        var finished: [StoryActionV2?] = []
        let player = Self.makePlayer(spy: spy, source: .main, clock: clock, onFinished: { _, action in
            finished.append(action)
        })

        player.start()
        // Both slides play themselves out, and the story has nowhere to loop.
        clock.advance(by: Self.slideDurationSeconds * 3)

        #expect(spy.closed.count == 1)
        #expect(spy.closed.first?.exitReason == .completed)
        #expect(spy.closed.first?.action == nil)
        #expect(finished == [nil])
    }

    @Test
    func heldLastSlideStaysOpenAndStepsBack() {
        let spy = SpyStoriesAnalyticsProvider()
        let clock = ManualProgressClock()
        var finishedCount = 0
        let player = Self.makePlayer(spy: spy, source: .main, holdsLastSlide: true, clock: clock, onFinished: { _, _ in
            finishedCount += 1
        })

        player.start()
        clock.advance(by: Self.slideDurationSeconds * 3)

        #expect(player.currentIndex == 1)
        #expect(finishedCount == 0)
        #expect(spy.closed.isEmpty)

        player.tapBackward()

        #expect(player.currentIndex == 0)

        clock.advance(by: Self.slideDurationSeconds + 1)

        #expect(player.currentIndex == 1)

        player.closeButtonTapped()

        #expect(finishedCount == 1)
        #expect(spy.closed.count == 1)
        #expect(spy.closed.first?.exitReason == .closeButton)
        #expect(spy.closed.first?.completed == true)
    }

    // MARK: - Fixtures

    private static let slideDurationSeconds: Double = 10

    /// Every test drives its own manual clock, so no slide ever advances on its own.
    private static func makePlayer(
        spy: SpyStoriesAnalyticsProvider,
        source: StorySource,
        endBehavior: EndBehavior = .finish,
        holdsLastSlide: Bool = false,
        clock: any ProgressClock,
        onAction: ((StoryActionV2) -> Void)? = nil,
        onFinished: @escaping (StoryExitReason, StoryActionV2?) -> Void = { _, _ in }
    ) -> StoryPlayerViewModel {
        StoryPlayerViewModel(
            story: makeStory(endBehavior: endBehavior),
            source: source,
            analytics: spy,
            clock: clock,
            holdsLastSlide: holdsLastSlide,
            onAction: onAction,
            onFinished: onFinished
        )
    }

    private static func makeStory(endBehavior: EndBehavior) -> StoryV2 {
        func slide(_ id: String, _ order: Int) -> SlideV2 {
            SlideV2(
                id: id,
                order: order,
                title: "t",
                subtitle: "s",
                asset: AssetV2(type: .image, durationMs: Int(slideDurationSeconds) * 1000, url: nil)
            )
        }

        return StoryV2(
            id: "analytics_story",
            endBehavior: endBehavior,
            actions: [StoryActionV2(id: "cta", label: "Go", style: .primary, target: .deeplink("tangem://x"))],
            slides: [slide("s1", 1), slide("s2", 2)],
            origin: .bundled
        )
    }
}

@MainActor
private final class SpyStoriesAnalyticsProvider: StoriesAnalyticsProvider {
    struct Opened { let storyId: String; let source: StorySource }
    struct Viewed { let slideId: String; let slideIndex: Int; let advanceReason: StoryAdvanceReason; let completed: Bool }
    struct Closed { let watched: Int; let loopsWatched: Int; let completed: Bool; let exitReason: StoryExitReason; let action: StoryActionV2? }

    private(set) var opened: [Opened] = []
    private(set) var viewed: [Viewed] = []
    private(set) var closed: [Closed] = []

    nonisolated init() {}

    /// The protocol requirements are nonisolated, so the witnesses have to be too; the player only
    /// ever calls them from the main actor, which is what `assumeIsolated` records.
    nonisolated func logStoryOpened(storyId: String, slidesTotal: Int, source: StorySource, origin: ContentOrigin) {
        MainActor.assumeIsolated { opened.append(Opened(storyId: storyId, source: source)) }
    }

    nonisolated func logSlideViewed(
        storyId: String,
        slideId: String,
        slideIndex: Int,
        assetType: AssetType,
        assetDurationMs: Int,
        watchedMs: Int,
        completed: Bool,
        advanceReason: StoryAdvanceReason,
        source: StorySource
    ) {
        MainActor.assumeIsolated {
            viewed.append(Viewed(slideId: slideId, slideIndex: slideIndex, advanceReason: advanceReason, completed: completed))
        }
    }

    nonisolated func logStoryClosed(storyId: String, slidesTotal: Int, watched: Int, loopsWatched: Int, completed: Bool, exitReason: StoryExitReason, action: StoryActionV2?, source: StorySource) {
        MainActor.assumeIsolated {
            closed.append(Closed(watched: watched, loopsWatched: loopsWatched, completed: completed, exitReason: exitReason, action: action))
        }
    }
}
