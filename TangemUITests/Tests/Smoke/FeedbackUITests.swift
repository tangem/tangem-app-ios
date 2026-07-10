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
    func testRequestSupportFromScanOnAppLaunch_ContactSupportSheetShown() throws {
        setAllureId(3985)
        launchApp()

        CreateWalletSelectorScreen(app)
            .skipStories()
            .openScanMenu()
            .cancelScan()
            .openScanMenu()
            .cancelScan()

        TroubleShootSheet(app)
            .requestSupport()
            .validateFallbackSheet()
    }

    func testRequestSupportFromDetails_ContactSupportSheetShown() throws {
        setAllureId(3960)

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
            .validateFallbackSheet()
    }

    func testRequestSupportFromSend_ContactSupportSheetShown() throws {
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
            .validateFallbackSheet()
    }

    func testContactSupportFromDetails_ContactSupportSheetShown() throws {
        setAllureId(894)
        launchApp()

        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .wallet2)
            .openDetails()
            .contactSupport()
            .validateFallbackSheet()
    }
    
    func testContactSupportForS2C() throws {
        setAllureId(3603)
        launchApp()
        
        CreateWalletSelectorScreen(app)
            .scanMockWallet(name: .s2c)
            .openDetails()
            .assertContactSupportButtonExists()
    }
}
