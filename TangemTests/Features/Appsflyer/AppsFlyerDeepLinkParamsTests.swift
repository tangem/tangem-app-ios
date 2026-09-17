//
//  AppsFlyerDeepLinkParamsTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("AppsFlyerDeepLinkParams parsing")
struct AppsFlyerDeepLinkParamsTests {
    @Test("Refcode is read from deep_link_sub1 for any deep_link_value", arguments: [
        "referral",
        "tpay_mobileonboard",
        "some_future_scenario",
        "",
    ])
    func refcodeIsValueAgnostic(deepLinkValue: String) {
        let params = AppsFlyerDeepLinkParams(clickEvent: [
            "deep_link_value": deepLinkValue,
            "deep_link_sub1": "REF1",
            "deep_link_sub2": "CAMP1",
        ])

        #expect(params.refcode == "REF1")
        #expect(params.campaign == "CAMP1")
    }

    @Test("Refcode is read when deep_link_value is missing")
    func refcodeWithoutDeepLinkValue() {
        let params = AppsFlyerDeepLinkParams(clickEvent: ["deep_link_sub1": "REF1"])

        #expect(params.value == nil)
        #expect(params.refcode == "REF1")
        #expect(params.campaign == nil)
        #expect(!params.isReferralDeepLink)
    }

    @Test("Blank and null-like sub parameters are discarded", arguments: ["", " ", "null"])
    func invalidSubParams(rawValue: String) {
        let params = AppsFlyerDeepLinkParams(clickEvent: [
            "deep_link_value": "referral",
            "deep_link_sub1": rawValue,
            "deep_link_sub2": rawValue,
        ])

        #expect(params.refcode == nil)
        #expect(params.campaign == nil)
    }

    @Test("Only the referral deep link value is treated as a referral one")
    func referralDetection() {
        let referral = AppsFlyerDeepLinkParams(clickEvent: ["deep_link_value": "referral"])
        let scenario = AppsFlyerDeepLinkParams(clickEvent: ["deep_link_value": "tpay_mobileonboard"])

        #expect(referral.isReferralDeepLink)
        #expect(!scenario.isReferralDeepLink)
    }

    @Test("Non-string values are ignored")
    func nonStringValues() {
        let params = AppsFlyerDeepLinkParams(clickEvent: ["deep_link_sub1": 42])

        #expect(params.refcode == nil)
    }
}
