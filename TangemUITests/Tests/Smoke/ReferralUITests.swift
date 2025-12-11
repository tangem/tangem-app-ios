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
        setAllureId(3647)
        let walletName = "Wallet"

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: walletName)
            .openReferralProgram()
            .validate()
    }
}
