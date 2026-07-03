//
//  AddCustomTokenUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

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

    func testAddCustomToken_MissingCurveCard_ShowsUnsupportedCurveWarning() {
        setAllureId(777)
        launchApp(tangemApiType: .mock, scenarios: [coinsScenario])

        openAddCustomToken(card: .wallet2NoEd25519Slip0010)
            .selectNetwork("Solana")
            .tapAddToken()
            .verifyUnsupportedCurveAlert(blockchain: "Solana")
    }

    func testDerivationPaths_MatchCardVersion() {
        setAllureId(776)

        XCTContext.runActivity(named: "Wallet 1.0 detached batch → v1") { _ in
            launchApp(tangemApiType: .mock, scenarios: [coinsScenario], mockCardBatchIdOverride: "AC01")
            openAddCustomToken(card: .wallet)
                .selectNetwork("Ethereum")
                .openDerivationSelector()
                .verifyDerivationOptionPath(option: "Bitcoin", expectedPath: "m/44'/0'/0'/0/0")
                .verifyDerivationOptionPath(option: "Ethereum Classic", expectedPath: "m/44'/61'/0'/0/0")
        }

        XCTContext.runActivity(named: "Wallet 1.0 → v2") { _ in
            launchApp(tangemApiType: .mock, scenarios: [coinsScenario])
            openAddCustomToken(card: .wallet)
                .selectNetwork("Ethereum")
                .openDerivationSelector()
                .verifyDerivationOptionPath(option: "Bitcoin", expectedPath: "m/44'/0'/0'/0/0")
                .verifyDerivationOptionPath(option: "Ethereum Classic", expectedPath: "m/44'/60'/0'/0/0")
        }

        XCTContext.runActivity(named: "Wallet 2.0 → v3") { _ in
            launchApp(tangemApiType: .mock, scenarios: [coinsScenario])
            openAddCustomToken(card: .wallet2)
                .selectNetwork("Ethereum")
                .openDerivationSelector()
                .verifyDerivationOptionPath(option: "Bitcoin", expectedPath: "m/84'/0'/0'/0/0")
                .verifyDerivationOptionPath(option: "Ethereum Classic", expectedPath: "m/44'/61'/0'/0/0")
        }
    }

    func testAddCustomToken_OldFirmwareCard_ShowsFirmwareLimitationWarning() {
        setAllureId(768)
        launchApp(tangemApiType: .mock, scenarios: [coinsScenario], mockCardFirmwareOverride: "4.51")

        openAddCustomToken(card: .wallet)
            .selectNetwork("Solana")
            .enterContractAddress(solanaContract)
            .tapAddToken()
            .verifyFirmwareLimitationAlert(blockchain: "Solana")
    }

    private var coinsScenario: ScenarioConfig {
        ScenarioConfig(name: "coins_api", initialState: "ManageTokensRich")
    }

    private func openAddCustomToken(card: CardMockAccessibilityIdentifiers = .wallet2) -> AddCustomTokenScreen {
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: card)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .selectAccount("Main account")
            .openManageTokens()
            .openAddCustomToken()
    }
}
