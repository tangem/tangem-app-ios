//
//  BuyReturnToAppUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class BuyReturnToAppUITests: BaseTestCase {
    private let safariHelper = SafariHelper()

    func testBuyReturnToApp_FromTokenDetails() {
        setAllureId(2573)

        launchApp(tangemApiType: .mock, expressApiType: .mock, scenarios: Constants.scenarios)

        let onrampScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.Token.polygon)
            .tapBuyButton()

        completePurchaseAndReturn(from: onrampScreen)
            .tapClose(to: TokenScreen.self)
            .waitForTokenName(Constants.Token.polygon)
    }

    func testBuyReturnToApp_FromTokenContextMenu() {
        setAllureId(12739)

        launchApp(tangemApiType: .mock, expressApiType: .mock, scenarios: Constants.scenarios)

        let onrampScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(Constants.Token.polygon)
            .tapBuy()

        completePurchaseAndReturn(from: onrampScreen)
            .tapClose(to: MainScreen.self)
            .verifyTokenVisible(Constants.Token.polygon)
    }

    func testBuyReturnToApp_FromAddFunds() {
        setAllureId(12740)

        launchApp(tangemApiType: .mock, expressApiType: .mock, scenarios: Constants.scenarios)

        let onrampScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapMainBuy()
            .waitBuyTokenSelectorDisplayed()
            .tapToken(Constants.Token.polygon)
            .tapBuy()

        completePurchaseAndReturn(from: onrampScreen)
            .tapClose(to: MainScreen.self)
            .verifyTokenVisible(Constants.Token.polygon)
    }

    func testBuyReturnToApp_FromMarkets() {
        setAllureId(12741)

        launchApp(tangemApiType: .mock, expressApiType: .mock, scenarios: Constants.scenarios)

        let onrampScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openMarketsSheet()
            .openTokenList()
            .openTokenDetails(Constants.Token.ethereum)
            .tapAddFunds()
            .tapBuy()

        completePurchaseAndReturn(from: onrampScreen)
            .tapClose(to: MarketsTokenDetailsScreen.self)
            .waitForAddFundsButton()
    }

    private func completePurchaseAndReturn(from onrampScreen: OnrampScreen) -> OnrampFinishScreen {
        onrampScreen
            .enterAmount(Constants.amount)
            .waitForProvidersToLoad()
            .tapBuyButton(provider: Constants.provider)

        openOnrampReturnLink(Constants.ReturnLink.cancel)

        onrampScreen
            .waitForProvidersToLoad()
            .tapBuyButton(provider: Constants.provider)

        let successLinkOpenedAt = Date()
        openOnrampReturnLink(Constants.ReturnLink.success)

        return OnrampFinishScreen(app)
            .waitForInProgressTitle()
            .verifyTransactionDate(between: successLinkOpenedAt, and: Date())
            .verifyPurchaseDetails(
                fiatAmount: Constants.amount,
                cryptoAmount: Constants.cryptoAmount,
                provider: Constants.provider
            )
            .verifyTransactionStatus(Localization.expressExchangeStatusReceivingActive)
            .waitForCloseButton()
    }

    private func openOnrampReturnLink(_ link: String) {
        XCTContext.runActivity(named: "Return to the app from the provider page via \(link)") { _ in
            safariHelper.safari.launch()
            safariHelper.openDeeplink(link)
            safariHelper.tapOpenButton()
        }
    }
}

private extension BuyReturnToAppUITests {
    enum Constants {
        static let amount = "100"
        static let cryptoAmount = "488.24938338"
        static let provider = "Mercuryo"

        static let scenarios = [
            ScenarioConfig(name: "onramp_widget", initialState: "Started"),
        ]

        enum Token {
            static let polygon = "Polygon"
            static let ethereum = "Ethereum"
        }

        enum ReturnLink {
            static let cancel = "tangem://onramp?result=cancel"
            static let success = "tangem://onramp?result=success"
        }
    }
}
