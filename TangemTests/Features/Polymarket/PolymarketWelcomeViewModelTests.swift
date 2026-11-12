//
//  PolymarketWelcomeViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemUI
@testable import Tangem

@Suite("Polymarket welcome: the fast trading switch")
struct PolymarketWelcomeViewModelTests {
    private let coordinator = WelcomeRoutableStub()

    @Test("The switch starts at the setting the card tap uses, and flipping it changes that setting", arguments: [true, false])
    func switchFollowsOnboardingFastTrading(_ isEnabled: Bool) {
        let fastTrading = PolymarketOnboardingFastTradingSpy()
        fastTrading.isEnabled = isEnabled

        let sut = makeSUT(fastTrading: fastTrading)

        #expect(sut.isFastTradingEnabled == isEnabled)

        sut.isFastTradingEnabled.toggle()

        #expect(fastTrading.isEnabled == !isEnabled)
    }
}

// MARK: - Helpers

private extension PolymarketWelcomeViewModelTests {
    func makeSUT(fastTrading: PolymarketOnboardingFastTrading) -> PolymarketWelcomeViewModel {
        PolymarketWelcomeViewModel(
            interactor: OnboardingInteractorStub(),
            hasExistingAccount: false,
            signingButtonType: .requiredNFCInteraction,
            fastTrading: fastTrading,
            coordinator: coordinator
        )
    }
}

// MARK: - Stubs

private struct OnboardingInteractorStub: PolymarketOnboardingInteractor {
    func onboard() -> AsyncStream<PolymarketOnboardingProgress> {
        AsyncStream { $0.finish() }
    }
}

private final class WelcomeRoutableStub: PolymarketWelcomeRoutable {
    func onboardingDidStart() {}
    func onboardingDidFinish(isNewAccount: Bool) {}
    func openRegionWarning() {}
    func openLegalTerms(url: URL) {}
    func dismiss() {}
}
