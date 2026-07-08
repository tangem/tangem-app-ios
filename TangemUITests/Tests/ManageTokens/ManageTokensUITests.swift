//
//  ManageTokensUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class ManageTokensUITests: BaseTestCase {
    func testNetworkStandardLabels_DisplayedForTokenNetworks() {
        setAllureId(765)
        let scenario = ScenarioConfig(name: "coins_api", initialState: "ManageTokensRich")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        openManageTokens()
            .expandTokenIfNeeded(coinId: "tether")
            .verifyNetworkStandard(network: "Ethereum", standard: "ERC20")
            .verifyNetworkStandard(network: "BNB Smart Chain", standard: "BEP20")
            .verifyNetworkStandard(network: "Tron", standard: "TRC20")
    }

    func testSearch_ByNameAndTicker_FiltersList() {
        setAllureId(667)
        let scenario = ScenarioConfig(name: "coins_api", initialState: "ManageTokensRich")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        openManageTokens()
            .search("Tether")
            .verifyTokenRowExists(coinId: "tether")
            .clearSearch()
            .search("USDT")
            .verifyTokenRowExists(coinId: "tether")
            .clearSearch()
            .search("Zzqnotoken")
            .verifyTokenRowNotExists(coinId: "tether")
    }

    func testSolanaToken_ModernCard_NoUnsupportedWarning() {
        setAllureId(763)
        let scenario = ScenarioConfig(name: "coins_api", initialState: "ManageTokensRich")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        openManageTokens()
            .expandTokenIfNeeded(coinId: "usd-coin")
            .toggleNetwork("Solana")
            .verifyNoAlertShown()
    }

    func testSolanaToken_MissingCurveCard_ShowsUnsupportedCurveWarning() {
        setAllureId(767)
        let scenario = ScenarioConfig(name: "coins_api", initialState: "ManageTokensRich")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        openManageTokens(card: .wallet2NoEd25519Slip0010)
            .expandTokenIfNeeded(coinId: "usd-coin")
            .toggleNetwork("Solana")
            .verifyUnsupportedCurveAlert(blockchain: "Solana")
    }

    func testSolanaToken_OldFirmwareCard_ShowsFirmwareLimitationWarning() {
        setAllureId(737)
        let scenario = ScenarioConfig(name: "coins_api", initialState: "ManageTokensRich")
        launchApp(tangemApiType: .mock, scenarios: [scenario], mockCardFirmwareOverride: "4.51")

        openManageTokens(card: .wallet)
            .expandTokenIfNeeded(coinId: "usd-coin")
            .toggleNetwork("Solana")
            .verifyFirmwareLimitationAlertAndDismiss(blockchain: "Solana")
            .verifyNetworkToggleOff("Solana")
    }

    func testLongPressNetwork_CopiesContractAddressWithToast() {
        setAllureId(719)
        let scenario = ScenarioConfig(name: "coins_api", initialState: "ManageTokensRich")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        let sentinel = "sentinel-not-copied"

        openManageTokens()
            .expandTokenIfNeeded(coinId: "bitcoin")
            .longPressNetworkToCopy("Bitcoin")
            .verifyNothingCopied()
            .expandTokenIfNeeded(coinId: "tether")
            .seedPasteboard(sentinel)
            .longPressNetworkToCopy("Ethereum")
            .verifyCopySuccessToast(text: "Contract address copied!")
            .verifyCopiedContract(equals: "0xdac17f958d2ee523a2206206994597c13d831ec7")
    }

    private func openManageTokens(card: CardMockAccessibilityIdentifiers = .wallet2) -> ManageTokensScreen {
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: card)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .selectAccount("Main account")
            .openManageTokens()
    }
}
