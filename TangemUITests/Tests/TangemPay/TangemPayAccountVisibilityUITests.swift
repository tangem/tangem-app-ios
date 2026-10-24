//
//  TangemPayAccountVisibilityUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import XCTest

final class TangemPayAccountVisibilityUITests: BaseTestCase {
    private let firstAccountName = "Account 1"
    private let secondAccountName = "Account 2"
    private let qaToolsClient = QAToolsClient()

    func testPayAccountNotListedInWalletSettingsAccounts() {
        setAllureId(11470)

        launchWithPayAndTwoAccounts()
            .openDetails()
            .openWalletSettings()
            .verifyAccountExists(firstAccountName)
            .verifyAccountExists(secondAccountName)
            .verifyAccountNotExists(Localization.tangempayPaymentAccount)
    }

    func testPayAccountNotOfferedWhenAddingTokenViaAddAndManage() {
        setAllureId(11469)

        launchWithPayAndTwoAccounts()
            .openAddTokensAccountPicker()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountVisible(secondAccountName)
            .verifyAccountNotVisible(Localization.tangempayPaymentAccount)
    }

    func testPayAccountNotListedInAddFundsTokenSelector() {
        setAllureId(11475)

        // Only the main account is asserted: a token selector lists an account solely when it holds a suitable token.
        launchWithPayAndTwoAccounts()
            .tapMainBuy()
            .waitBuyTokenSelectorDisplayed()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountNotVisible(Localization.tangempayPaymentAccount)
    }

    func testPayAccountNotListedInTransfersTokenSelector() {
        setAllureId(11476)

        launchWithPayAndTwoAccounts()
            .tapMainSell()
            .waitSellTokenSelectorDisplayed()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountNotVisible(Localization.tangempayPaymentAccount)
    }

    func testPayAccountNotOfferedWhenAddingTokenViaMarkets() {
        setAllureId(11468)

        launchWithPayAndTwoAccounts()
            .openMarketsSheet()
            .searchForToken(Constants.marketsToken)
            .openTokenDetails(Constants.marketsToken)
            .tapAddToPortfolio()
            .openAccountSelector()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountVisible(secondAccountName)
            .verifyAccountNotVisible(Localization.tangempayPaymentAccount)
    }

    func testPayAccountNotOfferedAsReferralRewardsAddress() {
        setAllureId(11471)

        launchWithPayAndTwoAccounts()
            .openDetails()
            .openWalletSettings()
            .openReferralProgram()
            .openAccountSelector()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountVisible(secondAccountName)
            .verifyAccountNotVisible(Localization.tangempayPaymentAccount)
    }

    func testPayAccountNotOfferedWhenReceivingNFT() {
        setAllureId(11473)

        launchWithPayTwoAccountsAndNFT(nftState: Constants.emptyNFTState)
            .openNFT()
            .waitForDisplayed()
            .tapReceive()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountVisible(secondAccountName)
            .verifyAccountNotVisible(Localization.tangempayPaymentAccount)
    }

    func testPayAccountNotListedInNFTSendAccounts() {
        setAllureId(11474)

        // The source account's own address is filtered out of the suggestions, leaving the second account.
        launchWithPayTwoAccountsAndNFT(nftState: Constants.singleCollectionNFTState)
            .openNFT()
            .waitForDisplayed()
            .expandCollection(Constants.nftCollectionName)
            .openAsset(Constants.nftAssetName)
            .tapSend()
            .verifySuggestedAccountVisible(secondAccountName)
            .verifySuggestedAccountNotVisible(Localization.tangempayPaymentAccount)
    }

    func testPayAccountNotOfferedWhenConnectingDAppViaWalletConnect() {
        setAllureId(11472)

        let qrScanScreen = launchWithPayAndTwoAccounts()
            .openDetails()
            .openWalletConnections()
            .tapNewConnection()
            .waitForQRScannerScreenToBeVisible()

        // The pairing URI is fetched once the app is ready to consume it, so it cannot expire during wallet import.
        UIPasteboard.general.string = fetchPairingURI()

        qrScanScreen
            .tapPasteButton()
            .waitForConnectionProposalBottomSheetToBeVisible()
            .tapAccountRow()
            .verifyAccountVisible(firstAccountName)
            .verifyAccountVisible(secondAccountName)
            .verifyAccountNotVisible(Localization.tangempayPaymentAccount)
    }

    private func launchWithPayAndTwoAccounts() -> MainScreen {
        launchAndImportHotWallet(
            expressApiType: .mock,
            scenarios: Constants.scenarios
        )
        .generateMissingAddressesIfNeeded()
        .verifyTangemPayTileVisible()
    }

    private func launchWithPayTwoAccountsAndNFT(nftState: String) -> MainScreen {
        launchAndImportHotWallet(
            expressApiType: .mock,
            scenarios: Constants.scenarios + [ScenarioConfig(name: Constants.nftScenario, initialState: nftState)]
        )
        .generateMissingAddressesIfNeeded()
        .verifyTangemPayTileVisible()
        .openDetails()
        .openWalletSettings()
        .enableNFT()
        .goBackToDetails()
        .goBackToMain()
    }

    private func fetchPairingURI() -> String {
        let deeplink = qaToolsClient.getWCURISync(network: .ethereum, uriScheme: .tangem)
        XCTAssert(!deeplink.isEmpty, "WC URI from qa-tools must not be empty")
        // The Paste button consumes the bare wc: URI, not the deeplink wrapping it.
        return deeplink.replacingOccurrences(of: "\(WCURIScheme.tangem.rawValue)?uri=", with: "")
    }
}

private extension TangemPayAccountVisibilityUITests {
    enum Constants {
        /// Not held by either account, so Markets offers to add it.
        static let marketsToken = "Bitcoin"

        static let nftScenario = "moralis_evm_nft_api"
        static let emptyNFTState = "Started"

        /// The fixture collection has GIF media, which keeps its row out of a drawing group that would hide the asset cells.
        static let singleCollectionNFTState = "SingleCollection"
        static let nftCollectionName = "Tangem Test Collection"
        static let nftAssetName = "Tangem Test NFT #1"

        /// Two tokens per account: Add & Manage only appears once an account holds at least two.
        static let scenarios: [ScenarioConfig] = [
            ScenarioConfig(name: "user_tokens_api", initialState: "TwoAccountsSameUsdt"),
            ScenarioConfig(name: "eth_call_api", initialState: "Started"),
            ScenarioConfig(name: "eth_network_balance", initialState: "Started"),
        ]
    }
}
