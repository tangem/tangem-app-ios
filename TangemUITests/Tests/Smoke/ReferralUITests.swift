//
//  ReferralUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class ReferralUITests: BaseTestCase {
    func testReferralProgramFlow_DisplayConditionsAndParticipateButton() {
        id(3647)
        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings()
            .openReferralProgram()
            .validate()
    }
}
