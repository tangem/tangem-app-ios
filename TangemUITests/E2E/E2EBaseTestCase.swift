//
//  E2EBaseTestCase.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

class E2EBaseTestCase: BaseTestCase {
    private let resetWalletIdEnvironmentKey = "E2E_RESET_WALLET_ID"

    override func resetAllWireMockScenarios() {}

    func launchAndImportE2EWallet() -> (main: MainScreen, network: E2ENetwork) {
        let testData = E2EConfig.testData

        var launchEnvironment: [String: String] = [:]
        if !testData.walletId.isEmpty {
            launchEnvironment[resetWalletIdEnvironmentKey] = testData.walletId
        }

        launchApp(clearStorage: true, useWireMock: false, extraLaunchEnvironment: launchEnvironment)

        let main = CreateWalletSelectorScreen(app)
            .importMobileWallet()
            .enterSeedPhrase(testData.seedPhrase)
            .tapImportButton()
            .tapContinue()
            .skipAccessCode()
            .tapFinish()

        return (main, testData.network)
    }
}
