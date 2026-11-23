//
//  OnrampRecommendedSlotReplacementTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem
@testable import TangemExpress

@Suite("Recommended slot replacement by a pseudo-provider banner")
struct OnrampRecommendedSlotReplacementTests {
    @Test("A banner for the Great rate slot takes the place of the offer that stood there")
    func bestSlotReplacesGreatOffer() throws {
        let list = Self.makeList()
        let plain = recommended(list: list, replacedSlots: [])
        let index = try #require(plain.firstIndex { displayedSlot($0) == .greatRate })

        let replaced = recommended(list: list, replacedSlots: [.greatRate])

        #expect(replaced.count == plain.count)
        #expect(isSlot(replaced[index], .greatRate))
        #expect(!replaced.contains { displayedSlot($0) == .greatRate })
    }

    @Test("A banner for the Fastest slot takes the place of the fastest offer")
    func fastestSlotReplacesFastestOffer() throws {
        let list = Self.makeList()
        let plain = recommended(list: list, replacedSlots: [])
        let index = try #require(plain.firstIndex { displayedSlot($0) == .fastest })

        let replaced = recommended(list: list, replacedSlots: [.fastest])

        #expect(replaced.count == plain.count)
        #expect(isSlot(replaced[index], .fastest))
        #expect(!replaced.contains { displayedSlot($0) == .fastest })
    }

    @Test("Without a slot banner Recommended stays as it was")
    func noSlotKeepsOffers() {
        let list = Self.makeList()

        let entries = recommended(list: list, replacedSlots: [])

        #expect(!entries.isEmpty)
        #expect(entries.allSatisfy { offerProvider($0) != nil })
    }

    @Test("When the slot's offer is shown in Recent, Recent stays and the banner still takes the slot")
    func recentOfferIsNotReplaced() throws {
        let list = Self.makeList()
        let great = try #require(list.great() ?? list.best())
        let recentTransaction = RecentOnrampTransactionParameters(providerId: great.provider.id, paymentMethodId: great.paymentMethod.id)

        let offers = try #require(CommonOnrampSummaryInteractor.mapToSuggestedOffers(
            selectedProvider: .success(great),
            providers: .success(list),
            recentOnrampTransaction: recentTransaction,
            replacedSlots: [.greatRate]
        ).value)

        #expect(offers.recent === great)
        #expect(offers.recommended.contains { isSlot($0, .greatRate) })
        #expect(!offers.recommended.contains { offerProvider($0) === great })
    }

    @Test("When the only offer is in Recent, the banner stays out of an otherwise empty Recommended")
    func onlyRecentOfferLeavesRecommendedEmpty() throws {
        let provider = OnrampTestFixtures.makeProvider(
            providerId: "provider-card",
            paymentMethodId: "card",
            state: .loaded(OnrampQuote(expectedAmount: 200, nativePaymentAvailable: false, quoteId: "q1", isRestricted: false))
        )
        let list = OnrampTestFixtures.makeProvidersList([provider])
        let recentTransaction = RecentOnrampTransactionParameters(providerId: provider.provider.id, paymentMethodId: provider.paymentMethod.id)

        let offers = try #require(CommonOnrampSummaryInteractor.mapToSuggestedOffers(
            selectedProvider: .success(provider),
            providers: .success(list),
            recentOnrampTransaction: recentTransaction,
            replacedSlots: [.greatRate]
        ).value)

        #expect(offers.recent === provider)
        #expect(offers.recommended.isEmpty)
    }

    @Test("A Great rate slot with no offer in it puts the banner before the Fastest offer")
    func emptyBestSlotGoesBeforeFastest() {
        let entries = CommonOnrampSummaryInteractor.placing(
            replacedSlots: [.greatRate],
            in: [.fastest(OnrampTestFixtures.makeProvider(providerId: "fast", paymentMethodId: "card"))]
        )

        #expect(entries.count == 2)
        #expect(isSlot(entries[0], .greatRate))
    }

    @Test("When the only offer is shown as Great rate, a Fastest banner is added next to it instead of replacing it")
    func singleGreatOfferStaysForFastestBanner() {
        let only = OnrampTestFixtures.makeProvider(providerId: "only", paymentMethodId: "card")

        let entries = CommonOnrampSummaryInteractor.placing(replacedSlots: [.fastest], in: [.great(only)])

        #expect(entries.count == 2)
        #expect(offerProvider(entries[0]) === only)
        #expect(isSlot(entries[1], .fastest))
    }

    @Test("Native Apple Pay shown as Great rate is replaced by a Great rate banner, not by a Fastest one")
    func nativeApplePayFollowsItsDisplayedSlot() throws {
        let list = OnrampTestFixtures.makeProvidersList([
            OnrampTestFixtures.makeProvider(
                providerId: "provider-apple-pay",
                paymentMethodId: "apple-pay",
                state: .loaded(OnrampQuote(expectedAmount: 200, nativePaymentAvailable: true, quoteId: "q1", isRestricted: false))
            ),
            OnrampTestFixtures.makeProvider(
                providerId: "provider-card",
                paymentMethodId: "card",
                state: .loaded(OnrampQuote(expectedAmount: 100, nativePaymentAvailable: false, quoteId: "q2", isRestricted: false))
            ),
        ])
        let plain = recommended(list: list, replacedSlots: [])
        let applePayIndex = try #require(plain.firstIndex { entry in
            if case .offer(.nativeApplePay) = entry { return true }
            return false
        })
        try #require(displayedSlot(plain[applePayIndex]) == .greatRate)

        let withFastestBanner = recommended(list: list, replacedSlots: [.fastest])
        let withBestBanner = recommended(list: list, replacedSlots: [.greatRate])

        #expect(displayedSlot(withFastestBanner[applePayIndex]) == .greatRate)
        #expect(isSlot(withBestBanner[applePayIndex], .greatRate))
    }

    @Test("Without offers the screen keeps its empty state instead of a Recommended block with only the banner")
    func noOffersKeepsEmptyState() throws {
        let offers = try #require(CommonOnrampSummaryInteractor.mapToSuggestedOffers(
            selectedProvider: nil,
            providers: nil,
            recentOnrampTransaction: nil,
            replacedSlots: [.greatRate, .fastest]
        ).value)

        #expect(offers.recent == nil)
        #expect(offers.recommended.isEmpty)
    }
}

@Suite("Call-to-action banners split between the top of the screen and Recommended slots")
struct OnrampCallToActionLayoutTests {
    @Test("The first banner for a slot takes it; the rest keep their order")
    func firstBannerPerSlotTakesIt() {
        let first = Self.banner(id: 1, slot: .greatRate)
        let second = Self.banner(id: 2, slot: .greatRate)
        let unslotted = Self.banner(id: 3, slot: nil)

        let layout = OnrampSummaryViewModel.CallToActionLayout(banners: [first, second, unslotted])

        #expect(layout.bannersBySlot == [.greatRate: first])
        #expect(layout.all == [first, second, unslotted])
    }

    @Test("With slot replacement off, every banner stays on top")
    func slotReplacementOffKeepsBannersOnTop() {
        let best = Self.banner(id: 1, slot: .greatRate)
        let fastest = Self.banner(id: 2, slot: .fastest)
        let unslotted = Self.banner(id: 3, slot: nil)

        let layout = OnrampSummaryViewModel.CallToActionLayout(banners: [best, fastest, unslotted], replacesSlots: false)

        #expect(layout.bannersBySlot.isEmpty)
        #expect(layout.all == [best, fastest, unslotted])
    }

    @Test("A banner placed in Recommended is not shown on top")
    func bannerInRecommendedIsOffTop() {
        let banner = Self.banner(id: 1, slot: .greatRate)
        let state = OnrampSummaryViewModel.ViewState.suggestedOffers(.init(recent: nil, recommended: [.banner(banner)], hasMoreOffers: false))

        #expect(OnrampSummaryViewModel.bannerIdsOffTop(for: state, keptWhileLoading: []) == [1])
    }

    @Test("While quotes reload, a banner that stood in Recommended doesn't jump to the top")
    func bannerStaysOffTopWhileLoading() {
        #expect(OnrampSummaryViewModel.bannerIdsOffTop(for: .loading, keptWhileLoading: [1]) == [1])
    }

    @Test("Once Recommended is gone for good, the banner goes back to the top")
    func bannerReturnsToTopWithoutRecommended() {
        #expect(OnrampSummaryViewModel.bannerIdsOffTop(for: .idle, keptWhileLoading: [1]).isEmpty)
    }

    private static func banner(id: Int, slot: MarketingBanner.RecommendedSlot?) -> CallToActionMarketingBanner {
        .pseudoProvider(CallToActionMarketingBannerViewModel(
            id: id,
            title: "USD account",
            buttonTitle: "Activate",
            isGlowing: false,
            link: URL(string: "tangem://support")!,
            isDismissible: false,
            content: .init(categoryLabel: nil, subtitle: nil, etaLabel: nil, partnerLabel: nil, replacedSlot: slot)
        ))
    }
}

// MARK: - Helpers

private extension OnrampRecommendedSlotReplacementTests {
    static func makeList() -> ProvidersList {
        OnrampTestFixtures.makeProvidersList([
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
        ])
    }

    func recommended(list: ProvidersList, replacedSlots: Set<MarketingBanner.RecommendedSlot>) -> [OnrampSummaryRecommendedEntry] {
        let first = list.flatMap(\.providers).first
        let result = CommonOnrampSummaryInteractor.mapToSuggestedOffers(
            selectedProvider: first.map { .success($0) },
            providers: .success(list),
            recentOnrampTransaction: nil,
            replacedSlots: replacedSlots
        )

        return result.value?.recommended ?? []
    }

    func displayedSlot(_ entry: OnrampSummaryRecommendedEntry) -> MarketingBanner.RecommendedSlot? {
        if case .offer(let item) = entry {
            return item.displayedSlot
        }

        return nil
    }

    func offerProvider(_ entry: OnrampSummaryRecommendedEntry) -> OnrampProvider? {
        if case .offer(let item) = entry {
            return item.provider
        }

        return nil
    }

    func isSlot(_ entry: OnrampSummaryRecommendedEntry, _ slot: MarketingBanner.RecommendedSlot) -> Bool {
        if case .replacedSlot(let entrySlot) = entry {
            return entrySlot == slot
        }

        return false
    }
}
