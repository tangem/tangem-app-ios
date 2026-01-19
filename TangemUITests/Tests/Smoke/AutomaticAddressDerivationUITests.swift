//
//  AutomaticAddressDerivationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation

final class AutomaticAddressDerivationUITests: BaseTestCase {
    private let qaToolsClient = QAToolsClient()
    private let testSeedPhrase = "they cram join fantasy unfair observe true theory buffalo bus exchange walk"

    func testAutomaticAddressDerivationForHotWallet() {
        setAllureId(1792)

        launchApp()

        let mainScreen = CreateWalletSelectorScreen(app)
            .skipStories()
            .startWithMobileWallet()
            .tapImportButton()
            .enterSeedPhrase(testSeedPhrase)
            .tapImportButton()
            .tapContinue()
            .skipAccessCode()
            .tapFinish()

        let actualJSONString = mainScreen
            .openDetails()
            .openEnvironmentSetup()
            .openAddressesInfo()
            .copyJSON()

        // Get reference JSON from QA tools
        let apiWallets = qaToolsClient.getAddressesSync()

        // Parse actual JSON
        guard let uiJSONData = actualJSONString.data(using: .utf8) else {
            XCTFail("Failed to convert UI JSON string to data")
            return
        }

        let decoder = JSONDecoder()
        var currentWallets: [WalletInfoJSON]
        do {
            currentWallets = try decoder.decode([WalletInfoJSON].self, from: uiJSONData)
        } catch {
            XCTFail("Failed to parse UI JSON: \(error)")
            return
        }

        // Compare wallets with detailed error reporting
        let comparisonResult = WalletComparisonHelper.compare(uiWallets: currentWallets, apiWallets: apiWallets)

        if comparisonResult.hasDifferences {
            XCTFail(comparisonResult.errorMessage)
        }
    }
}
