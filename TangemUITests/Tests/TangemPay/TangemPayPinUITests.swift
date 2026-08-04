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
    private let currentPin = "4821"

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

    func testCurrentPinSheetOpensWhenPinIsAlreadySetOnCard() {
        setAllureId(9651)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: pinScenario, initialState: "PinSet"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapPinCode()
        .waitForSheet()
        .verifyPin(currentPin)
    }

    func testLoaderIsShownWhileCurrentPinIsLoading() {
        setAllureId(9654)

        launchAndImportHotWallet(
            scenarios: [
                ScenarioConfig(name: pinScenario, initialState: "PinSet"),
            ],
            extraLaunchEnvironment: ["UITEST_TANGEMPAY_PIN_DELAY_MS": "10000"]
        )
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapPinCode()
        .waitForSheet()
        .verifyLoadingState()
        .verifyPin(currentPin)
    }

    func testCurrentPinRemainsDisplayedAfterAppMinimizeAndMaximize() {
        setAllureId(9655)

        let pinCheckSheet = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: pinScenario, initialState: "PinSet"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapPinCode()
        .waitForSheet()
        .verifyPin(currentPin)

        minimizeApp()
        maximizeApp()

        pinCheckSheet
            .waitForSheet()
            .verifyPin(currentPin)
    }

    func testErrorToastIsShownWhenCurrentPinRequestFails() {
        setAllureId(9836)

        launchAndImportHotWallet(
            scenarios: [
                ScenarioConfig(name: pinScenario, initialState: "PinSet"),
            ],
            // The failure has to land after the sheet is presented, the way a network error does.
            extraLaunchEnvironment: [
                "UITEST_TANGEMPAY_PIN_ERROR": "1",
                "UITEST_TANGEMPAY_PIN_DELAY_MS": "1500",
            ]
        )
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapPinCode()
        .verifyErrorToastAndDismissal()
        .waitForScreen()
    }

    func testPinChangeSucceedsForCardWithPinAlreadySet() {
        setAllureId(5053)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: pinScenario, initialState: "PinSet"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapPinCode()
        .waitForSheet()
        .verifyPin(currentPin)
        .tapChangePin()
        .waitForPinEntryScreen()
        .enterPin(validPin)
        .verifySuccessContent()
        .tapDone()
        .waitForScreen()
    }
}
