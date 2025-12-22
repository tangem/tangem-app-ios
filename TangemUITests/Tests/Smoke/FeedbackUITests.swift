//
//  FeedbackUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import XCTest

final class FeedbackUITests: BaseTestCase {
    func testRequestSupportFromScanOnAppLaunch_SupportEmailOpened() throws {
        setAllureId(892)
        launchApp()

        CreateWalletSelectorScreen(app)
            .skipStories()
            .openScanMenu()
            .cancelScan()
            .openScanMenu()
            .cancelScan()

        TroubleShootSheet(app)
            .requestSupport()
            .validateMailOpened()
    }

    func testRequestSupportFromDetails_SupportEmailOpened() throws {
        setAllureId(3960)

        try XCTSkipIf(true, "Testcase is waiting for QA review dut to business logic change.")

        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .tapAddNewWallet()
            .cancelScan()
            .tapAddNewWallet()
            .cancelScan()

        TroubleShootSheet(app)
            .requestSupport()
            .validateMailOpened()
    }

    func testRequestSupportFromSend_SupportEmailOpened() throws {
        setAllureId(893)

        let token = "Polygon"
        let sendAmount = "10"
        let destinationAddress = "0x24298f15b837E5851925E18439490859e0c1F1ee"

        launchApp(tangemApiType: .mock)

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(token)
            .tapActionButton(.send)

        SendScreen(app)
            .enterAmount(sendAmount)
            .tapNextButton()
            .enterDestination(destinationAddress)
            .tapNextButton()
            .tapSendButton()

        TroubleShootSheet(app)
            .requestSupport()
            .validateMailOpened()
    }

    func testContactSupportFromDetails_SupportEmailOpened() throws {
        setAllureId(894)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .contactSupport()
            .validateMailOpened()
    }
}
