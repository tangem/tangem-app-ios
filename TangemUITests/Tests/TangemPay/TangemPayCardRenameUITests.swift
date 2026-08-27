//
//  TangemPayCardRenameUITests.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayCardRenameUITests: BaseTestCase {
    private let renameScenario = "tangem_pay_card_rename"
    private let newCardName = "Renamed Card"
    private let initialCardName = "My Card"

    func testSuccessfulCardRename() {
        setAllureId(9711)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: renameScenario, initialState: "Started"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapCardName()
        .waitForScreen()
        .clearAndEnterName(newCardName)
        .submitExpectingSuccess()
        .verifyCardName(contains: newCardName)
    }

    func testInvalidCharactersOnCardRename() {
        setAllureId(9712)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: renameScenario, initialState: "Started"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapCardName()
        .waitForScreen()
        .clearAndEnterName("   ")
        .verifyDoneDisabled()
        .clearName()
        .verifyDoneDisabled()
        .clearAndEnterName("AaBbCcDdEeFfGgHhIiJjK")
        .verifyDoneDisabled()
        .clearAndEnterName("abc$")
        .submitExpectingInvalidCharacters()
        .clearAndEnterName("😀")
        .submitExpectingInvalidCharacters()
    }

    func testBackendErrorOnCardRename() {
        setAllureId(9713)

        launchAndImportHotWallet(scenarios: [
            ScenarioConfig(name: renameScenario, initialState: "RenameError"),
        ])
        .openTangemPay()
        .waitForScreen()
        .tapCard()
        .waitForScreen()
        .tapCardName()
        .waitForScreen()
        .clearAndEnterName(newCardName)
        .submitExpectingBackendError()
        .close()
        .verifyCardName(contains: initialCardName)
    }
}
