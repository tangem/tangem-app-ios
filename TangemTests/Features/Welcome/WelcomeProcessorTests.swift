//
//  WelcomeProcessorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

@Suite("WelcomeProcessor.State startup onboarding")
struct WelcomeProcessorTests {
    typealias State = WelcomeProcessor.State

    @Test("No startup onboarding: no deep link")
    func startup_none() {
        let state = State(startupOnboarding: nil)
        #expect(state.deepLink == nil)
    }

    @Test("Tangem Pay startup: Tangem Pay deep link")
    func startup_tangemPay() {
        let state = State(startupOnboarding: .tangemPayMobile)
        #expect(state.deepLink == .tangemPay)
    }

    @Test("Tangem Pay campaign startup: campaign deep link carrying the key")
    func startup_tangemPayCampaign() {
        let campaignKey = "tpay_for_harvard123"
        let state = State(startupOnboarding: .tangemPayCampaign(campaignKey: campaignKey))
        #expect(state.deepLink == .tangemPayCampaign(campaignKey: campaignKey))
    }
}
