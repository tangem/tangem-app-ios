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

    @Test("No startup onboarding: no welcome onboarding, no deep link")
    func startup_none() {
        let state = State(startupOnboarding: nil)
        #expect(state.welcomeOnboarding == nil)
        #expect(state.deepLink == nil)
    }

    @Test("Welcome onboarding: steps captured, no deep link")
    func startup_welcome() {
        let state = State(startupOnboarding: .welcome(steps: [.tos]))
        #expect(state.welcomeOnboarding == [.tos])
        #expect(state.deepLink == nil)
    }

    @Test("Tangem Pay startup: Tangem Pay deep link, no welcome onboarding")
    func startup_tangemPay() {
        let state = State(startupOnboarding: .tangemPayMobile)
        #expect(state.welcomeOnboarding == nil)
        #expect(state.deepLink == .tangemPay)
    }
}
