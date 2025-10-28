//
//  SendFeeSelectorScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendFeeSelectorScreen: ScreenBase<SendFeeSelectorElement> {
    private lazy var slowOption = button(.slowOption)
    private lazy var marketOption = button(.marketOption)
    private lazy var fastOption = button(.fastOption)
    private lazy var customOption = button(.customOption)
    private lazy var customOptionTextFields = app.textFields.matching(identifier: FeeAccessibilityIdentifiers.customFeeOption)

    @discardableResult
    func selectSlow() -> Self {
        XCTContext.runActivity(named: "Select Slow fee option") { _ in
            slowOption.waitAndTap()
        }
        return self
    }

    @discardableResult
    func selectFast() -> Self {
        XCTContext.runActivity(named: "Select Fast fee option") { _ in
            fastOption.waitAndTap()
        }
        return self
    }

    @discardableResult
    func selectMarket() -> Self {
        XCTContext.runActivity(named: "Select Market fee option") { _ in
            marketOption.waitAndTap()
        }
        return self
    }

    @discardableResult
    func selectCustom() -> Self {
        XCTContext.runActivity(named: "Select Custom fee option") { _ in
            customOption.waitAndTap()
        }
        return self
    }

    @discardableResult
    func setLowCustomFee() -> Self {
        XCTContext.runActivity(named: "Set low custom fee") { _ in
            let maxFeeField = customOptionTextFields.element(boundBy: 0)

            maxFeeField.waitAndTap()
            maxFeeField.typeText(XCUIKeyboardKey.delete.rawValue)
            maxFeeField.typeText(XCUIKeyboardKey.delete.rawValue)
            maxFeeField.typeText("2")
        }
        return self
    }

    @discardableResult
    func setHighCustomFee() -> Self {
        XCTContext.runActivity(named: "Set high custom fee") { _ in
            let maxFeeField = customOptionTextFields.element(boundBy: 0)

            maxFeeField.waitAndTap()
            maxFeeField.typeText(XCUIKeyboardKey.delete.rawValue)
            maxFeeField.typeText(XCUIKeyboardKey.delete.rawValue)
            maxFeeField.typeText(XCUIKeyboardKey.delete.rawValue)
            maxFeeField.typeText("3")
        }
        return self
    }

    @discardableResult
    func tapFeeSelectorDone() -> SendScreen {
        XCTContext.runActivity(named: "Tap Done button on Fee Selector") { _ in
            let doneButton = app.buttons[FeeAccessibilityIdentifiers.feeSelectorDoneButton]
            doneButton.waitAndTap()
        }
        return SendScreen(app)
    }
}

enum SendFeeSelectorElement: String, UIElement {
    case slowOption
    case marketOption
    case fastOption
    case customOption

    var accessibilityIdentifier: String {
        switch self {
        case .slowOption:
            return FeeAccessibilityIdentifiers.slowFeeOption
        case .marketOption:
            return FeeAccessibilityIdentifiers.marketFeeOption
        case .fastOption:
            return FeeAccessibilityIdentifiers.fastFeeOption
        case .customOption:
            return FeeAccessibilityIdentifiers.customFeeOption
        }
    }
}
