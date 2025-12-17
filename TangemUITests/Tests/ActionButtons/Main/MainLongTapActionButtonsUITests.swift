//
//  MainLongTapActionButtonsUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class MainLongTapActionButtonsUITests: BaseTestCase {
    private let token = "Polygon"

    func testLongTapBuy_OpensOnrampForToken() throws {
        let expectedTitle = "Buy \(token)"

        setAllureId(82)
        launchApp(tangemApiType: .mock)

        let contextMenu = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(token)

        try contextMenu
            .waitForActionButtons()
            .tapBuy()
            .tapCurrencySelector()
            .selectCurrency("USD")
            .waitForAmountFieldDisplay(
                amount: "",
                currency: "$",
                title: expectedTitle
            )
    }

    func testLongTapCopyAddress_CopiesAndShowsToast() {
        setAllureId(84)
        launchApp(tangemApiType: .mock)

        let contextMenu = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(token)

        contextMenu
            .waitForActionButtons()
            .tapCopyAddress()
            .waitForAddressCopiedToast()
    }

    func testLongTapContextMenu_UIValidation() {
        setAllureId(79)
        launchApp(tangemApiType: .mock)

        let contextMenu = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(token)

        contextMenu
            .waitForActionButtons()
    }

    func testLongTapReceive_NavigatesThroughReceiveFlow() {
        setAllureId(86)
        launchApp(tangemApiType: .mock)

        let contextMenu = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(token)

        let receiveTemplates = contextMenu
            .waitForActionButtons()
            .tapReceive()
            .tapUnderstoodIfNeeded()

        let qrCodeSheet = receiveTemplates
            .validateShowQRCodeButtonDisplayed()
            .tapShowQRCode()

        qrCodeSheet.waitForDisplay()
    }

    func testLongTapSend_NavigatesToSendScreen() {
        setAllureId(83)
        launchApp(tangemApiType: .mock)

        let contextMenu = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(token)

        let sendScreen = contextMenu
            .waitForActionButtons()
            .tapSend()

        sendScreen.waitForDisplay()
    }

    func testLongTapExchange_NavigatesToSwapScreen() {
        setAllureId(87)
        launchApp(tangemApiType: .mock)

        let contextMenu = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(token)

        let swapScreen = contextMenu
            .waitForActionButtons()
            .tapSwap()
            .closeStoriesIfNeeded()

        swapScreen.validateSwapScreenDisplayed()
    }

    func testLongTapSell_NavigatesToMoonPay() {
        let token = "Ethereum"

        setAllureId(85)
        launchApp(tangemApiType: .mock)

        let contextMenu = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(token)

        contextMenu
            .waitForActionButtons()
            .tapSell()
            .waitForDisplay()
    }

    func testLongTapBitcoin_SellButtonNotPresent() {
        let token = "Bitcoin"

        setAllureId(77)
        launchApp(tangemApiType: .mock)

        let contextMenu = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(token)

        contextMenu
            .verifySellButtonDoesNotExist()
    }
}
