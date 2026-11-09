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

        sut.onActionTap()
        await waitUntil { routable.events.isNotEmpty }

        #expect(routable.events == [.closeReconnection])
    }
}

// MARK: - Helpers

private extension CollectiblesWelcomeViewModelTests {
    func makeSUT(routable: WelcomeRoutableSpy, purpose: CollectiblesWelcomeViewModel.Purpose) -> CollectiblesWelcomeViewModel {
        let sut = CollectiblesWelcomeViewModel(
            routable: routable,
            onboarder: OnboarderStub(),
            signingActionButtonType: .holdToConfirm,
            purpose: purpose
        )
        return trackForMemoryLeaks(sut)
    }
}

// MARK: - Doubles

private final class OnboarderStub: CollectiblesOnboarder {
    func onboard() async throws {}
}

@MainActor
private final class WelcomeRoutableSpy: CollectiblesWelcomeRoutable {
    enum Event {
        case openStories
        case closeReconnection
    }

    private(set) var events: [Event] = []

    func openStories() {
        events.append(.openStories)
    }

    func openLegalTerms(url: URL) {}

    func closeReconnection() {
        events.append(.closeReconnection)
    }
}
