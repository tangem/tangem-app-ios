//
//  TangemPayPinUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayPinUITests: BaseTestCase {
    private let pinScenario = "tangem_pay_pin_setup"
    private let validPin = "6194"

    func testPinEntryScreenOpensFromCardDetailsWhenPinIsNotSet() {
        setAllureId(9650)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: pinScenario, initialState: "PinNotSet"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapChangePin()
        .waitForPinEntryScreen()
    }

    func testPinValidationRejectsRepeatedAndSequentialDigits() {
        setAllureId(9534)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: pinScenario, initialState: "PinNotSet"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapChangePin()
        .waitForPinEntryScreen()
        .verifyNumericKeyboardDisplayed()
        .enterDigits("1111")
        .waitForValidationError()
        .deleteDigits(4)
        .verifyValidationErrorHidden()
        .enterDigits("4567")
        .waitForValidationError()
    }

    func testPinEntryScreenClosesWithoutSavingAndReturnsToCardDetails() {
        setAllureId(9579)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: pinScenario, initialState: "PinNotSet"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapChangePin()
        .waitForPinEntryScreen()
        .verifyNumericKeyboardDisplayed()
        .enterDigits("1111")
        .close()
        .waitForScreen()
    }

    func testPinSuccessScreenShowsCreatedState() {
        setAllureId(9582)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: pinScenario, initialState: "PinNotSet"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapChangePin()
        .waitForPinEntryScreen()
        .enterPin(validPin)
        .verifySuccessContent()
    }
}
