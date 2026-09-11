//
//  OnrampRegionRestrictionTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemExpress

@Suite("Onramp region restriction")
struct OnrampRegionRestrictionTests {
    // MARK: - Provider predicates

    @Test("A restricted offer is loaded but not executable")
    func restrictedProviderIsLoadedButNotExecutable() {
        let provider = OnrampTestFixtures.makeProvider(state: .loaded(Self.makeQuote(isRestricted: true)))

        // The offer list filters by `isSuccessfullyLoaded`, so it has to stay true — otherwise the
        // restricted offer disappears instead of being shown dimmed.
        #expect(provider.isSuccessfullyLoaded)
        #expect(provider.isRestricted)
        #expect(!provider.isExecutable)
    }

    @Test("An ordinary offer stays executable")
    func ordinaryProviderIsExecutable() {
        let provider = OnrampTestFixtures.makeProvider(state: .loaded(Self.makeQuote(isRestricted: false)))

        #expect(!provider.isRestricted)
        #expect(provider.isExecutable)
    }

    @Test("A provider without a quote is never reported as restricted")
    func providerWithoutQuoteIsNotRestricted() {
        let provider = OnrampTestFixtures.makeProvider(state: .idle)

        #expect(!provider.isRestricted)
        #expect(!provider.isExecutable)
    }

    // MARK: - Badge

    @Test("A restricted offer shows the restriction badge instead of an advantage one")
    func restrictedProviderGetsRestrictedBadge() {
        let provider = OnrampTestFixtures.makeProvider(state: .loaded(Self.makeQuote(isRestricted: true)))
        provider.update(globalAttractiveType: .best)

        let badge = OnrampAmountBadgeBuilder().mapToOnrampAmountBadge(provider: provider)

        #expect(badge == .restricted)
    }

    @Test("An ordinary best-rate offer keeps its advantage badge")
    func ordinaryProviderKeepsAdvantageBadge() {
        let provider = OnrampTestFixtures.makeProvider(state: .loaded(Self.makeQuote(isRestricted: false)))
        provider.update(globalAttractiveType: .best)

        let badge = OnrampAmountBadgeBuilder().mapToOnrampAmountBadge(provider: provider)

        #expect(badge == .best)
    }

    // MARK: - Suggested offers

    /// The mockup keeps a restricted offer on screen, dimmed, rather than dropping it from the list.
    @Test("A restricted offer is still suggested")
    func restrictedProviderRemainsSuggested() {
        let restricted = OnrampTestFixtures.makeProvider(
            providerId: "restricted",
            paymentMethodId: "card",
            state: .loaded(Self.makeQuote(isRestricted: true))
        )

        let list = [ProviderItem(paymentMethod: restricted.paymentMethod, providers: [restricted])]

        let result = CommonOnrampSummaryInteractor.mapToSuggestedOffers(
            selectedProvider: .success(restricted),
            providers: .success(list),
            recentOnrampTransaction: nil
        )

        guard case .success(let offers) = result else {
            Issue.record("Expected suggested offers, got \(result)")
            return
        }

        #expect(offers.contains { $0.provider === restricted })
    }

    @Test("A restricted offer carries the restriction badge on the summary screen too")
    func suggestedRestrictedOfferKeepsBadge() {
        let restricted = OnrampTestFixtures.makeProvider(state: .loaded(Self.makeQuote(isRestricted: true)))

        let viewModel = OnrampSuggestedOfferViewModelBuilder(tokenItem: Self.tokenItem).mapToOnrampOfferViewModel(
            title: .text(""),
            provider: restricted,
            buyAction: .button {}
        )

        #expect(viewModel.amount.badge == .restricted)
        #expect(!viewModel.isAvailable)
    }

    // MARK: - Default selection

    @Test("The default selection skips a restricted provider even with the better rate")
    func defaultSelectionSkipsRestricted() {
        let restricted = OnrampTestFixtures.makeProvider(
            providerId: "restricted",
            state: .loaded(Self.makeQuote(expectedAmount: 200, isRestricted: true))
        )
        let ordinary = OnrampTestFixtures.makeProvider(
            providerId: "ordinary",
            state: .loaded(Self.makeQuote(expectedAmount: 100, isRestricted: false))
        )

        let item = ProviderItem(paymentMethod: restricted.paymentMethod, providers: [restricted, ordinary])
        item.sort()

        #expect(item.maxPriorityProvider() === restricted)
        #expect(item.maxPriorityUnrestrictedProvider() === ordinary)
    }

    @Test("Nothing is preferred when every provider is restricted, so the caller keeps its fallback")
    func defaultSelectionHasNoCandidateWhenEverythingIsRestricted() {
        let restricted = OnrampTestFixtures.makeProvider(state: .loaded(Self.makeQuote(isRestricted: true)))
        let item = ProviderItem(paymentMethod: restricted.paymentMethod, providers: [restricted])

        #expect(item.maxPriorityUnrestrictedProvider() == nil)
        #expect(item.selectableProvider() === restricted)
    }

    // MARK: - Payment method row

    @Test("The payment method is priced by a provider the user can pay with")
    func paymentMethodRowSkipsRestricted() {
        let restricted = OnrampTestFixtures.makeProvider(
            providerId: "restricted",
            state: .loaded(Self.makeQuote(expectedAmount: 200, isRestricted: true))
        )
        let ordinary = OnrampTestFixtures.makeProvider(
            providerId: "ordinary",
            state: .loaded(Self.makeQuote(expectedAmount: 100, isRestricted: false))
        )

        let item = ProviderItem(paymentMethod: restricted.paymentMethod, providers: [restricted, ordinary])
        item.sort()

        let viewModel = OnrampProviderItemViewModelBuilder(tokenItem: Self.tokenItem)
            .mapToOnrampProviderItemViewModel(providerItem: item) {}

        guard case .available(let amount) = viewModel.amountType else {
            Issue.record("Expected an available amount, got \(viewModel.amountType)")
            return
        }

        #expect(amount.formatted.contains("100"))
        #expect(amount.badge != .restricted)
        #expect(viewModel.isAvailable)
    }

    @Test("A wholly restricted payment method keeps its price but stops looking available")
    func paymentMethodRowFallsBackToRestricted() {
        let restricted = OnrampTestFixtures.makeProvider(
            providerId: "restricted",
            state: .loaded(Self.makeQuote(expectedAmount: 200, isRestricted: true))
        )

        let item = ProviderItem(paymentMethod: restricted.paymentMethod, providers: [restricted])

        let viewModel = OnrampProviderItemViewModelBuilder(tokenItem: Self.tokenItem)
            .mapToOnrampProviderItemViewModel(providerItem: item) {}

        guard case .available(let amount) = viewModel.amountType else {
            Issue.record("Expected an available amount, got \(viewModel.amountType)")
            return
        }

        #expect(amount.formatted.contains("200"))
        #expect(amount.badge == .restricted)
        #expect(!viewModel.isAvailable)
    }

    // MARK: - Attractive types

    @Test("The best-rate slot goes to a provider the user can pay with")
    func bestSlotSkipsRestricted() {
        let restricted = OnrampTestFixtures.makeProvider(
            providerId: "restricted",
            state: .loaded(Self.makeQuote(expectedAmount: 200, isRestricted: true))
        )
        let ordinary = OnrampTestFixtures.makeProvider(
            providerId: "ordinary",
            state: .loaded(Self.makeQuote(expectedAmount: 100, isRestricted: false))
        )

        let list: ProvidersList = [ProviderItem(paymentMethod: restricted.paymentMethod, providers: [restricted, ordinary])]
        list.sortNestedProviders()
        list.updateAttractiveTypes()

        #expect(ordinary.globalAttractiveType == .best)
        #expect(restricted.globalAttractiveType != .best)
    }

    @Test("A restricted Apple Pay offer is not recommended as the fastest one")
    func fastestSkipsRestrictedApplePay() {
        let applePay = OnrampTestFixtures.makeProvider(
            providerId: "apple-pay-provider",
            paymentMethodId: "apple-pay",
            state: .loaded(Self.makeQuote(isRestricted: true))
        )
        let card = OnrampTestFixtures.makeProvider(
            providerId: "card-provider",
            paymentMethodId: "card",
            state: .loaded(Self.makeQuote(isRestricted: false))
        )

        let list: ProvidersList = [
            ProviderItem(paymentMethod: applePay.paymentMethod, providers: [applePay]),
            ProviderItem(paymentMethod: card.paymentMethod, providers: [card]),
        ]
        list.sortNestedProviders()
        list.updateAttractiveTypes()
        list.updateProcessingTimeTypes(preferredProviderId: nil)

        #expect(list.fastest() !== applePay)
    }
}

// MARK: - Helpers

private extension OnrampRegionRestrictionTests {
    static let tokenItem: TokenItem = .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))

    static func makeQuote(expectedAmount: Decimal = 100, isRestricted: Bool) -> OnrampQuote {
        OnrampQuote(
            expectedAmount: expectedAmount,
            nativePaymentAvailable: true,
            quoteId: "quote-id",
            isRestricted: isRestricted
        )
    }
}
