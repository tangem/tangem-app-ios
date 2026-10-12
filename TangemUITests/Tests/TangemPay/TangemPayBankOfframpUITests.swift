//
//  TangemPayBankOfframpUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayBankOfframpUITests: BaseTestCase {
    func testWithdrawOpensHub_OnlyWhenChannelsIncludeBankOfframp() {
        setAllureId(12172)

        openPaymentAccount()
            .tapWithdrawOpeningHub()
            .close()
            .tapBack()

        wireMockClient.setScenarioStateSync(Constants.Scenario.eligibilityChannels, state: Constants.State.withoutBankOfframp)
        let channelsRequestsBefore = requestCount(Constants.Endpoint.eligibilityChannels)

        MainScreen(app)
            .openTangemPay()
            .waitForScreen()
            .tapWithdraw()
            .validateSwapScreenDisplayed()

        verifyRequestedAgain(
            Constants.Endpoint.eligibilityChannels,
            since: channelsRequestsBefore,
            "Eligibility channels should be requested again after reopening the payment account"
        )
        TangemPayWithdrawHubScreen(app).verifyNotDisplayed()
    }

    func testWithdrawHub_ShowsZeroStateInBothSections() {
        setAllureId(12173)

        openPaymentAccount()
            .tapWithdrawOpeningHub()
            .verifyRecentsZeroStateInBothSections()
    }

    func testWithdrawHub_BankAccountsError_TapReloadsList() {
        setAllureId(12174)

        let hub = openPaymentAccount(bankAccountsState: Constants.State.error)
            .tapWithdrawOpeningHub()
            .verifyRecentAccountsLoadError()

        let bankAccountsRequestsBefore = requestCount(Constants.Endpoint.bankAccounts)
        hub.tapRecentAccountsRetry()

        verifyRequestedAgain(
            Constants.Endpoint.bankAccounts,
            since: bankAccountsRequestsBefore,
            "Tapping the error tile should request the bank accounts again"
        )
        hub.verifyRecentAccountsLoadError()
    }

    func testBankTransferBlock_UnavailableWhenOptionsFailOrEmpty() {
        setAllureId(12175)

        openPaymentAccount(offrampOptionsState: Constants.State.error)
            .tapWithdrawOpeningHub()
            .verifyBankTransferUnavailable()
            .close()

        wireMockClient.setScenarioStateSync(Constants.Scenario.offrampOptions, state: Constants.State.empty)

        verifyOfframpOptionsRequested {
            TangemPayMainScreen(app).tapWithdrawOpeningHub()
        }

        TangemPayWithdrawHubScreen(app)
            .verifyBankTransferUnavailable()
    }

    func testWithdrawHub_ShowsRecentBankRecipients() {
        setAllureId(12177)

        openPaymentAccount(bankAccountsState: Constants.State.twoAccounts)
            .tapWithdrawOpeningHub()
            .verifyRecentRecipientCount(2)
            .verifyRecentRecipient(.john)
            .verifyRecentRecipient(.acme)
            .verifySeeAllNotDisplayed()
            .close()

        wireMockClient.setScenarioStateSync(Constants.Scenario.bankAccounts, state: Constants.State.fiveAccounts)

        TangemPayMainScreen(app)
            .tapWithdrawOpeningHub()
            .verifyRecentRecipientCount(3)
            .verifyRecentRecipient(.john)
            .verifyRecentRecipient(.acme)
            .verifyRecentRecipient(.alice)
            .verifyRecentRecipientNotDisplayed(.bob)
            .verifySeeAllDisplayed()
            .tapSeeAll()
            .verifyOnlyRecipients(TangemPayBankRecipient.fiveSavedAccounts)
    }

    func testRecipientAndToken_AddedToRecents_AfterSuccessfulTransfers() {
        setAllureId(12178)

        let signaturesBefore = signatureRequestCount()

        openPaymentAccount(extraScenarios: Constants.swapScenarios)
            .tapWithdrawOpeningHub()
            .verifyBankRecentsZeroState()
            .tapToPersonalAccount()
            .enterAmount(Constants.transferAmount)
            .tapContinueToTransferType()
            .selectTransferType(.thirdPartyAccount)
            .selectAccountType(.checking)
            .fillRecipientDetails(Constants.janeDetails)
            .fillBankDetails(Constants.chaseBankDetails)
            .tapSend()
            .waitForScreen(amount: Constants.sentAmount)
            .tapClose()

        XCTContext.runActivity(named: "Verify the bank transfer signature was submitted once") { _ in
            XCTAssertEqual(
                signatureRequestCount() - signaturesBefore,
                1,
                "The signed bank transfer should be submitted exactly once"
            )
        }

        wireMockClient.setScenarioStateSync(Constants.Scenario.bankAccounts, state: Constants.State.afterTransfer)

        let withdrawDataBefore = withdrawDataRequestCount()

        TangemPayMainScreen(app)
            .tapWithdrawOpeningHub()
            .verifyRecentRecipient(.jane)
            .tapWithinPortfolio()
            .chooseTokenFromEmptySelector(Constants.bitcoinName)
            .enterFromAmount(Constants.transferAmount)
            .holdConfirmUntilSubmitted {
                withdrawDataRequestCount() == withdrawDataBefore
            }
            .tapCloseButton()

        TangemPayMainScreen(app)
            .waitForScreen()
            .tapWithdrawOpeningHub()
            .verifyRecentToken(Constants.bitcoinName)
    }

    func testBankRecipients_SearchByNameAndAccountNumber() {
        setAllureId(12180)

        openPaymentAccount(bankAccountsState: Constants.State.fiveAccounts)
            .tapWithdrawOpeningHub()
            .tapSeeAll()
            .verifyOnlyRecipients(TangemPayBankRecipient.fiveSavedAccounts)
            .search(Constants.Search.namePrefix)
            .verifyOnlyRecipients([.alice])
            .search(Constants.Search.accountNumberPart)
            .verifyOnlyRecipients([.alice, .bob, .carol])
            .search(Constants.Search.unknown)
            .verifyNothingFound()
    }

    func testBankRecipientFromFullList_OpensAmountPrefilled() {
        setAllureId(12181)

        openPaymentAccount(bankAccountsState: Constants.State.fiveAccounts)
            .tapWithdrawOpeningHub()
            .tapSeeAll()
            .tapRecipient(.alice)
            .verifyTitle(TangemPayBankRecipient.alice.fullName)
            .enterAmount(Constants.transferAmount)
            .tapContinueToConfirmation()
            .verifyRecipientDetails(Constants.aliceSavedDetails)
    }

    func testBankTransferSourceTokens_ShowOnlyPositiveBalances() {
        setAllureId(12182)

        let paymentAccount = openPaymentAccount(balanceState: Constants.State.multiNetworkStatuses)
        verifyOfframpOptionsRequested {
            paymentAccount.tapWithdrawOpeningHub()
        }

        TangemPayWithdrawHubScreen(app)
            .tapToPersonalAccount()
            .verifySourceToken(symbol: Constants.usdcSymbol, network: TangemPayNetwork.polygon.displayName)
            .tapSourceToken()
            .verifyAvailableToken(symbol: Constants.usdcSymbol, network: .polygon, balance: Constants.polygonBalance, isSelected: true)
            .verifyUnavailableToken(symbol: Constants.usdtSymbol, network: .bsc)
            .verifyTokenCount(2)
            .close()
            .close()

        wireMockClient.setScenarioStateSync(Constants.Scenario.balance, state: Constants.State.arbitrumTopUp)
        pullToRefresh()
        paymentAccount.verifyBalanceContains(Constants.toppedUpBalance)

        verifyOfframpOptionsRequested {
            paymentAccount.tapWithdrawOpeningHub()
        }

        TangemPayWithdrawHubScreen(app)
            .tapToBusinessAccount()
            .verifySourceToken(symbol: Constants.usdcSymbol, network: TangemPayNetwork.polygon.displayName)
            .tapSourceToken()
            .verifyAvailableToken(symbol: Constants.usdcSymbol, network: .polygon, balance: Constants.polygonBalance, isSelected: true)
            .verifyAvailableToken(symbol: Constants.usdcSymbol, network: .arbitrum, balance: Constants.arbitrumBalance, isSelected: false)
            .verifyUnavailableToken(symbol: Constants.usdtSymbol, network: .bsc)
            .verifyTokenCount(3)
    }

    private func openPaymentAccount(
        balanceState: String = Constants.State.initialBalance,
        bankAccountsState: String = Constants.State.started,
        offrampOptionsState: String = Constants.State.started,
        extraScenarios: [ScenarioConfig] = []
    ) -> TangemPayMainScreen {
        launchAndImportHotWalletWithRealPayAuthorization(expressApiType: .mock, scenarios: [
            ScenarioConfig(name: Constants.Scenario.eligibilityChannels, initialState: Constants.State.bankOfframp),
            ScenarioConfig(name: Constants.Scenario.balance, initialState: balanceState),
            ScenarioConfig(name: Constants.Scenario.history, initialState: Constants.State.emptyHistory),
            ScenarioConfig(name: Constants.Scenario.bankAccounts, initialState: bankAccountsState),
            ScenarioConfig(name: Constants.Scenario.offrampOptions, initialState: offrampOptionsState),
        ] + extraScenarios)
            .openTangemPay()
            .waitForScreen()
            .waitForBalanceLoaded()
    }

    private func verifyOfframpOptionsRequested(by action: () -> Void) {
        let optionsRequestsBefore = requestCount(Constants.Endpoint.offrampOptions)
        action()
        verifyRequestedAgain(
            Constants.Endpoint.offrampOptions,
            since: optionsRequestsBefore,
            "Opening the Withdraw hub should request the bank off-ramp options"
        )
    }

    private func verifyRequestedAgain(_ urlPathPattern: String, since previousCount: Int, _ message: String) {
        XCTContext.runActivity(named: "Verify \(urlPathPattern) was requested again") { _ in
            let requestedAgain = NSPredicate { _, _ in
                self.requestCount(urlPathPattern) > previousCount
            }
            let expectation = XCTNSPredicateExpectation(predicate: requestedAgain, object: nil)
            XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: .conditional), .completed, message)
        }
    }

    private func withdrawDataRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.withdrawData)
    }

    private func signatureRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.offrampSignature)
    }

    private func requestCount(_ urlPathPattern: String) -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPathPattern: urlPathPattern)
    }
}

private extension TangemPayBankOfframpUITests {
    enum Constants {
        static let transferAmount = "5"
        static let sentAmount = "$5"
        static let bitcoinName = "Bitcoin"
        static let usdcSymbol = "USDC"
        static let usdtSymbol = "USDT"
        static let polygonBalance = "$10.00"
        static let arbitrumBalance = "$5.00"
        static let toppedUpBalance = "$22.00"

        static let swapScenarios = [
            ScenarioConfig(name: "bitcoin_utxo", initialState: "Started"),
            ScenarioConfig(name: "express_api_assets", initialState: "BitcoinExchangeEnabled"),
            ScenarioConfig(name: "exchange_status_provider", initialState: "Changelly"),
        ]

        static let janeDetails = TangemPayBankTransferWizardScreen.RecipientDetails(
            accountNumber: TangemPayBankRecipient.jane.accountNumber,
            routingNumber: "021000021",
            firstName: "Jane",
            lastName: "Roe",
            country: "United States",
            region: "California",
            city: "Los Angeles",
            addressLine1: "1 Main Street",
            postalCode: "90001"
        )

        static let chaseBankDetails = TangemPayBankTransferWizardScreen.BankDetails(
            name: "Chase Bank",
            region: "New York",
            city: "New York",
            addressLine1: "270 Park Avenue",
            postalCode: "10017"
        )

        static let aliceSavedDetails = [TangemPayBankRecipient.alice.accountNumber, "021000021", "Alice", "Smith", "Chase Bank"]

        enum Scenario {
            static let eligibilityChannels = "tangem_pay_eligibility_channels"
            static let balance = "tangem_pay_balance_update"
            static let history = "tangem_pay_transaction_history"
            static let bankAccounts = "tangem_pay_bank_accounts"
            static let offrampOptions = "tangem_pay_bank_offramp_options"
        }

        enum State {
            static let started = "Started"
            static let bankOfframp = "BankOfframp"
            static let withoutBankOfframp = "BannerAndDetails"
            static let initialBalance = "InitialBalanceMultinetwork"
            static let multiNetworkStatuses = "MultiNetworkStatuses"
            static let arbitrumTopUp = "MultiNetworkArbitrumTopUp"
            static let emptyHistory = "InitialEmpty"
            static let twoAccounts = "TwoAccounts"
            static let fiveAccounts = "FiveAccounts"
            static let afterTransfer = "AfterTransfer"
            static let error = "Error"
            static let empty = "Empty"
        }

        enum Endpoint {
            static let eligibilityChannels = "/bff-v2/v1/eligibility/channels"
            static let bankAccounts = "/bff-v2/v1/account/bank-accounts"
            static let offrampOptions = "/bff-v2/v1/account/bank-offramp/options"
            static let offrampSignature = "/bff-v2/v1/order/.*/bank-offramp/signature"
            static let withdrawData = "/bff-v2/v1/customer/card/withdraw/data"
        }

        enum Search {
            static let namePrefix = "Ali"
            static let accountNumberPart = "0000"
            static let unknown = "zzqx"
        }
    }
}
