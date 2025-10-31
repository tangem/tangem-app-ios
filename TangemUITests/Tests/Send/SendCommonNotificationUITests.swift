//
//  SendCommonNotificationUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendCommonNotificationUITests: BaseTestCase {
    private let ethTokenName = "Ethereum"
    private let destination = "0x24298f15b837E5851925E18439490859e0c1F1ee"

    override func setUp() {
        super.setUp()

        launchApp(tangemApiType: .mock)

        StoriesScreen(app)
            .scanMockWallet(name: .wallet2)
            .tapToken(ethTokenName)
            .tapSendButton()
            .waitForDisplay()
    }

    func testNotificationDisplayed_WhenCustomFeeLowerThanSlow() {
        setAllureId(4293)

        SendScreen(app)
            .enterAmount("0.01")
            .tapNextButton()
            .enterDestination(destination)
            .tapNextButton()
            .tapFeeBlock()
            .selectCustom()
            .setLowCustomFee()
            .tapFeeSelectorDone()
            .waitForCustomFeeTooLowBanner()
            .waitForSendButtonEnabled()
    }

    func testNotificationDisplayed_WhenTotalExceedsBalance() {
        setAllureId(4221)

        SendScreen(app)
            .enterAmount("0.9999")
            .tapNextButton()
            .enterDestination(destination)
            .tapNextButton()
            .waitForFeeWillBeSubtractFromSendingAmountBanner()
            .waitForSendButtonEnabled()
    }

    func testNotificationDisplayed_WhenCustomFeeIsHigh() {
        setAllureId(4294)

        SendScreen(app)
            .enterAmount("0.01")
            .tapNextButton()
            .enterDestination(destination)
            .tapNextButton()
            .tapFeeBlock()
            .selectCustom()
            .setHighCustomFee()
            .tapFeeSelectorDone()
            .waitForCustomFeeTooHighBanner()
            .waitForSendButtonEnabled()
    }
}
