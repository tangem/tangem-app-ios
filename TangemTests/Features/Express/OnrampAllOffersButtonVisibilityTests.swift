//
//  OnrampAllOffersButtonVisibilityTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemExpress

@Suite("All offers button on the Buy screen")
struct OnrampAllOffersButtonVisibilityTests {
    @Test("The button is hidden when every offer is already on the screen")
    func hiddenWhenEveryOfferIsShown() throws {
        let offers = try suggestedOffers(providers: [makeCardProvider(id: "only", amount: 100)], replacedSlots: [])

        #expect(!offers.hasMoreOffers)
    }

    @Test("The button is shown when All offers has offers the screen doesn't")
    func shownWhenSomeOffersAreHidden() throws {
        let offers = try suggestedOffers(
            providers: [
                makeCardProvider(id: "first", amount: 100),
                makeCardProvider(id: "second", amount: 90),
                makeCardProvider(id: "third", amount: 80),
            ],
            replacedSlots: []
        )

        #expect(offers.hasMoreOffers)
    }

    @Test("An offer replaced by a slot banner counts as not shown, so the button appears")
    func replacedOfferShowsButton() throws {
        let providers = [
            OnrampTestFixtures.makeProvider(
                providerId: "provider-card",
                paymentMethodId: "card",
                state: .loaded(OnrampQuote(expectedAmount: 200, nativePaymentAvailable: false, quoteId: "q1", isRestricted: false))
            ),
            OnrampTestFixtures.makeProvider(
                providerId: "provider-apple-pay",
                paymentMethodId: "apple-pay",
                state: .loaded(OnrampQuote(expectedAmount: 100, nativePaymentAvailable: true, quoteId: "q2", isRestricted: false))
            ),
        ]

        let plain = try suggestedOffers(providers: providers, replacedSlots: [])
        let replaced = try suggestedOffers(providers: providers, replacedSlots: [.greatRate])

        #expect(!plain.hasMoreOffers)
        #expect(replaced.hasMoreOffers)
    }

    @Test("An offer that failed to load isn't in All offers and doesn't keep the button")
    func failedOfferIsNotCounted() throws {
        let offers = try suggestedOffers(
            providers: [
                makeCardProvider(id: "loaded", amount: 100),
                OnrampTestFixtures.makeProvider(providerId: "failed", paymentMethodId: "card", state: .failed(error: TestError())),
            ],
            replacedSlots: []
        )

        #expect(!offers.hasMoreOffers)
    }
}

// MARK: - Helpers

private extension OnrampAllOffersButtonVisibilityTests {
    struct TestError: Error {}

    func makeCardProvider(id: String, amount: Decimal) -> OnrampProvider {
        OnrampTestFixtures.makeProvider(
            providerId: id,
            paymentMethodId: "card",
            amount: amount,
            state: .loaded(OnrampQuote(expectedAmount: amount, nativePaymentAvailable: false, quoteId: id, isRestricted: false))
        )
    }

    func suggestedOffers(
        providers: [OnrampProvider],
        replacedSlots: Set<MarketingBanner.RecommendedSlot>
    ) throws -> OnrampSummarySuggestedOffers {
        let list = OnrampTestFixtures.makeProvidersList(providers)

        return try #require(CommonOnrampSummaryInteractor.mapToSuggestedOffers(
            selectedProvider: .success(providers[0]),
            providers: .success(list),
            recentOnrampTransaction: nil,
            replacedSlots: replacedSlots
        ).value)
    }
}
