//
//  SendViaSwapQuotesUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendViaSwapQuotesUITests: BaseTestCase {
    private let safariHelper = SafariHelper()

    func testOfferIsRecalculatedAfterAmountChange() {
        setAllureId(11533)
        launchSendViaSwap()

        let sendScreen = openSummary(receiveToken: Constants.Token.ethereum, address: Constants.Address.ethereum)
            .tapAmountField()
            .waitForNextButton(titled: Constants.Button.continueTitle)
            .tapSourceTokenBlock()
            .waitForRateBadge(Constants.Badge.floatingRate)
            .waitForAmountValue(containing: Constants.Amount.send)

        let quoteRequestsBefore = quoteRequestCount(matching: Constants.Endpoint.doubledSendAmountQuote)

        sendScreen
            .clearAmount()
            .enterAmount(Constants.Amount.doubledSend)
            .waitForApproximateReceiveAmount(containing: Constants.Amount.doubledReceive)

        waitForQuoteRequestCount(matching: Constants.Endpoint.doubledSendAmountQuote, toExceed: quoteRequestsBefore)

        sendScreen
            .waitForNextButtonEnabled()
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
            .waitForSendAmount(containing: Constants.Amount.doubledSend)
            .waitForReceiveAmount(containing: Constants.Amount.doubledReceive)
            .assertBestRateBadgeOnProvider()
    }

    func testNetworkFeeSpeedSelection() {
        setAllureId(11532)
        launchSendViaSwap()

        let summaryScreen = openSummary(receiveToken: Constants.Token.ethereum, address: Constants.Address.ethereum)
            .waitForNetworkFeeLoaded(fiatSymbol: Constants.Symbol.fiat)

        let summaryFeeBefore = summaryScreen.getNetworkFeeNumericValue()

        let feeSelector = summaryScreen
            .tapFeeBlock()
            .waitForSwapFeeOptions(cryptoSymbol: Constants.Symbol.bitcoin, fiatSymbol: Constants.Symbol.fiat)
            .assertOptionSelected(.market)
            .assertOptionNotSelected(.fast)

        let marketFee = feeSelector.getCryptoFee(of: .market, cryptoSymbol: Constants.Symbol.bitcoin)
        let fastFee = feeSelector.getCryptoFee(of: .fast, cryptoSymbol: Constants.Symbol.bitcoin)
        XCTAssertGreaterThan(fastFee, marketFee, "Fast fee should be higher than Market fee")

        feeSelector
            .selectFastAndWaitForClose()
            .waitForNetworkFeeIncreased(from: summaryFeeBefore)
            .tapFeeBlock()
            .assertOptionSelected(.fast)
    }

    func testQuoteIsUpdatedAutomatically() {
        setAllureId(11534)
        launchSendViaSwap(extraScenarios: [
            ScenarioConfig(name: Constants.Scenario.exchangeQuote, initialState: Constants.State.autoRefresh),
        ])

        let summaryScreen = openSummary(
            receiveToken: Constants.Token.ethereum,
            address: Constants.Address.ethereum,
            isFloatingRate: true
        )
        .assertBestRateBadgeOnProvider()

        let bestRateReceiveAmount = summaryScreen.getReceiveAmountValue()

        summaryScreen
            .tapProviderBlock()
            .waitForDisplay()
            .selectProvider(name: Constants.Provider.changeHero)
            .assertProviderName(Constants.Provider.changeHero)

        var receiveAmount = summaryScreen.waitForReceiveAmountChanged(from: bestRateReceiveAmount, timeout: Constants.Quote.updateTimeout)
        let quoteRequestsBefore = quoteRequestTimestamps(matching: Constants.Endpoint.changeHeroQuote).count

        for _ in 0 ..< Constants.Quote.autoUpdatesCount {
            receiveAmount = summaryScreen.waitForReceiveAmountChanged(from: receiveAmount, timeout: Constants.Quote.updateTimeout)
            summaryScreen
                .assertProviderName(Constants.Provider.changeHero)
                .assertBestRateBadgeNotOnProvider()
                .waitForSendButtonEnabled()
        }

        XCTContext.runActivity(named: "Assert quotes are requested about every 10 seconds") { _ in
            let timestamps = Array(quoteRequestTimestamps(matching: Constants.Endpoint.changeHeroQuote).dropFirst(quoteRequestsBefore))
            let intervals = zip(timestamps, timestamps.dropFirst()).map { $1.timeIntervalSince($0) }
            XCTAssertFalse(intervals.isEmpty, "At least two automatic quote requests are expected, got \(timestamps)")
            XCTAssertTrue(
                intervals.allSatisfy { Constants.Quote.updateInterval.contains($0) },
                "Quote update intervals \(intervals) should be within \(Constants.Quote.updateInterval)"
            )
        }
    }

    func testConfirmReceiveTokenChange() {
        setAllureId(11536)
        launchSendViaSwap()

        let sendScreen = openSummary(
            receiveToken: Constants.Token.solana,
            address: Constants.Address.solana,
            isFloatingRate: true
        )
        .tapAmountField()
        .tapReceiveTokenBlock()
        .waitForRateBadge(Constants.Badge.fixedRate)
        .tapReceiveTokenBlock()
        .tapReceiveToken(name: Constants.Token.ethereum)
        .tapReceiveNetworkOption(name: Constants.Token.ethereum)
        .waitForChangeTokenAlert()
        .waitForChangeTokenAlertMessage(Constants.Alert.changeTokenMessage)
        .tapChangeTokenAlertContinue()

        sendScreen
            .waitForNextButton(titled: Constants.Button.nextTitle)
            .waitForReceiveToken(named: Constants.Token.ethereum)
            .waitForCompactSendAmount(containing: Constants.Amount.send)
            .waitForRateBadge(Constants.Badge.fixedRate)
            .waitForReceiveAmountValue(containing: Constants.Amount.receive)
            .trimReceiveAmount(to: Constants.Amount.changedReceive)
            .waitForNextButtonEnabled()
            .tapNextButton()
            .validateDestinationIsEmpty()
            .waitForDestinationPlaceholder(Constants.Placeholder.ensAddress)
    }

    func testSwitchFromFixedToFloatingRate() {
        setAllureId(11537)
        launchSendViaSwap()

        let sendScreen = openSendScreen()
            .tapConvertButton()
            .tapReceiveToken(name: Constants.Token.ethereum)
            .tapReceiveNetworkOption(name: Constants.Token.ethereum)
            .waitForRateBadge(Constants.Badge.fixedRate)
            .enterReceiveAmount(Constants.Amount.receive)
            .waitForCompactSendAmount(containing: Constants.Amount.send)
            .waitForReceiveAmountValue(containing: Constants.Amount.receive)
            .assertApproximateReceiveAmountNotDisplayed()
            .waitForNextButtonEnabled()
            .tapSourceTokenBlock()
            .waitForRateBadge(Constants.Badge.floatingRate)
            .waitForAmountValue(containing: Constants.Amount.send)

        let quoteRequestsBefore = quoteRequestCount(matching: Constants.Endpoint.doubledSendAmountQuote)

        sendScreen
            .clearAmount()
            .enterAmount(Constants.Amount.doubledSend)

        waitForQuoteRequestCount(matching: Constants.Endpoint.doubledSendAmountQuote, toExceed: quoteRequestsBefore)

        sendScreen
            .waitForApproximateReceiveAmount(containing: Constants.Amount.doubledReceive)
            .waitForNextButtonEnabled()
    }

    func testFCAWarningForCexProviderInUK() {
        setAllureId(3973)
        launchSendViaSwap(extraScenarios: [
            ScenarioConfig(name: Constants.Scenario.geo, initialState: Constants.State.unitedKingdom),
            ScenarioConfig(name: Constants.Scenario.exchangeQuote, initialState: Constants.State.changeHeroBestRate),
        ])

        let summaryScreen = openSendScreen()
            .tapConvertButton()
            .tapReceiveToken(name: Constants.Token.ethereum)
            .tapReceiveNetworkOption(name: Constants.Token.ethereum)
            .waitForRateBadge(Constants.Badge.fixedRate)
            .tapSourceTokenBlock()
            .waitForRateBadge(Constants.Badge.floatingRate)
            .enterAmount(Constants.Amount.send)
            .waitForNextButtonEnabled()
            .tapNextButton()
            .enterDestination(Constants.Address.ethereum)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
            .assertProviderName(Constants.Provider.changeHero)
            .tapProviderBlock()
            .waitForDisplay()
            .assertFCAWarningBadge(onProvider: Constants.Provider.changelly)
            .assertFCAWarningBadge(onProvider: Constants.Provider.simpleSwap)
            .assertNoFCAWarningBadge(onProvider: Constants.Provider.changeHero)
            .selectProvider(name: Constants.Provider.changelly)
            .assertProviderName(Constants.Provider.changelly)
            .waitForFCAWarning()
            .tapLegalLink(Constants.Link.termsOfUse)

        safariHelper.waitForPageURL(containing: Constants.Link.changellyTermsOfUsePath)

        summaryScreen
            .returnFromBrowser()
            .assertProviderName(Constants.Provider.changelly)
            .waitForFCAWarning()
            .tapLegalLink(Constants.Link.privacyPolicy)

        safariHelper.waitForPageURL(containing: Constants.Link.changellyPrivacyPolicyPath)
        summaryScreen.returnFromBrowser()
    }

    private func launchSendViaSwap(extraScenarios: [ScenarioConfig] = []) {
        launchApp(
            tangemApiType: .mock,
            expressApiType: .mock,
            clearStorage: true,
            scenarios: [
                ScenarioConfig(name: Constants.Scenario.bitcoinUTXO, initialState: Constants.State.balance),
                ScenarioConfig(name: Constants.Scenario.expressAssets, initialState: Constants.State.bitcoinExchangeEnabled),
                ScenarioConfig(name: Constants.Scenario.userTokens, initialState: Constants.State.wallet2),
                ScenarioConfig(name: Constants.Scenario.networkProviders, initialState: Constants.State.bitcoinMockOnly),
            ] + extraScenarios
        )
    }

    private func openSendScreen() -> SendScreen {
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(Constants.Token.bitcoin)
            .tapSendButton()
            .waitForDisplay()
            .waitForConvertButton()
    }

    private func openSummary(receiveToken: String, address: String, isFloatingRate: Bool = false) -> SendSummaryScreen {
        let sendScreen = openSendScreen()
            .enterAmount(Constants.Amount.send)
            .tapConvertButton()
            .tapReceiveToken(name: receiveToken)
            .tapReceiveNetworkOption(name: receiveToken)

        if isFloatingRate {
            sendScreen
                .waitForRateBadge(Constants.Badge.fixedRate)
                .tapSourceTokenBlock()
                .waitForRateBadge(Constants.Badge.floatingRate)
        }

        return sendScreen
            .waitForNextButtonEnabled()
            .tapNextButton()
            .enterDestination(address)
            .tapNextButtonToSummary()
            .waitForDisplay(checkValidatorBlock: false)
    }

    private func quoteRequestCount(matching urlPattern: String) -> Int {
        wireMockClient.requestCountSync(method: Constants.Endpoint.method, urlPattern: urlPattern)
    }

    private func quoteRequestTimestamps(matching urlPattern: String) -> [Date] {
        wireMockClient.findRequestTimestampsSync(method: Constants.Endpoint.method, urlPattern: urlPattern)
    }

    private func waitForQuoteRequestCount(matching urlPattern: String, toExceed previousCount: Int) {
        XCTContext.runActivity(named: "Wait for a quote request matching '\(urlPattern)'") { _ in
            let predicate = NSPredicate { [self] _, _ in
                quoteRequestCount(matching: urlPattern) > previousCount
            }
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "A quote request matching '\(urlPattern)' should be sent"
            )
        }
    }
}

private extension SendViaSwapQuotesUITests {
    enum Constants {
        enum Scenario {
            static let bitcoinUTXO = "bitcoin_utxo"
            static let expressAssets = "express_api_assets"
            static let userTokens = "user_tokens_api"
            static let exchangeQuote = "exchange_quote_bitcoin"
            static let geo = "geo"
            static let networkProviders = "networks_providers"
        }

        enum State {
            static let balance = "Balance"
            static let bitcoinExchangeEnabled = "BitcoinExchangeEnabled"
            static let wallet2 = "Wallet2"
            static let autoRefresh = "AutoRefresh"
            static let changeHeroBestRate = "ChangeHeroBestRate"
            static let unitedKingdom = "GB"
            static let bitcoinMockOnly = "BitcoinMockOnly"
        }

        enum Endpoint {
            static let method = "GET"
            static let doubledSendAmountQuote = "/v1/exchange-quote\\?.*fromAmount=200000.*"
            static let changeHeroQuote = "/v1/exchange-quote\\?.*providerId=changehero.*"
        }

        enum Token {
            static let bitcoin = "Bitcoin"
            static let ethereum = "Ethereum"
            static let solana = "Solana"
        }

        enum Address {
            static let ethereum = "0x5aa711F440Eb6d4361148bBD89d03464628ace84"
            static let solana = "5fcy9woa8Di1QHcce65CsV3XKrxdB2pD4HJx5xx82ipM"
        }

        enum Amount {
            static let send = "0.001"
            static let doubledSend = "0.002"
            static let receive = "0.0428"
            static let doubledReceive = "0.0856"
            static let changedReceive = "0.04"
        }

        enum Provider {
            static let changeHero = "ChangeHero"
            static let changelly = "Changelly"
            static let simpleSwap = "SimpleSwap"
        }

        enum Badge {
            static let fixedRate = "Rate is fixed"
            static let floatingRate = "Floating rate"
        }

        enum Button {
            static let nextTitle = "Next"
            static let continueTitle = "Continue"
        }

        enum Alert {
            static let changeTokenMessage = "Are you sure you want to change the receiving token? This will reset your previously entered data."
        }

        enum Placeholder {
            static let ensAddress = "ENS name or address"
        }

        enum Symbol {
            static let bitcoin = "BTC"
            static let fiat = "$"
        }

        enum Link {
            static let termsOfUse = "Terms\u{00A0}of\u{00A0}Use"
            static let privacyPolicy = "Privacy\u{00A0}Policy"
            static let changellyTermsOfUsePath = "changelly.com/terms-of-use"
            static let changellyPrivacyPolicyPath = "changelly.com/privacy-policy"
        }

        enum Quote {
            static let autoUpdatesCount = 2
            static let updateTimeout: TimeInterval = 30
            static let updateInterval: ClosedRange<TimeInterval> = 9.5 ... 15
        }
    }
}
