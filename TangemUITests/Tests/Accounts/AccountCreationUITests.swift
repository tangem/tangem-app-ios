//
//  AccountCreationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//

import XCTest

final class AccountCreationUITests: BaseTestCase {
    private let walletName = "Wallet"

    func testAccountNameInputValidation() {
        setAllureId(5507)
        launchApp(tangemApiType: .mock)

        let accountForm = navigateToWalletSettings()
            .tapAddAccount()

        accountForm
            .verifyScreenIsDisplayed()
            .verifyMainButtonDisabled()

        accountForm
            .typeName("Test")
            .verifyMainButtonEnabled()

        accountForm
            .clearName()
            .verifyMainButtonDisabled()

        let maxLengthName = String(repeating: "A", count: 20)
        accountForm
            .clearNameAndType(maxLengthName)
            .verifyNameFieldValue(maxLengthName)
            .verifyMainButtonEnabled()

        let longName = String(repeating: "B", count: 25)
        accountForm
            .clearNameAndType(longName)
            .verifyNameFieldValue(String(repeating: "B", count: 20))

        let overLimitName = String(repeating: "C", count: 30)
        accountForm
            .clearNameAndType(overLimitName)
            .verifyNameFieldValue(String(repeating: "C", count: 20))
    }

    func testUnsavedChangesNotification() {
        setAllureId(5505)
        launchApp(tangemApiType: .mock)

        let accountForm = navigateToWalletSettings()
            .tapAddAccount()

        accountForm
            .verifyScreenIsDisplayed()
            .typeName("My Account")

        accountForm
            .tapCloseButton()
            .verifyUnsavedChangesAlert()

        accountForm
            .tapKeepEditing()
            .verifyScreenIsDisplayed()
            .verifyNameFieldValue("My Account")

        accountForm
            .tapCloseButton()
            .verifyUnsavedChangesAlert()

        accountForm
            .tapDiscard()
            .verifyAddAccountButtonEnabled()
    }

    func testNetworkErrorHandlingDuringAccountCreation() {
        setAllureId(5504)
        let scenario = ScenarioConfig(name: "user_tokens_api", initialState: "Started")
        launchApp(tangemApiType: .mock, clearStorage: true, scenarios: [scenario])

        let accountForm = navigateToWalletSettings()
            .tapAddAccount()

        accountForm
            .verifyScreenIsDisplayed()
            .typeName("New Account")

        wireMockClient.setScenarioStateSync("user_tokens_api", state: "AccountsGetError")

        accountForm
            .tapMainButton()
            .verifyErrorAlert(expectedMessage: "try again")
            .dismissErrorAlert()

        wireMockClient.setScenarioStateSync("user_tokens_api", state: "AccountsPutError")

        accountForm
            .tapMainButton()
            .verifyErrorAlert(expectedMessage: "try again")
            .dismissErrorAlert()

        wireMockClient.setScenarioStateSync("user_tokens_api", state: "AccountReadyToCreate")

        accountForm.tapMainButton()

        ManageTokensScreen(app)
            .goBackToWalletSettings()
            .verifyAddAccountButtonEnabled()
    }

    private func navigateToWalletSettings() -> CardSettingsScreen {
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .openWalletSettings(for: walletName)
    }
}
