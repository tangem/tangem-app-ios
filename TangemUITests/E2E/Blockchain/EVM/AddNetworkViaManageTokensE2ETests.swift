//
//  AddNetworkViaManageTokensE2ETests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class AddNetworkViaManageTokensE2ETests: E2EBaseTestCase {
    private let walletName = "Wallet"
    private let mainAccountName = "Main account"

    func testAddNetworkToMainViaManageTokens() {
        setAllureId(2076)

        let (main, network) = launchAndImportE2EWallet()

        main
            .openDetails()
            .openWalletSettings(for: walletName)
            .selectAccount(mainAccountName)
            .openManageTokens()
            .search(network.searchQuery)
            .verifyTokenRowExists(coinId: network.coinId)
            .expandTokenIfNeeded(coinId: network.coinId)
            .ensureNetworkEnabled(network.networkName)
            .tapSaveButton()
            .goBackToAccountSettings()
            .goBackToWalletSettings()
            .goBackToDetails()
            .goBackToMain()
            .revealToken(network.mainScreenToken)
            .verifyTokenVisible(network.mainScreenToken)
            .verifyTokenBalanceNonNegative(network.mainScreenToken)
    }
}
