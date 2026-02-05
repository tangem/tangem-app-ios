//
//  SendAddressQRCodeUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest

final class SendAddressQRCodeUITests: BaseTestCase {
    func testQRScannerElementsDisplayedWhenTappingScanButton() {
        setAllureId(4574)

        let tokenName = "Ethereum"
        let sendAmount = "1"

        launchApp(tangemApiType: .mock)

        let sendScreen = CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .longPressToken(tokenName)
            .waitForActionButtons()
            .tapSend()
            .waitForDisplay()
            .enterAmount(sendAmount)
            .tapNextButton()

        sendScreen
            .tapScanQRButton()
            .waitForDisplay(networkName: tokenName)
            .tapCloseButton()
            .validateDestinationIsEmpty()
            .waitForNextButtonDisabled()
    }
}
