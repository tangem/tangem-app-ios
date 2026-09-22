//
//  AppsFlyerDeepReferralHandlerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("AppsFlyerDeepReferralHandler")
struct AppsFlyerDeepReferralHandlerTests {
    @Test("Referral params are stored for any deep_link_value", arguments: [
        "referral",
        "tpay_mobileonboard",
        "some_future_scenario",
        "",
    ])
    func storesReferralParams(deepLinkValue: String) async {
        await withServices { referralService, _ in
            AppsFlyerDeepReferralHandler().handle(makeParams(value: deepLinkValue, refcode: "REF1", campaign: "CAMP1"))

            #expect(referralService.refcode == "REF1")
            #expect(referralService.campaign == "CAMP1")
        }
    }

    @Test("Referral params are stored when deep_link_value is missing")
    func storesReferralParamsWithoutDeepLinkValue() async {
        await withServices { referralService, _ in
            AppsFlyerDeepReferralHandler().handle(AppsFlyerDeepLinkParams(clickEvent: ["deep_link_sub1": "REF1"]))

            #expect(referralService.refcode == "REF1")
        }
    }

    @Test("The mobile wallet promo is set for the referral deep link")
    func promoIsSetForReferralDeepLink() async {
        await withServices { _, promoService in
            AppsFlyerDeepReferralHandler().handle(makeParams(value: "referral", refcode: "REF1"))

            #expect(promoService.shouldShowMobilePromoWalletSelector)
        }
    }

    @Test("The mobile wallet promo is not set for a scenario deep link")
    func promoIsNotSetForScenarioDeepLink() async {
        await withServices { _, promoService in
            AppsFlyerDeepReferralHandler().handle(makeParams(value: "tpay_mobileonboard", refcode: "REF1"))

            #expect(!promoService.shouldShowMobilePromoWalletSelector)
        }
    }

    @Test("Nothing is stored without a refcode", arguments: [nil, "", " ", "null"] as [String?])
    func doesNotStoreWithoutRefcode(rawRefcode: String?) async {
        await withServices { referralService, promoService in
            AppsFlyerDeepReferralHandler().handle(makeParams(value: "referral", refcode: rawRefcode))

            #expect(referralService.refcode == nil)
            #expect(referralService.saveCallsCount == 0)
            #expect(!promoService.shouldShowMobilePromoWalletSelector)
        }
    }

    @Test("An already stored refcode is not overwritten")
    func doesNotOverwriteStoredRefcode() async {
        await withServices(storedRefcode: "REF1", storedCampaign: "CAMP1") { referralService, promoService in
            AppsFlyerDeepReferralHandler().handle(makeParams(value: "referral", refcode: "REF2", campaign: "CAMP2"))

            #expect(referralService.refcode == "REF1")
            #expect(referralService.campaign == "CAMP1")
            #expect(referralService.saveCallsCount == 0)
            #expect(!promoService.shouldShowMobilePromoWalletSelector)
        }
    }
}

// MARK: - Environment

private extension AppsFlyerDeepReferralHandlerTests {
    /// The handler resolves its dependencies from `InjectedValues`, which is process-wide, so every test that
    /// swaps them takes the shared gate rather than only being serialized against its own suite.
    func withServices(
        storedRefcode: String? = nil,
        storedCampaign: String? = nil,
        _ body: (ReferralServiceStub, MobileWalletPromoServiceStub) async -> Void
    ) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousReferralService = InjectedValues[\.referralService]
            let previousPromoService = InjectedValues[\.mobileWalletPromoService]

            let referralService = ReferralServiceStub(refcode: storedRefcode, campaign: storedCampaign)
            let promoService = MobileWalletPromoServiceStub()

            InjectedValues[\.referralService] = referralService
            InjectedValues[\.mobileWalletPromoService] = promoService

            defer {
                InjectedValues[\.referralService] = previousReferralService
                InjectedValues[\.mobileWalletPromoService] = previousPromoService
            }

            await body(referralService, promoService)
        }
    }

    func makeParams(value: String?, refcode: String?, campaign: String? = nil) -> AppsFlyerDeepLinkParams {
        var clickEvent: [AnyHashable: Any] = [:]
        value.map { clickEvent["deep_link_value"] = $0 }
        refcode.map { clickEvent["deep_link_sub1"] = $0 }
        campaign.map { clickEvent["deep_link_sub2"] = $0 }

        return AppsFlyerDeepLinkParams(clickEvent: clickEvent)
    }
}
