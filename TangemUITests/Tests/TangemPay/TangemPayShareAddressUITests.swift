//
//  TangemPayShareAddressUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayShareAddressUITests: BaseTestCase {
    private let depositNetwork = "Polygon"

    func testShareDepositAddressFromAddFunds() {
        setAllureId(9551)

        let receiveSheet = launchAndImportHotWallet()
            .openTangemPay()
            .waitForScreen()
            .tapAddFunds()
            .waitForScreen()
            .verifySwapAndReceiveOptions()
            .tapReceive()
            .verifyDepositInfo(network: depositNetwork)
            .tapGotIt()
            .verifyCopyAndShareButtonsDisplayed()

        // Tangem Pay exposes a single default address, which uses the non-legacy identifiers.
        let address = receiveSheet.readSegwitAddress()

        receiveSheet
            .tapShare()
            .waitForSheet()
            .verifySharedText(address)
            .dismiss(to: ReceiveTemplatesSheet.self)

        let qrCodeSheet = receiveSheet.tapShowQRCode(.segwit)
        qrCodeSheet.assertQRCodeEncodesDisplayedAddress()

        qrCodeSheet
            .verifyDisplayedAddress(address)
            .verifyCopyAndShareButtonsDisplayed()
            .tapShare()
            .waitForSheet()
            .verifySharedText(address)
            .dismiss(to: ReceiveQRCodeSheet.self)
    }
}
