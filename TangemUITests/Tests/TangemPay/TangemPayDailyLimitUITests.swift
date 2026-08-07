//
//  TangemPayDailyLimitUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayDailyLimitUITests: BaseTestCase {
    func testDailyLimitScreen_DisplaysCorrectly() {
        setAllureId(9726)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_daily_limit", initialState: "HighLimit"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapChangeDailyLimit()
        .waitForScreen()
        .verifyScreenDisplayed()
    }

    func testQuickValue_AppliedToAmountField() {
        setAllureId(9724)

        let dailyLimit = launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_daily_limit", initialState: "HighLimit"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapChangeDailyLimit()
        .waitForScreen()

        dailyLimit.tapPreset("5000")

        XCTAssertEqual(
            dailyLimit.readAmountDigits(),
            "5000",
            "Selected quick value should be applied to the Amount field"
        )
    }

    func testAmountValidation_SetLimitsDisabledWhenAboveLimit() {
        setAllureId(9737)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_daily_limit", initialState: "HighLimit"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapChangeDailyLimit()
        .waitForScreen()
        .clearAndEnterAmount("300000")
        .verifySetLimitsDisabled()
    }

    func testSuccessfulDailyLimitSetup() {
        setAllureId(9739)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_daily_limit", initialState: "HighLimit"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapChangeDailyLimit()
        .waitForScreen()
        .clearAndEnterAmount("5000")
        .tapSetLimits()
        .verifySuccessDisplayed()
        .tapDone()
        .verifyDailyLimitValue(contains: "5,000")
    }

    func testError_ShownWhenLimitChangeFails() {
        setAllureId(9727)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: "tangem_pay_daily_limit", initialState: "SetError"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapChangeDailyLimit()
        .waitForScreen()
        .clearAndEnterAmount("5000")
        .tapSetLimits()
        .verifyErrorAlert()
    }
}
