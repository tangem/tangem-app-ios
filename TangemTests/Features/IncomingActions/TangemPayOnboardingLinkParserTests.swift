//
//  TangemPayOnboardingLinkParserTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("Tangem Pay onboarding AppsFlyer link")
struct TangemPayOnboardingLinkParserTests {
    @Test(
        "The link asks for onboarding, from any domain of ours",
        arguments: [
            "https://tangem.onelink.me/abcd?deep_link_value=tpay_mobileonboard",
            "https://join.tangem.com/MsTz?af_xp=social&pid=marketing&c=tpay_mobileonboard&deep_link_value=tpay_mobileonboard&af_dp=tangem%3A%2F%2F",
            "https://app.tangem.com/abcd?deep_link_value=tpay_mobileonboard",
        ]
    )
    func appsFlyerLinkOpensOnboarding(link: String) {
        let url = URL(string: link)!

        #expect(TangemPayOnboardingLinkParser.matches(url))
        #expect(TangemPayOnboardingLinkParser().parse(url) == .navigation(.onboardVisa(OnboardVisaDeeplink(deeplinkString: nil))))
    }

    @Test(
        "The same value written into a link from anywhere else asks for nothing",
        arguments: [
            "https://evil.example.com/abcd?deep_link_value=tpay_mobileonboard",
            "tangem://tangem.onelink.me?deep_link_value=tpay_mobileonboard",
            "https://tangem.onelink.me/abcd?deep_link_value=something_else",
            "https://tangem.onelink.me/abcd",
        ]
    )
    func otherLinksAreNotIt(link: String) {
        let url = URL(string: link)!

        #expect(!TangemPayOnboardingLinkParser.matches(url))
        #expect(TangemPayOnboardingLinkParser().parse(url) == nil)
    }
}
