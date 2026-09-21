//
//  TangemPayMultichainDepositUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayMultichainDepositUITests: BaseTestCase {
    func testAddFundsSheetListsBankTransferThenSwapThenReceive() {
        setAllureId(11366)

        launchWithMultiNetworkBalance(extraScenarios: [
            ScenarioConfig(name: Constants.Scenario.channels, initialState: Constants.State.virtualAccount),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapAddFunds()
        .waitForScreen()
        .verifyOptionsOrder()
        .verifyOptionLabels(
            bankTransfer: ["From a bank account", "Receive USD from a bank account"],
            swap: ["From your Tangem Wallet", "Use crypto from your wallet to top up your payment account"],
            receive: ["From another wallet or exchange", "Send USDC or USDT to your account"]
        )
    }

    func testPaymentAccountShowsMultiNetworkAndMultiTokenIndicators() {
        setAllureId(11367)

        launchWithMultiNetworkBalance()
            .verifyTangemPayTileVisible()
            .verifyTangemPayTileBalanceContains("$17.00")
            .verifyTangemPayTileCurrency("USD")
            .openTangemPay()
            .waitForScreen()
            .verifyHeader(title: "Payment account", subtitle: "US Dollars")
    }

    func testChooseNetworkSheetSplitsNetworksIntoFastAndOtherOptions() {
        setAllureId(11368)

        openChooseNetworkSheet()
            .verifyFastOptions([.polygon, .bsc, .base])
            .verifyOtherOptions([.arbitrum, .ethereum])
            .verifyCloseButtonDisplayed()
    }

    func testDisabledNetworkOpensOtherNetworksSheet() {
        setAllureId(11370)

        openChooseNetworkSheet()
            .tapNetworkExpectingOtherNetworks(.arbitrum)
            .waitForSheet()
            .verifyContent(
                title: "Send USDT/USDC on any EVM-chain to your Tangem Wallet",
                subtitle: "Then swap it to payment account with zero fees"
            )
            .tapClose()
            .waitForSheet()
            .verifyFastOptions([.polygon, .bsc, .base])
    }

    func testEnabledNetworkShowsReceiveSheetWithAddressAndQRCode() {
        setAllureId(11372)

        let receiveSheet = openChooseNetworkSheet()
            .tapNetworkExpectingReceive(.bsc)
            .waitForSheet()
            .verifyWarning(
                title: "Send only USDC or USDT on the BNB Smart Chain network",
                description: "Sending any other currency will result in its irreversible loss."
            )
            .verifyHeading("USDC or USDT on BNB Smart Chain network")
            .verifyTokenIcons(["USDC", "USDT"])
            .verifyAddress(Constants.DepositAddress.bsc)
            .verifyActionButtonsDisplayed()

        receiveSheet
            .tapShowQRCode()
            .waitForDisplay()
            .verifyDisplayedAddress(Constants.DepositAddress.bsc)
            .verifyCopyAndShareButtonsDisplayed()
            .assertQRCodeEncodesDisplayedAddress()
    }

    func testEnabledNetworkAddressActionsCopyAndShare() {
        setAllureId(11383)

        let receiveSheet = openChooseNetworkSheet()
            .tapNetworkExpectingReceive(.bsc)
            .waitForSheet()
            .verifyAddress(Constants.DepositAddress.bsc)
            .tapCopy()
            .verifyToastVisible(text: Constants.addressCopiedToast)

        receiveSheet
            .tapShare()
            .waitForSheet()
            .verifySharedText(Constants.DepositAddress.bsc)
            .dismiss(to: TangemPayMultichainReceiveSheet.self)
            .waitForSheet()
            .tapShowQRCode()
            .waitForDisplay()
            .verifyDisplayedAddress(Constants.DepositAddress.bsc)
            .tapCopy()
            .verifyToastVisible(text: Constants.addressCopiedToast)
            .tapShare()
            .waitForSheet()
            .verifySharedText(Constants.DepositAddress.bsc)
            .dismiss(to: ReceiveQRCodeSheet.self)
            .waitForDisplay()
    }

    func testNotIssuedNetworkActivationPlacesOrderAndOpensReceiveSheet() {
        setAllureId(11380)

        wireMockClient.resetRequestJournalSync()

        openChooseNetworkSheet(activationState: Constants.State.activationPending)
            .verifyFastOptions([.polygon, .base])
            .tapNetworkExpectingActivation(.base)
            .verifyNetworkSubtitle(.base, contains: Constants.preparingAddressSubtitle)

        TangemPayMultichainReceiveSheet(app)
            .waitForSheet()
            .verifyHeading("USDC or USDT on Base network")
            .verifyAddress(Constants.DepositAddress.base)

        XCTContext.runActivity(named: "Verify the activation looked up orders first and then placed exactly one") { _ in
            // An empty lookup is retried once before the order is placed.
            XCTAssertEqual(orderLookupRequestCount(), 2, "Activation should look up existing orders twice")
            XCTAssertEqual(placeOrderRequestCount(), 1, "Activation should place exactly one order")
        }
    }

    func testNotIssuedNetworkActivationResumesOrderAlreadyInFlight() {
        setAllureId(11382)

        wireMockClient.resetRequestJournalSync()

        openChooseNetworkSheet(activationState: Constants.State.activationInFlight)
            .tapNetworkExpectingActivation(.base)
            .verifyNetworkSubtitle(.base, contains: Constants.preparingAddressSubtitle)

        TangemPayMultichainReceiveSheet(app)
            .waitForSheet()
            .verifyHeading("USDC or USDT on Base network")
            .verifyAddress(Constants.DepositAddress.base)

        XCTContext.runActivity(named: "Verify the in-flight order was resumed instead of placing a new one") { _ in
            XCTAssertEqual(orderLookupRequestCount(), 1, "A resumed activation should look up existing orders once")
            XCTAssertEqual(placeOrderRequestCount(), 0, "Resuming an activation should place no new order")
        }
    }

    private func launchWithMultiNetworkBalance(extraScenarios: [ScenarioConfig] = []) -> MainScreen {
        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: Constants.Scenario.balance, initialState: Constants.State.multiNetworkStatuses),
            ScenarioConfig(name: Constants.Scenario.history, initialState: Constants.State.emptyHistory),
        ] + extraScenarios)
    }

    private func openChooseNetworkSheet(activationState: String? = nil) -> TangemPayChooseNetworkSheet {
        let activationScenarios = activationState.map { [ScenarioConfig(name: Constants.Scenario.activation, initialState: $0)] } ?? []

        return launchWithMultiNetworkBalance(extraScenarios: activationScenarios)
            .openTangemPay()
            .waitForScreen()
            .tapAddFunds()
            .waitForScreen()
            .tapReceiveExpectingChooseNetwork()
            .waitForSheet()
    }

    private func placeOrderRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "POST", urlPathPattern: Constants.Endpoint.placeOrder)
    }

    private func orderLookupRequestCount() -> Int {
        wireMockClient.requestCountSync(method: "GET", urlPattern: Constants.Endpoint.orderLookupPattern)
    }
}

private extension TangemPayMultichainDepositUITests {
    enum Constants {
        static let preparingAddressSubtitle = "Preparing address…"
        static let addressCopiedToast = "Address was copied to clipboard"

        enum Scenario {
            static let balance = "tangem_pay_balance_update"
            static let history = "tangem_pay_transaction_history"
            static let channels = "tangem_pay_eligibility_channels"
            static let activation = "tangem_pay_network_activation"
        }

        enum State {
            static let multiNetworkStatuses = "MultiNetworkStatuses"
            static let emptyHistory = "InitialEmpty"
            static let virtualAccount = "VirtualAccount"
            static let activationPending = "NetworkActivationPending"
            static let activationInFlight = "NetworkActivationInFlight"
        }

        enum Endpoint {
            static let placeOrder = "/bff-v2/v1/order"
            static let orderLookupPattern = "/bff-v2/v1/order\\?.*SMART_CONTRACT_ISSUE_RAIN.*"
        }

        enum DepositAddress {
            static let bsc = "0x0000000000000000000000000000000000000056"
            static let base = "0x0000000000000000000000000000000000008453"
        }
    }
}
