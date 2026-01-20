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
    private let seed12 = "they cram join fantasy unfair observe true theory buffalo bus exchange walk"
    private let seed15 = "genuine try deer upset connect sausage diary rule price shallow fit faculty leopard hawk when"
    private let seed18 = "crush idle include refuse expose kiss slot budget uphold when dinner certain holiday slow word armor butter suffer"
    private let seed21 = "employ space oval venue wash clog zebra cover icon wash assist word debris inform cable meadow add game meat rigid pride"
    private let seed24 = "force visit fresh brown razor target ill scissors figure cave feel genre cargo category bread much nature basic fun iron benefit egg error prosper"

    func testAutomaticAddressDerivationForHotWalletSeed12() {
        setAllureId(1792)
        testAddressDerivation(seedPhrase: seed12, id: "twelve")
    }

    func testAutomaticAddressDerivationForHotWalletSeed15() {
        setAllureId(5106)
        testAddressDerivation(seedPhrase: seed15, id: "fifteen")
    }

    func testAutomaticAddressDerivationForHotWalletSeed18() {
        setAllureId(5107)
        testAddressDerivation(seedPhrase: seed18, id: "eighteen")
    }

    func testAutomaticAddressDerivationForHotWalletSeed21() {
        setAllureId(5108)
        testAddressDerivation(seedPhrase: seed21, id: "twenty_one")
    }

    func testAutomaticAddressDerivationForHotWalletSeed24() {
        setAllureId(5109)
        testAddressDerivation(seedPhrase: seed24, id: "twenty_four")
    }

    private func testAddressDerivation(seedPhrase: String, id: String) {
        launchApp()

        let mainScreen = CreateWalletSelectorScreen(app)
            .skipStories()
            .startWithMobileWallet()
            .tapImportButton()
            .enterSeedPhrase(seedPhrase)
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
        let apiWallets = qaToolsClient.getAddressesSync(id: id)

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
