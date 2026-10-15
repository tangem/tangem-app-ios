//
//  TangemPayBankOfframpUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayBankOfframpUITests: TangemPayBankOfframpUITestCase {
    func testWithdrawOpensHub_OnlyWhenChannelsIncludeBankOfframp() {
        setAllureId(12172)

        openPaymentAccount()
            .tapWithdrawOpeningHub()
            .close()
            .tapBack()

        switchEligibilityChannels(to: .withoutBankOfframp)
        let channelsRequestsBefore = requestCount(.eligibilityChannels)

        MainScreen(app)
            .openTangemPay()
            .waitForScreen()
            .tapWithdraw()
            .validateSwapScreenDisplayed()

        verifyRequestedAgain(
            .eligibilityChannels,
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

        let hub = openPaymentAccount(bankAccounts: .error)
            .tapWithdrawOpeningHub()
            .verifyRecentAccountsLoadError()

        let bankAccountsRequestsBefore = requestCount(.bankAccounts)
        hub.tapRecentAccountsRetry()

        verifyRequestedAgain(
            .bankAccounts,
            since: bankAccountsRequestsBefore,
            "Tapping the error tile should request the bank accounts again"
        )
        hub.verifyRecentAccountsLoadError()
    }

    func testBankTransferBlock_UnavailableWhenOptionsFailOrEmpty() {
        setAllureId(12175)

        openPaymentAccount(offrampOptions: .error)
            .tapWithdrawOpeningHub()
            .verifyBankTransferUnavailable()
            .close()

        switchOfframpOptions(to: .empty)

        verifyOfframpOptionsRequested {
            TangemPayMainScreen(app).tapWithdrawOpeningHub()
        }

        TangemPayWithdrawHubScreen(app)
            .verifyBankTransferUnavailable()
    }

    func testWithdrawHub_ShowsRecentBankRecipients() {
        setAllureId(12177)

        openPaymentAccount(bankAccounts: .twoAccounts)
            .tapWithdrawOpeningHub()
            .verifyRecentRecipientCount(2)
            .verifyRecentRecipient(.john)
            .verifyRecentRecipient(.acme)
            .verifySeeAllNotDisplayed()
            .close()

        switchBankAccounts(to: .fiveAccounts)

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

    func testRecipient_AddedToRecents_AfterSuccessfulBankTransfer() {
        setAllureId(12178)

        let signaturesBefore = requestCount(.orderSignature, method: "POST")

        openPaymentAccount(extraScenarios: Constants.swapScenarios)
            .tapWithdrawOpeningHub()
            .verifyBankRecentsZeroState()
            .tapToPersonalAccount()
            .enterAmount(Constants.transferAmount)
            .tapContinueToTransferType()
            .selectTransferType(.thirdPartyAccount)
            .selectAccountType(.checking)
            .fillRecipientDetails(.jane)
            .fillBankDetails(.chase)
            .tapSend()
            .waitForScreen(amount: Constants.sentAmount)
            .tapClose()

        XCTContext.runActivity(named: "Verify the bank transfer signature was submitted once") { _ in
            XCTAssertEqual(
                requestCount(.orderSignature, method: "POST") - signaturesBefore,
                1,
                "The signed bank transfer should be submitted exactly once"
            )
        }

        switchBankAccounts(to: .afterTransfer)

        TangemPayMainScreen(app)
            .tapWithdrawOpeningHub()
            .verifyRecentRecipient(.jane)
    }

    func testToken_AddedToRecents_AfterSuccessfulSwap() {
        setAllureId(12670)

        let withdrawDataBefore = requestCount(.withdrawData, method: "POST")

        openPaymentAccount(bankAccounts: .afterTransfer, extraScenarios: Constants.swapScenarios)
            .tapWithdrawOpeningHub()
            .tapWithinPortfolio()
            .chooseTokenFromEmptySelector(Constants.bitcoinName)
            .enterFromAmount(Constants.transferAmount)
            .confirmSwapUntilFinishOpened {
                requestCount(.withdrawData, method: "POST") == withdrawDataBefore
            }
            .tapCloseButton()

        TangemPayMainScreen(app)
            .waitForScreen()
            .tapWithdrawOpeningHub()
            .verifyRecentToken(Constants.bitcoinName)
    }

    func testBankRecipients_SearchByNameAndAccountNumber() {
        setAllureId(12180)

        openPaymentAccount(bankAccounts: .fiveAccounts)
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

        openPaymentAccount(bankAccounts: .fiveAccounts)
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

        let paymentAccount = openPaymentAccount(balance: .multiNetworkStatuses)
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

        switchBalance(to: .arbitrumTopUp)
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

    private func verifyOfframpOptionsRequested(by action: () -> Void) {
        let optionsRequestsBefore = requestCount(.offrampOptions)
        action()
        verifyRequestedAgain(
            .offrampOptions,
            since: optionsRequestsBefore,
            "Opening the Withdraw hub should request the bank off-ramp options"
        )
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

        static let aliceSavedDetails = [TangemPayBankRecipient.alice.accountNumber, "021000021", "Alice", "Smith", "Chase Bank"]

        enum Search {
            static let namePrefix = "Ali"
            static let accountNumberPart = "0000"
            static let unknown = "zzqx"
        }
    }
}
