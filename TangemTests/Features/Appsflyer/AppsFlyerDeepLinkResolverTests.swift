//
//  AppsFlyerDeepLinkResolverTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

/// What the resolver does with a click event before anything on screen knows about it: the referral it carries
/// is written down whatever the link asks for, and the link still gets what it asked for.
@Suite("AppsFlyerDeepLinkResolver")
@MainActor
struct AppsFlyerDeepLinkResolverTests {
    @Test(
        "The referral a link carries is stored whatever the link names",
        arguments: ["referral", "tpay_mobileonboard", "some_future_scenario", ""]
    )
    func storesReferralForAnyDeepLinkValue(deepLinkValue: String) async {
        await withServices { referralService, _ in
            AppsFlyerDeepLinkResolver().resolve(clickEvent: [
                "deep_link_value": deepLinkValue,
                "deep_link_sub1": "REF1",
                "deep_link_sub2": "CAMP1",
            ])

            #expect(referralService.refcode == "REF1")
            #expect(referralService.campaign == "CAMP1")
        }
    }

    @Test("A link naming nothing at all is still worth its referral")
    func storesReferralWithoutDeepLinkValue() async {
        await withServices { referralService, _ in
            AppsFlyerDeepLinkResolver().resolve(clickEvent: ["deep_link_sub1": "REF1"])

            #expect(referralService.refcode == "REF1")
        }
    }

    @Test("A scenario link is still answered with its scenario")
    func scenarioIsStillResolved() async {
        await withServices { referralService, _ in
            AppsFlyerDeepLinkResolver().resolve(clickEvent: [
                "deep_link_value": "tpay_mobileonboard",
                "deep_link_sub1": "REF1",
            ])

            #expect(TangemPayMobileOnboardingService().isOnboardingNeeded)
            #expect(referralService.refcode == "REF1")
        }
    }

    /// The intro stories are skipped for the referral link alone — a scenario link carrying a refcode must not
    /// take the user through the referral flow.
    @Test(
        "Only the referral link asks for the mobile wallet promo",
        arguments: [("referral", true), ("tpay_mobileonboard", false)]
    )
    func promoBelongsToTheReferralLink(deepLinkValue: String, isPromoExpected: Bool) async {
        await withServices { _, promoService in
            AppsFlyerDeepLinkResolver().resolve(clickEvent: [
                "deep_link_value": deepLinkValue,
                "deep_link_sub1": "REF1",
            ])

            #expect(promoService.shouldShowMobilePromoWalletSelector == isPromoExpected)
        }
    }
}

// MARK: - Environment

private extension AppsFlyerDeepLinkResolverTests {
    func withServices(_ body: (ReferralServiceStub, MobileWalletPromoServiceStub) async -> Void) async {
        await InjectedDependenciesIsolation.shared.run {
            let previousReferralService = InjectedValues[\.referralService]
            let previousPromoService = InjectedValues[\.mobileWalletPromoService]
            let previousOnboarding = AppSettings.shared.needsTangemPayMobileOnboarding

            let referralService = ReferralServiceStub()
            let promoService = MobileWalletPromoServiceStub()

            InjectedValues[\.referralService] = referralService
            InjectedValues[\.mobileWalletPromoService] = promoService
            AppSettings.shared.needsTangemPayMobileOnboarding = false

            defer {
                InjectedValues[\.referralService] = previousReferralService
                InjectedValues[\.mobileWalletPromoService] = previousPromoService
                AppSettings.shared.needsTangemPayMobileOnboarding = previousOnboarding
            }

            await body(referralService, promoService)
        }
    }
}
