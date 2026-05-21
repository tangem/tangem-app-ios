//
//  OnrampSummaryInteractorSuggestedOffersTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem
@testable import TangemExpress

@Suite("OnrampSummaryInteractor.mapToSuggestedOffers")
struct OnrampSummaryInteractorSuggestedOffersTests {
    @Test("Native Apple Pay is placed first even when another payment method has a higher rate")
    func nativeApplePayWinsOverHigherRateOtherMethod() {
        let nativeApplePay = OnrampTestFixtures.makeProvider(
            providerId: "provider-apple-pay",
            paymentMethodId: "apple-pay",
            amount: 100,
            state: .loaded(OnrampQuote(expectedAmount: 100, nativePaymentAvailable: true, quoteId: "q1"))
        )
        let cardWithBetterRate = OnrampTestFixtures.makeProvider(
            providerId: "provider-card",
            paymentMethodId: "card",
            amount: 100,
            state: .loaded(OnrampQuote(expectedAmount: 200, nativePaymentAvailable: false, quoteId: "q2"))
        )

        let list = makeProvidersList([nativeApplePay, cardWithBetterRate])

        let result = CommonOnrampSummaryInteractor.mapToSuggestedOffers(
            selectedProvider: .success(nativeApplePay),
            providers: .success(list),
            recentOnrampTransaction: nil
        )

        let offers = unwrapSuccess(result)
        #expect(firstCase(offers) == .nativeApplePay)
        #expect(offers.first?.provider === nativeApplePay)
    }

    @Test("Native Apple Pay wins over a widget Apple Pay provider with a higher rate")
    func nativeApplePayWinsOverHigherRateWidgetApplePay() {
        let nativeApplePay = OnrampTestFixtures.makeProvider(
            providerId: "provider-native",
            paymentMethodId: "apple-pay",
            amount: 100,
            state: .loaded(OnrampQuote(expectedAmount: 100, nativePaymentAvailable: true, quoteId: "q1"))
        )
        let widgetApplePay = OnrampTestFixtures.makeProvider(
            providerId: "provider-widget",
            paymentMethodId: "apple-pay",
            amount: 100,
            state: .loaded(OnrampQuote(expectedAmount: 200, nativePaymentAvailable: false, quoteId: "q2"))
        )

        let list = makeProvidersList([nativeApplePay, widgetApplePay])

        let result = CommonOnrampSummaryInteractor.mapToSuggestedOffers(
            selectedProvider: .success(nativeApplePay),
            providers: .success(list),
            recentOnrampTransaction: nil
        )

        let offers = unwrapSuccess(result)
        #expect(firstCase(offers) == .nativeApplePay)
        #expect(offers.first?.provider === nativeApplePay)
    }

    @Test("No native Apple Pay candidate keeps legacy [great, fastest] ordering")
    func noNativeApplePayPreservesLegacyOrdering() {
        let card = OnrampTestFixtures.makeProvider(
            providerId: "provider-card",
            paymentMethodId: "card",
            amount: 100,
            state: .loaded(OnrampQuote(expectedAmount: 200, nativePaymentAvailable: false, quoteId: "q1"))
        )
        let sepa = OnrampTestFixtures.makeProvider(
            providerId: "provider-sepa",
            paymentMethodId: "sepa",
            amount: 100,
            state: .loaded(OnrampQuote(expectedAmount: 150, nativePaymentAvailable: false, quoteId: "q2"))
        )

        let list = makeProvidersList([card, sepa])

        let result = CommonOnrampSummaryInteractor.mapToSuggestedOffers(
            selectedProvider: .success(card),
            providers: .success(list),
            recentOnrampTransaction: nil
        )

        let offers = unwrapSuccess(result)
        #expect(!offers.contains(where: { firstCaseFor($0) == .nativeApplePay }))
    }

    @Test("Recent transaction sharing the native Apple Pay provider yields a single nativeApplePay entry")
    func nativeApplePayWinsOverRecentSameProvider() {
        let nativeApplePay = OnrampTestFixtures.makeProvider(
            providerId: "provider-apple-pay",
            paymentMethodId: "apple-pay",
            amount: 100,
            state: .loaded(OnrampQuote(expectedAmount: 100, nativePaymentAvailable: true, quoteId: "q1"))
        )
        let other = OnrampTestFixtures.makeProvider(
            providerId: "provider-card",
            paymentMethodId: "card",
            amount: 100,
            state: .loaded(OnrampQuote(expectedAmount: 50, nativePaymentAvailable: false, quoteId: "q2"))
        )

        let list = makeProvidersList([nativeApplePay, other])

        let recentTransaction = RecentOnrampTransactionParameters(
            providerId: nativeApplePay.provider.id,
            paymentMethodId: nativeApplePay.paymentMethod.id
        )

        let result = CommonOnrampSummaryInteractor.mapToSuggestedOffers(
            selectedProvider: .success(nativeApplePay),
            providers: .success(list),
            recentOnrampTransaction: recentTransaction
        )

        let offers = unwrapSuccess(result)
        #expect(firstCase(offers) == .nativeApplePay)
        #expect(!offers.contains(where: { firstCaseFor($0) == .recent }))
        let applePayEntries = offers.filter { $0.provider === nativeApplePay }
        #expect(applePayEntries.count == 1)
    }

    @Test("Same provider qualifying for nativeApplePay and great keeps a single entry at index 0")
    func dedupKeepsNativeApplePaySlot() {
        let onlyProvider = OnrampTestFixtures.makeProvider(
            providerId: "provider-apple-pay",
            paymentMethodId: "apple-pay",
            amount: 100,
            state: .loaded(OnrampQuote(expectedAmount: 100, nativePaymentAvailable: true, quoteId: "q1"))
        )

        // Second provider keeps `updateAttractiveTypes` from returning early (it requires >1 providers)
        let other = OnrampTestFixtures.makeProvider(
            providerId: "provider-card",
            paymentMethodId: "card",
            amount: 100,
            state: .loaded(OnrampQuote(expectedAmount: 50, nativePaymentAvailable: false, quoteId: "q2"))
        )

        let list = makeProvidersList([onlyProvider, other])

        let result = CommonOnrampSummaryInteractor.mapToSuggestedOffers(
            selectedProvider: .success(onlyProvider),
            providers: .success(list),
            recentOnrampTransaction: nil
        )

        let offers = unwrapSuccess(result)
        #expect(firstCase(offers) == .nativeApplePay)
        let applePayEntries = offers.filter { $0.provider === onlyProvider }
        #expect(applePayEntries.count == 1)
    }

    // MARK: - Helpers

    private func makeProvidersList(_ providers: [OnrampProvider]) -> ProvidersList {
        let grouped = Dictionary(grouping: providers, by: { $0.paymentMethod.id })
        let items = grouped.map { _, providers in
            ProviderItem(paymentMethod: providers[0].paymentMethod, providers: providers)
        }
        items.forEach { $0.sort() }
        let list: ProvidersList = items
        list.updateAttractiveTypes()
        list.updateProcessingTimeTypes(preferredProviderId: nil)
        return list
    }

    private func unwrapSuccess(
        _ result: LoadingResult<OnrampSummaryInteractorSuggestedOffers, Never>
    ) -> OnrampSummaryInteractorSuggestedOffers {
        switch result {
        case .success(let offers): return offers
        case .loading: Issue.record("Expected .success, got .loading"); return []
        case .failure: Issue.record("Expected .success, got .failure"); return []
        }
    }

    private func firstCase(_ offers: OnrampSummaryInteractorSuggestedOffers) -> SuggestedOfferCase? {
        offers.first.flatMap(firstCaseFor)
    }

    private func firstCaseFor(_ item: OnrampSummaryInteractorSuggestedOfferItem) -> SuggestedOfferCase {
        switch item {
        case .recent: .recent
        case .nativeApplePay: .nativeApplePay
        case .great: .great
        case .fastest: .fastest
        case .plain: .plain
        }
    }

    private enum SuggestedOfferCase {
        case recent
        case nativeApplePay
        case great
        case fastest
        case plain
    }
}
