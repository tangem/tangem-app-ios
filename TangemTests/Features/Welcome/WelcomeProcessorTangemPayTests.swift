//
//  WelcomeProcessorTangemPayTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
@testable import Tangem

@Suite("WelcomeProcessor Tangem Pay deep links", .timeLimit(.minutes(1)))
@MainActor
struct WelcomeProcessorTangemPayTests {
    @Test("Without mobile wallets an onboarding pending from the last launch is dropped")
    func pendingOnboardingIsDroppedWithoutMobileWallets() async {
        await withDeepLinkInputs { _ in
            var flags = makeOnboardingFlagChanges()

            AppSettings.shared.needsTangemPayMobileOnboarding = true
            await consume(&flags, until: true)

            let sut = makeSUT(isMobileWalletAvailable: false)
            await consume(&flags, until: false)

            #expect(sut.state.deepLink == nil)
        }
    }

    @Test("Without mobile wallets every onboarding requested during the session is dropped")
    func requestedOnboardingsAreDroppedWithoutMobileWallets() async {
        await withDeepLinkInputs { _ in
            let sut = makeSUT(isMobileWalletAvailable: false)
            var flags = makeOnboardingFlagChanges()

            AppSettings.shared.needsTangemPayMobileOnboarding = true
            await consume(&flags, until: true)
            await consume(&flags, until: false)

            AppSettings.shared.needsTangemPayMobileOnboarding = true
            await consume(&flags, until: true)
            await consume(&flags, until: false)

            #expect(sut.state.deepLink == nil)
        }
    }

    @Test("Without mobile wallets a campaign pending from the last launch is dropped")
    func pendingCampaignIsDroppedWithoutMobileWallets() async {
        await withDeepLinkInputs(pendingCampaignKey: Constants.campaignKey) { storage in
            let sut = makeSUT(isMobileWalletAvailable: false)

            await waitForCampaignKey(nil, in: storage)

            #expect(sut.state.deepLink == nil)
        }
    }

    @Test("Without mobile wallets every campaign arriving during the session is dropped")
    func arrivingCampaignsAreDroppedWithoutMobileWallets() async {
        await withDeepLinkInputs { storage in
            let sut = makeSUT(isMobileWalletAvailable: false)

            storage.pendingCampaignKey = Constants.campaignKey
            await waitForCampaignKey(nil, in: storage)

            storage.pendingCampaignKey = Constants.campaignKey
            await waitForCampaignKey(nil, in: storage)

            #expect(sut.state.deepLink == nil)
        }
    }

    @Test("With mobile wallets a pending onboarding opens Tangem Pay and stays pending")
    func pendingOnboardingOpensTangemPay() async {
        await withDeepLinkInputs(needsOnboarding: true) { _ in
            let sut = makeSUT(isMobileWalletAvailable: true)

            let deepLink = await waitForDeepLink(of: sut)

            #expect(deepLink == .tangemPay)
            #expect(AppSettings.shared.needsTangemPayMobileOnboarding)
        }
    }

    @Test("With mobile wallets a pending campaign opens the campaign and stays pending")
    func pendingCampaignOpensCampaign() async {
        await withDeepLinkInputs(pendingCampaignKey: Constants.campaignKey) { storage in
            let sut = makeSUT(isMobileWalletAvailable: true)

            let deepLink = await waitForDeepLink(of: sut)

            #expect(deepLink == .tangemPayCampaign(campaignKey: Constants.campaignKey))
            #expect(storage.pendingCampaignKey == Constants.campaignKey)
        }
    }
}

// MARK: - Helpers

private extension WelcomeProcessorTangemPayTests {
    enum Constants {
        static let campaignKey = "tpay_for_harvard123"
    }

    func makeSUT(isMobileWalletAvailable: Bool) -> WelcomeProcessor {
        WelcomeProcessor(
            isIdle: Just(true).eraseToAnyPublisher(),
            isMobileWalletAvailable: isMobileWalletAvailable
        )
    }

    typealias FlagChanges = AsyncPublisher<AnyPublisher<Bool, Never>>.Iterator

    func makeOnboardingFlagChanges() -> FlagChanges {
        AppSettings.shared.$needsTangemPayMobileOnboarding
            .dropFirst()
            .buffer(size: 16, prefetch: .keepFull, whenFull: .dropNewest)
            .eraseToAnyPublisher()
            .values
            .makeAsyncIterator()
    }

    func consume(_ flags: inout FlagChanges, until value: Bool) async {
        while let flag = await flags.next(), flag != value {}
    }

    func waitForCampaignKey(_ value: String?, in storage: TangemPayCampaignKeyStorageStub) async {
        _ = await storage.pendingCampaignKeyPublisher.values.first { $0 == value }
    }

    func waitForDeepLink(of sut: WelcomeProcessor) async -> WelcomeProcessor.State.DeepLink? {
        await sut.statePublisher.values.compactMap(\.deepLink).first { _ in true }
    }

    func withDeepLinkInputs(
        needsOnboarding: Bool = false,
        pendingCampaignKey: String? = nil,
        _ body: (TangemPayCampaignKeyStorageStub) async -> Void
    ) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousCampaignKeyStorage = InjectedValues[\.tangemPayCampaignKeyStorage]
            let previousNeedsOnboarding = AppSettings.shared.needsTangemPayMobileOnboarding
            let previousShowsPromo = AppSettings.shared.shouldShowMobilePromoWalletSelector

            let storage = TangemPayCampaignKeyStorageStub(pendingCampaignKey: pendingCampaignKey)
            InjectedValues[\.tangemPayCampaignKeyStorage] = storage
            AppSettings.shared.needsTangemPayMobileOnboarding = needsOnboarding
            AppSettings.shared.shouldShowMobilePromoWalletSelector = false

            defer {
                InjectedValues[\.tangemPayCampaignKeyStorage] = previousCampaignKeyStorage
                AppSettings.shared.needsTangemPayMobileOnboarding = previousNeedsOnboarding
                AppSettings.shared.shouldShowMobilePromoWalletSelector = previousShowsPromo
            }

            await body(storage)
        }
    }
}
