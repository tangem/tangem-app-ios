//
//  TangemPayPolygonUsdcTransferUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayPolygonUsdcTransferUITests: BaseTestCase {
    func testPolygonUsdcTransferToPaymentAccountWithoutProviderFee() {
        setAllureId(9693)

        let mainScreen = launchAndImportHotWallet(expressApiType: .mock, scenarios: Constants.scenarios)
            .verifyTangemPayTileBalanceContains(Constants.Balance.initial)
            .waitForTokenBalanceLoaded(tokenName: Constants.usdc)
        let usdcBalance = mainScreen.getTokenBalanceNumeric(tokenName: Constants.usdc)

        mainScreen
            .tapToken(Constants.usdc)
            .waitForNonZeroTotalBalance()
            .tapSwapButton()
            .closeStoriesIfNeeded()
            .validateSwapScreenDisplayed()
            .tapToTokenSelector()
            .selectToken(Constants.usdc, inAccount: Localization.tangempayPaymentAccount)
            .waitForReceiveAccount(Localization.tangempayPaymentAccount)
            .enterFromAmount(Constants.Amount.deposit)
            .assertConfirmButtonLabelIsTransfer()
            .waitForProviderBlockNotDisplayed()
            .waitForNonZeroNetworkFee()
            .confirmTransferAndOpenFinish()
            .waitForDisplay()
            .assertHeaderTitle(Localization.transferInProgressTitle)
            .tapCloseButton()

        completeTransfer(payBalanceState: Constants.State.afterPolygonDeposit, usdcBalanceState: Constants.State.afterPayDeposit)

        let walletScreen = TokenScreen(app).goBackToMain()
        pullToRefresh()
        walletScreen
            .waitForTokenBalance(tokenName: Constants.usdc, to: .decrease, from: usdcBalance)
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains(Constants.Balance.afterDeposit)
    }

    func testPaymentAccountTransferToPolygonUsdcWithoutFee() {
        setAllureId(12129)

        let mainScreen = launchAndImportHotWalletWithRealPayAuthorization(
            expressApiType: .mock,
            scenarios: Constants.scenarios + [
                ScenarioConfig(name: "tangem_pay_eligibility_channels", initialState: "BankOfframp"),
            ]
        )
        .waitForTokenBalanceLoaded(tokenName: Constants.usdc)
        let usdcBalance = mainScreen.getTokenBalanceNumeric(tokenName: Constants.usdc)

        mainScreen
            .openTangemPay()
            .waitForScreen()
            .verifyBalanceContains(Constants.Balance.initial)
            .tapWithdrawOpeningHub()
            .tapWithinPortfolio()
            .chooseTokenFromEmptySelector(Constants.usdc)
            .waitToTokenDisplayed(tokenSymbol: Constants.usdc)
            .enterFromAmount(Constants.Amount.withdraw)
            .assertConfirmButtonLabelIsTransfer()
            .waitForZeroNetworkFee()
            .confirmTransferAndOpenFinish()
            .waitForDisplay()
            .assertHeaderTitle(Localization.transferInProgressTitle)
            .tapCloseButton()

        completeTransfer(payBalanceState: Constants.State.afterWithdraw, usdcBalanceState: Constants.State.afterPayWithdraw)

        TangemPayMainScreen(app).waitForScreen()
        pullToRefresh()
        TangemPayMainScreen(app)
            .verifyBalanceContains(Constants.Balance.afterWithdraw)
            .tapBack()
        pullToRefresh()
        MainScreen(app).waitForTokenBalance(tokenName: Constants.usdc, to: .increase, from: usdcBalance)
    }

    private func completeTransfer(payBalanceState: String, usdcBalanceState: String) {
        XCTContext.runActivity(named: "Complete the transfer on the backend and on chain") { _ in
            wireMockClient.setScenarioStateSync(Constants.Scenario.payBalance, state: payBalanceState)
            wireMockClient.setScenarioStateSync(Constants.Scenario.usdcBalance, state: usdcBalanceState)
        }
    }
}

private extension TangemPayPolygonUsdcTransferUITests {
    enum Constants {
        static let usdc = "USDC"

        static let scenarios = [
            ScenarioConfig(name: "user_tokens_api", initialState: "TangemPayTransferUsdc"),
            ScenarioConfig(name: "express_api_assets", initialState: "PayWithdrawAllNetworks"),
            ScenarioConfig(name: Scenario.payBalance, initialState: "InitialBalanceMultinetwork"),
            ScenarioConfig(name: "tangem_pay_transaction_history", initialState: "InitialEmpty"),
        ]

        enum Amount {
            static let deposit = "10"
            static let withdraw = "5"
        }

        enum Balance {
            static let initial = "$10.00"
            static let afterDeposit = "$20.00"
            static let afterWithdraw = "$5.00"
        }

        enum Scenario {
            static let payBalance = "tangem_pay_balance_update"
            static let usdcBalance = "polygon_usdc_balance"
        }

        enum State {
            static let afterPolygonDeposit = "AfterPolygonDeposit"
            static let afterWithdraw = "AfterWithdraw"
            static let afterPayDeposit = "AfterPayDeposit"
            static let afterPayWithdraw = "AfterPayWithdraw"
        }
    }
}
