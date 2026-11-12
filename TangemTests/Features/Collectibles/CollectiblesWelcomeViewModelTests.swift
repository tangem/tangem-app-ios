//
//  CollectiblesWelcomeViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemCollectibles
import TangemTestKit
@testable import Tangem

@Suite("CollectiblesWelcomeViewModel", .timeLimit(.minutes(1)))
@MainActor
final class CollectiblesWelcomeViewModelTests: LeakTrackingTestSuite {
    @Test("A finished reconnection closes the screen instead of opening the stories")
    func reconnectionClosesScreen() async {
        let routable = WelcomeRoutableSpy()
        let sut = makeSUT(routable: routable, purpose: .reconnection)
        var eventsIterator = routable.eventStream.makeAsyncIterator()

        sut.onActionTap()
        _ = await eventsIterator.next()

        #expect(routable.events == [.closeReconnection])
    }

    @Test("A reconnection that finds no account closes Packs instead of the screen")
    func reconnectionWithoutAccountClosesPacks() async {
        let routable = WelcomeRoutableSpy()
        let sut = makeSUT(routable: routable, purpose: .reconnection, relinkOutcome: .accountNotFound)

        sut.onActionTap()
        var eventsIterator = routable.eventStream.makeAsyncIterator()
        let event = await eventsIterator.next()

        #expect(event == .closeCollectibles)
    }
}

// MARK: - Helpers

private extension CollectiblesWelcomeViewModelTests {
    func makeSUT(
        routable: WelcomeRoutableSpy,
        purpose: CollectiblesWelcomeViewModel.Purpose,
        relinkOutcome: CollectiblesRelinkOutcome = .relinked
    ) -> CollectiblesWelcomeViewModel {
        let sut = CollectiblesWelcomeViewModel(
            routable: routable,
            onboarder: OnboarderStub(relinkOutcome: relinkOutcome),
            signingActionButtonType: .holdToConfirm,
            purpose: purpose
        )
        return trackForMemoryLeaks(sut)
    }
}

// MARK: - Doubles

private final class OnboarderStub: CollectiblesOnboarder, CollectiblesRelinker {
    private let relinkOutcome: CollectiblesRelinkOutcome

    init(relinkOutcome: CollectiblesRelinkOutcome) {
        self.relinkOutcome = relinkOutcome
    }

    func onboard() async throws {}

    func relink() async throws -> CollectiblesRelinkOutcome {
        relinkOutcome
    }
}

@MainActor
private final class WelcomeRoutableSpy: CollectiblesWelcomeRoutable {
    enum Event {
        case openStories
        case closeReconnection
        case closeCollectibles
    }

    let eventStream: AsyncStream<Event>

    private let eventContinuation: AsyncStream<Event>.Continuation

    private(set) var events: [Event] = []

    init() {
        (eventStream, eventContinuation) = AsyncStream.makeStream(of: Event.self)
    }

    func openStories() {
        record(.openStories)
    }

    func openLegalTerms(url: URL) {}

    func closeReconnection() {
        record(.closeReconnection)
    }

    func closeCollectibles() {
        record(.closeCollectibles)
    }

    private func record(_ event: Event) {
        events.append(event)
        eventContinuation.yield(event)
    }
}
