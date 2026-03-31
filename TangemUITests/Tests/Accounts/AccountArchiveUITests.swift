//
//  AccountArchiveUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class AccountArchiveUITests: BaseTestCase {
    private let walletName = "Wallet"
    private let scenarioName = "user_tokens_api"
    private let mainAccountName = "Main account"
    private let account2Name = "Account 2"
    private let account3Name = "Account 3"

    func testArchiveAccount() {
        setAllureId(5974)
        let scenario = ScenarioConfig(name: scenarioName, initialState: "TwoAccountsArchivable")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        navigateToWalletSettings()
            .selectAccount(account2Name)
            .verifyArchiveButtonVisible()
            .tapArchiveButton()
            .verifyArchiveDialogVisible()
            .confirmArchiveDialog()
            .verifyAccountNotExists(account2Name)
    }

    func testRestoreArchivedAccount() {
        setAllureId(5976)
        let scenario = ScenarioConfig(name: scenarioName, initialState: "TwoAccountsWithArchivedAccounts")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        let walletSettings = navigateToWalletSettings()

        wireMockClient.setScenarioStateSync(scenarioName, state: "TwoAccountsWithArchivedAccounts")

        let archivedScreen = walletSettings
            .openArchivedAccounts()
            .verifyArchivedAccountExists(account3Name)

        wireMockClient.setScenarioStateSync(scenarioName, state: "ReadyToRestore")

        archivedScreen
            .tapRecoverButton(for: account3Name)
            .verifyAccountExists(account3Name)
            .verifyArchivedAccountsButtonNotExists()
    }

    func testMainAccountArchiveButtonNotVisible() {
        setAllureId(5979)
        launchApp(tangemApiType: .mock)

        navigateToWalletSettings()
            .selectAccount(mainAccountName)
            .verifyArchiveButtonNotVisible()
    }

    func testArchiveReferralAccount() {
        setAllureId(5981)
        let scenarios = [
            ScenarioConfig(name: scenarioName, initialState: "TwoAccountsArchivable"),
            ScenarioConfig(name: "referral_api", initialState: "Participating"),
        ]
        launchApp(tangemApiType: .mock, scenarios: scenarios)

        navigateToWalletSettings()
            .selectAccount(account2Name)
            .verifyArchiveButtonVisible()
            .tapArchiveButton()
            .verifyArchiveDialogVisible()
            .confirmArchiveDialogExpectingError()
            .verifyErrorAlert(expectedMessage: "referral program")
            .dismissErrorAlert(buttonTitle: "Got it")
            .verifyArchiveButtonVisible()
    }

    func testArchiveAccountError() {
        setAllureId(6844)
        let scenario = ScenarioConfig(name: scenarioName, initialState: "TwoAccountsArchivable")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        let accountSettings = navigateToWalletSettings()
            .selectAccount(account2Name)
            .verifyArchiveButtonVisible()
            .tapArchiveButton()
            .verifyArchiveDialogVisible()

        wireMockClient.setScenarioStateSync(scenarioName, state: "AccountsPutError")

        accountSettings
            .confirmArchiveDialogExpectingError()
            .verifyErrorAlert(expectedMessage: "try again")
            .dismissErrorAlert()
    }

    func testRestoreArchivedAccountWithCustomTokenTransfer() {
        setAllureId(5980)
        let scenario = ScenarioConfig(name: scenarioName, initialState: "OneAccountWithArchivedCustomToken")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        let walletSettings = navigateToWalletSettings()

        let archivedScreen = walletSettings
            .openArchivedAccounts()
            .verifyArchivedAccountExists(account2Name)
            .verifyArchivedAccountTokenInfo(account2Name, expectedInfo: "1 token")

        wireMockClient.setScenarioStateSync(scenarioName, state: "ReadyToRestoreCustomToken")

        archivedScreen
            .tapRecoverButton(for: account2Name)
            .verifyMigrationDialogVisible()
            .verifyMigrationDialogContains(text: mainAccountName)
            .verifyMigrationDialogContains(text: account2Name)
            .confirmMigrationDialog()
            .verifyAccountExists(account2Name)
            .goBackToDetails()
            .goBackToMain()
            .verifyAccountVisible(mainAccountName)
            .verifyAccountVisible(account2Name)
            .expandAccount(mainAccountName)
            .verifyTokenNotVisible("Polygon")
            .expandAccount(account2Name)
            .verifyTokenVisible("Polygon")
    }

    func testRestoreArchivedAccountError() {
        setAllureId(7962)
        let scenario = ScenarioConfig(name: scenarioName, initialState: "TwoAccountsWithArchivedAccounts")
        launchApp(tangemApiType: .mock, scenarios: [scenario])

        let walletSettings = navigateToWalletSettings()

        wireMockClient.setScenarioStateSync(scenarioName, state: "TwoAccountsWithArchivedAccounts")

        let archivedScreen = walletSettings
            .openArchivedAccounts()
            .verifyArchivedAccountExists(account3Name)

        wireMockClient.setScenarioStateSync(scenarioName, state: "AccountsPutError")

        archivedScreen
            .tapRecoverButtonExpectingError(for: account3Name)
            .verifyErrorAlert(expectedMessage: "try again")
            .dismissErrorAlert()
    }

    private func navigateToWalletSettings() -> CardSettingsScreen {
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: walletName)
    }
}
