//
//  ManageTokensUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

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

    private func openManageTokens() -> ManageTokensScreen {
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: "Wallet")
            .selectAccount("Main account")
            .openManageTokens()
    }
}
