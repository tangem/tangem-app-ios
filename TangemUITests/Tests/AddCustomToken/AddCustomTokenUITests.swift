//
//  AddCustomTokenUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class AddCustomTokenUITests: BaseTestCase {
    private let ethContract = "0xdac17f958d2ee523a2206206994597c13d831ec7"
    private let solanaContract = "EPjFWdd5AufqSSqeM2qN1xzybapC8G4wEGGkZwyTDt1v"

    func testAddCustomToken_TokenAddedToMain() {
        setAllureId(772)
        launchApp(tangemApiType: .mock, scenarios: [coinsScenario])

        openAddCustomToken()
            .selectNetwork("Ethereum")
            .enterContractAddress(ethContract)
            .tapAddToken()

        ManageTokensScreen(app)
            .goBackToAccountSettings()
            .goBackToWalletSettings()
            .goBackToDetails()
            .goBackToMain()
            .verifyTokenExists("Tether")
    }

    func testAddCustomToken_CustomDerivationPathAccepted() {
        setAllureId(775)
        launchApp(tangemApiType: .mock, scenarios: [coinsScenario])

        openAddCustomToken()
            .selectNetwork("Ethereum")
            .enterContractAddress(ethContract)
            .openDerivationSelector()
            .chooseCustomDerivation()
            .enterCustomDerivationPath("m/44'/60'/0'/0/1")
            .tapAddToken()

        ManageTokensScreen(app)
            .goBackToAccountSettings()
            .goBackToWalletSettings()
            .goBackToDetails()
            .goBackToMain()
            .verifyTokenExists("Tether")
    }

    func testAddCustomToken_DerivationAvailableForNonEVMNetwork() {
        setAllureId(770)
        launchApp(tangemApiType: .mock, scenarios: [coinsScenario])

        openAddCustomToken()
            .selectNetwork("Solana")
            .verifyDerivationFieldEnabled()
    }

    func testAddCustomToken_CustomDerivationIndicatorShownOnMain() {
        setAllureId(771)
        launchApp(tangemApiType: .mock, scenarios: [coinsScenario])

        openAddCustomToken()
            .selectNetwork("Ethereum")
            .enterContractAddress(ethContract)
            .openDerivationSelector()
            .chooseCustomDerivation()
            .enterCustomDerivationPath("m/44'/60'/0'/0/1")
            .tapAddToken()

        ManageTokensScreen(app)
            .goBackToAccountSettings()
            .goBackToWalletSettings()
            .goBackToDetails()
            .goBackToMain()
            .verifyCustomTokenIndicatorExists(for: "Tether")
    }

    func testAddCustomToken_SolanaToken_ModernCard_NoWarning() {
        setAllureId(769)
        launchApp(tangemApiType: .mock, scenarios: [coinsScenario])

        openAddCustomToken()
            .selectNetwork("Solana")
            .enterContractAddress(solanaContract)
            .verifyNoUnsupportedTokenWarning()
    }

    private var coinsScenario: ScenarioConfig {
        ScenarioConfig(name: "coins_api", initialState: "ManageTokensRich")
    }

    private func openAddCustomToken() -> AddCustomTokenScreen {
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .selectAccount("Main account")
            .openManageTokens()
            .openAddCustomToken()
    }
}
