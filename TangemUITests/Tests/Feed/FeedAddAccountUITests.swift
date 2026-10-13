//
//  FeedAddAccountUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class FeedAddAccountUITests: BaseTestCase {
    func testFeed_availableAccountTypesWithSingleWallet() {
        setAllureId(11634)
        launchApp(tangemApiType: .mock, featureToggles: [Constants.jointAccountsToggle: true])

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheet()
            .openAddAccountTypeSelector()
            .verifyCryptoAccountOptionClickable()
            .verifyJointAccountOptionClickable()
    }

    func testFeed_walletChooserWithSeveralWallets() {
        setAllureId(11635)
        launchApp(
            tangemApiType: .mock,
            featureToggles: [Constants.jointAccountsToggle: true],
            scenarios: [ScenarioConfig(name: Constants.userTokensScenario, initialState: Constants.accountsReadyState)]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet)
            .addNewWallet(name: .wallet2)
            .openMarketsSheet()
            .openAddAccountWalletSelector()
            .verifyWalletOptionDisplayed(Constants.firstWalletName)
            .verifyWalletOptionDisplayed(Constants.secondWalletName)
    }

    func testFeed_createCryptoAccount() {
        setAllureId(11636)
        launchApp(
            tangemApiType: .mock,
            featureToggles: [Constants.jointAccountsToggle: true],
            scenarios: [ScenarioConfig(name: Constants.userTokensScenario, initialState: Constants.createCryptoAccountState)]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheet()
            .openAddAccountTypeSelector()
            .tapCryptoAccount()
            .typeName(Constants.cryptoAccountName)
            .tapMainButton()

        ManageTokensScreen(app)
            .verifyScreenIsDisplayed()
            .goBackToMain()
            .verifyAccountVisible(Constants.cryptoAccountName)
    }

    func testFeed_addAccountBannerHiddenForSingleCurrencyWallet() {
        setAllureId(11638)
        launchApp(tangemApiType: .mock, featureToggles: [Constants.jointAccountsToggle: true])

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .xrpNote)
            .openMarketsSheet()
            .verifyMarketsSheetIsDisplayed()
            .verifyAddAccountBannerNotDisplayed()
    }

    func testFeed_addAccountBannerWithMultiAndSingleCurrencyWallets() {
        setAllureId(11658)
        launchApp(tangemApiType: .mock, featureToggles: [Constants.jointAccountsToggle: true])

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .addNewSingleCurrencyWallet(name: .xrpNote, walletName: Constants.noteWalletName)
            .openMarketsSheet()
            .openAddAccountTypeSelector()
            .verifyCryptoAccountOptionClickable()
            .verifyJointAccountOptionClickable()
    }

    func testFeed_cryptoAccountLimitReachedPopup() {
        setAllureId(11659)
        launchApp(
            tangemApiType: .mock,
            featureToggles: [Constants.jointAccountsToggle: true],
            scenarios: [ScenarioConfig(name: Constants.userTokensScenario, initialState: Constants.cryptoAccountLimitReachedState)]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheet()
            .openAddAccountTypeSelector()
            .tapCryptoAccountExpectingAccountLimit()
            .verifyDisplayed()
    }

    func testFeed_jointAccountLimitReachedPopup() {
        setAllureId(11660)
        launchApp(
            tangemApiType: .mock,
            featureToggles: [Constants.jointAccountsToggle: true],
            scenarios: [ScenarioConfig(name: Constants.userTokensScenario, initialState: Constants.jointAccountLimitReachedState)]
        )

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheet()
            .openAddAccountTypeSelector()
            .tapJointAccountExpectingAccountLimit()
            .verifyDisplayed()
    }
}

private extension FeedAddAccountUITests {
    enum Constants {
        static let jointAccountsToggle = "TWI-1611_joint_accounts"
        static let firstWalletName = "Wallet"
        static let secondWalletName = "Wallet 2"
        static let noteWalletName = "Note"
        static let userTokensScenario = "user_tokens_api"
        static let accountsReadyState = "JointAccountReadyToCreate"
        static let createCryptoAccountState = "AccountReadyToCreateEmpty"
        static let cryptoAccountLimitReachedState = "CryptoAccountLimitReached"
        static let jointAccountLimitReachedState = "JointAccountLimitReachedIOS"
        static let cryptoAccountName = "Account 2"
    }
}
