//
//  AppsFlyerMarketingActivityHandlerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("AppsFlyerMarketingActivityHandler")
@MainActor
struct AppsFlyerMarketingActivityHandlerTests {
    private let bindingService = MarketingActivityBindingServiceSpy()

    @Test(
        "The uid in deep_link_sub3 is registered whatever the link names",
        arguments: ["referral", "tpay_mobileonboard", "tpay_for_some-campaign", "some_future_scenario", ""]
    )
    func registersForAnyDeepLinkValue(deepLinkValue: String) async {
        await withServices {
            AppsFlyerDeepLinkResolver().resolve(clickEvent: [
                "deep_link_value": deepLinkValue,
                "deep_link_sub3": OneLink.uid,
            ])

            #expect(bindingService.registeredUids == [OneLink.uid])
        }
    }

    @Test("A deferred link, which brings nothing but its deep link parameters, registers its uid")
    func registersDeferredLink() async {
        await withServices {
            AppsFlyerDeepLinkResolver().resolve(clickEvent: ["deep_link_sub3": OneLink.uid])

            #expect(bindingService.registeredUids == [OneLink.uid])
        }
    }

    @Test("The uid is registered exactly as AppsFlyer delivers it", arguments: ["AbC-123", " AbC-123 ", "abc-123"])
    func registersUidAsDelivered(uid: String) async {
        await withServices {
            AppsFlyerDeepLinkResolver().resolve(clickEvent: ["deep_link_sub3": uid])

            #expect(bindingService.registeredUids == [uid])
        }
    }

    @Test(
        "A click event without a uid in deep_link_sub3 registers nothing",
        arguments: [
            [:],
            ["deep_link_value": "referral", "deep_link_sub3": ""],
            ["deep_link_value": "referral", "uid": "AbC-123"],
        ] as [[String: String]]
    )
    func ignoresClickEventWithoutUid(clickEvent: [String: String]) async {
        await withServices {
            AppsFlyerDeepLinkResolver().resolve(clickEvent: clickEvent)

            #expect(bindingService.registeredUids.isEmpty)
        }
    }

    @Test(
        "A OneLink opened in the app registers its uid once, though both the app and AppsFlyer read the link",
        arguments: [OneLink.direct, OneLink.brandedDirect, OneLink.directWithoutSub3]
    )
    func openingRegistersOnce(link: URL) async {
        await withServices {
            let manager = CommonIncomingActionManager()

            manager.handleIncomingURL(link)
            AppsFlyerDeepLinkResolver().resolve(clickEvent: clickEvent(of: link))

            #expect(bindingService.registeredUids == [OneLink.uid])
        }
    }
}

// MARK: - Helpers

private extension AppsFlyerMarketingActivityHandlerTests {
    enum OneLink {
        static let uid = "AbC-123"
        static let direct = URL(string: "https://tangem.onelink.me/AbCd?deep_link_value=tpay_mobileonboard&deep_link_sub3=AbC-123&uid=AbC-123")!
        static let brandedDirect = URL(string: "https://join.tangem.com/AbCd?deep_link_value=tpay_for_some-campaign&deep_link_sub3=AbC-123&uid=AbC-123")!
        static let directWithoutSub3 = URL(string: "https://tangem.onelink.me/AbCd?deep_link_value=tpay_mobileonboard&uid=AbC-123")!
    }

    func clickEvent(of link: URL) -> [String: String] {
        let queryItems = URLComponents(url: link, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(queryItems.map { ($0.name, $0.value ?? "") }) { first, _ in first }
    }

    func withServices(_ body: () async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousRepository = InjectedValues[\.userWalletRepository]
            let previousBindingService = InjectedValues[\.marketingActivityBindingService]
            let previousCampaignKeyStorage = InjectedValues[\.tangemPayCampaignKeyStorage]
            let previousOnboarding = AppSettings.shared.needsTangemPayMobileOnboarding

            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository(models: [])
            InjectedValues[\.marketingActivityBindingService] = bindingService
            InjectedValues[\.tangemPayCampaignKeyStorage] = TangemPayCampaignKeyStorageStub()

            defer {
                InjectedValues[\.userWalletRepository] = previousRepository
                InjectedValues[\.marketingActivityBindingService] = previousBindingService
                InjectedValues[\.tangemPayCampaignKeyStorage] = previousCampaignKeyStorage
                AppSettings.shared.needsTangemPayMobileOnboarding = previousOnboarding
            }

            await body()
        }
    }
}
