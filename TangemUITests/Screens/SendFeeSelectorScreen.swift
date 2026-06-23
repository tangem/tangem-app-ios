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

    // MARK: - Bitcoin Custom Fee Fields

    private lazy var maxFeeField = app.textFields[FeeAccessibilityIdentifiers.customFeeMaxFeeField]
    private lazy var satoshiPerByteField = app.textFields[FeeAccessibilityIdentifiers.customFeeSatoshiPerByteField]
    private lazy var nonceField = app.textFields[FeeAccessibilityIdentifiers.customFeeNonceField]
    private lazy var feeUpToField = app.textFields[FeeAccessibilityIdentifiers.customFeeTotalAmountField]

    @discardableResult
    func waitForDisplay(cryptoSymbol: String, fiatSymbol: String, includeCustom: Bool = true) -> Self {
        XCTContext.runActivity(named: "Validate fee selector options are displayed") { _ in
            waitForFeeOption(
                slowOption,
                optionName: "Slow",
                cryptoSymbol: cryptoSymbol,
                fiatSymbol: fiatSymbol
            )
            waitForFeeOption(
                marketOption,
                optionName: "Market",
                cryptoSymbol: cryptoSymbol,
                fiatSymbol: fiatSymbol
            )
            waitForFeeOption(
                fastOption,
                optionName: "Fast",
                cryptoSymbol: cryptoSymbol,
                fiatSymbol: fiatSymbol
            )
            if includeCustom {
                waitForFeeOption(
                    customOption,
                    optionName: "Custom",
                    cryptoSymbol: cryptoSymbol,
                    fiatSymbol: fiatSymbol
                )
            }
        }
        return self
    }

    @discardableResult
    func waitForSwapFeeOptions(cryptoSymbol: String, fiatSymbol: String) -> Self {
        XCTContext.runActivity(named: "Validate swap fee options (Market + Fast only)") { _ in
            waitForFeeOption(
                marketOption,
                optionName: "Market",
                cryptoSymbol: cryptoSymbol,
                fiatSymbol: fiatSymbol
            )
            waitForFeeOption(
                fastOption,
                optionName: "Fast",
                cryptoSymbol: cryptoSymbol,
                fiatSymbol: fiatSymbol
            )

            XCTAssertFalse(
                slowOption.waitForExistence(timeout: .quick),
                "Slow fee option should NOT exist for swap transactions"
            )
            XCTAssertFalse(
                customOption.waitForExistence(timeout: .quick),
                "Custom fee option should NOT exist for swap transactions"
            )
        }
        return self
    }

    @discardableResult
    func selectSlow() -> Self {
        XCTContext.runActivity(named: "Select Slow fee option") { _ in
            slowOption.waitAndTap()
        }
        return self
    }

    @discardableResult
    func selectFast() -> SendSummaryScreen {
        XCTContext.runActivity(named: "Select Fast fee option") { _ in
            fastOption.waitAndTap()
        }
        return SendSummaryScreen(app)
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
            waitAndAssertTrue(feeUpToField, "Fee up to field should exist")
            feeUpToField.waitAndTap()
            feeUpToField.typeText(XCUIKeyboardKey.delete.rawValue)
            feeUpToField.typeText(XCUIKeyboardKey.delete.rawValue)
            feeUpToField.typeText("2")
        }
        return self
    }

    @discardableResult
    func setHighCustomFee() -> Self {
        XCTContext.runActivity(named: "Set high custom fee") { _ in
            waitAndAssertTrue(feeUpToField, "Fee up to field should exist")
            feeUpToField.waitAndTap()
            feeUpToField.typeText(XCUIKeyboardKey.delete.rawValue)
            feeUpToField.typeText(XCUIKeyboardKey.delete.rawValue)
            feeUpToField.typeText(XCUIKeyboardKey.delete.rawValue)
            feeUpToField.typeText("3")
        }
        return self
    }

    @discardableResult
    func waitForCustomFields() -> Self {
        XCTContext.runActivity(named: "Validate custom fee fields are displayed") { _ in
            CustomField.allCases.forEach { field in
                let titleElement = app.staticTexts[field.description]
                waitAndAssertTrue(titleElement, "Field title '\(field.description)' should exist")
            }

            waitAndAssertTrue(nonceField, "Custom fee should expose text fields for every title")
        }
        return self
    }

    @discardableResult
    func tapFeeSelectorDone() -> SendScreen {
        XCTContext.runActivity(named: "Tap Done button on Fee Selector") { _ in
            let doneButton = app.buttons[FeeAccessibilityIdentifiers.feeSelectorDoneButton]
            doneButton.waitAndTapWithScroll()
        }
        return SendScreen(app)
    }

    // MARK: - Bitcoin Custom Fee Methods

    @discardableResult
    func waitForBitcoinCustomFields() -> Self {
        XCTContext.runActivity(named: "Validate Bitcoin custom fee fields are displayed") { _ in
            waitAndAssertTrue(maxFeeField, "Max Fee field should exist")
            waitAndAssertTrue(satoshiPerByteField, "Satoshi per vbyte field should exist")
        }
        return self
    }

    @discardableResult
    func waitForBitcoinCustomFieldsPrefilled() -> Self {
        XCTContext.runActivity(named: "Validate Bitcoin custom fee fields are prefilled with Market values") { _ in
            waitAndAssertTrue(maxFeeField, "Max Fee text field should exist")
            let maxFeeValue = (maxFeeField.value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            XCTAssertFalse(maxFeeValue.isEmpty, "Max Fee value should not be empty")

            waitAndAssertTrue(satoshiPerByteField, "Satoshi per vbyte text field should exist")
            let satoshiValue = (satoshiPerByteField.value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            XCTAssertFalse(satoshiValue.isEmpty, "Satoshi per vbyte value should not be empty")
        }
        return self
    }

    @discardableResult
    func verifyMaxFeeFieldNotEditable() -> Self {
        XCTContext.runActivity(named: "Verify Max Fee field is not editable") { _ in
            waitAndAssertTrue(maxFeeField, "Max Fee text field should exist")
            XCTAssertFalse(maxFeeField.isEnabled, "Max Fee field should not be editable")
        }
        return self
    }

    @discardableResult
    func verifySatoshiPerByteFieldEditable() -> Self {
        XCTContext.runActivity(named: "Verify Satoshi per vbyte field is editable") { _ in
            waitAndAssertTrue(satoshiPerByteField, "Satoshi per vbyte text field should exist")
            XCTAssertTrue(satoshiPerByteField.isEnabled, "Satoshi per vbyte field should be editable")
        }
        return self
    }

    @discardableResult
    func enterSatoshiPerByte(_ value: String) -> Self {
        XCTContext.runActivity(named: "Enter Satoshi per vbyte value: \(value)") { _ in
            waitAndAssertTrue(satoshiPerByteField, "Satoshi per vbyte text field should exist")
            satoshiPerByteField.waitAndTap()
            clearText(element: satoshiPerByteField)
            satoshiPerByteField.typeText(value)
        }
        return self
    }

    func getMaxFeeFiatValue() -> String {
        XCTContext.runActivity(named: "Get Max Fee fiat value displayed right of Fee up to field") { _ in
            waitAndAssertTrue(maxFeeField, "Max Fee text field should exist")

            let fiatValueElement = app.staticTexts[FeeAccessibilityIdentifiers.customFeeMaxFeeFiatValue]
            waitAndAssertTrue(fiatValueElement, "Max Fee fiat value element should exist")

            return fiatValueElement.label.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    @discardableResult
    func verifyCustomOptionSelected() -> Self {
        XCTContext.runActivity(named: "Verify Custom option is selected and highlighted") { _ in
            waitAndAssertTrue(customOption, "Custom option should exist")
        }
        return self
    }

    private func waitForFeeOption(
        _ option: XCUIElement,
        optionName: String,
        cryptoSymbol: String,
        fiatSymbol: String
    ) {
        waitAndAssertTrue(option, "\(optionName) fee option should exist")
        let label = option.label
        XCTAssertTrue(
            label.contains(cryptoSymbol),
            "\(optionName) fee option should display \(cryptoSymbol) amount"
        )
        XCTAssertTrue(
            label.contains(fiatSymbol),
            "\(optionName) fee option should display \(fiatSymbol) amount"
        )
    }
}

// MARK: - Gasless (fee token selection)

extension SendFeeSelectorScreen {
    private func feeTokenRow(symbol: String) -> XCUIElement {
        app.buttons[FeeAccessibilityIdentifiers.feeCurrencyOption(symbol: symbol)].firstMatch
    }

    private var applyButton: XCUIElement {
        app.buttons[FeeAccessibilityIdentifiers.feeSelectorApplyButton].firstMatch
    }

    @discardableResult
    func waitForNetworkFeeSheet() -> Self {
        XCTContext.runActivity(named: "Validate 'Network fee' sheet is displayed") { _ in
            let title = app.staticTexts[FeeAccessibilityIdentifiers.feeSelectorNetworkFeeTitle].firstMatch
            waitAndAssertTrue(title, "'Network fee' sheet title should be displayed")
        }
        return self
    }

    @discardableResult
    func openTokenSelector(fromCoinSymbol coinSymbol: String) -> Self {
        XCTContext.runActivity(named: "Open fee token selector via '\(coinSymbol)' row") { _ in
            feeTokenRow(symbol: coinSymbol).waitAndTap()
        }
        return self
    }

    @discardableResult
    func waitForChooseTokenSheet() -> Self {
        XCTContext.runActivity(named: "Validate 'Choose token' sheet is displayed") { _ in
            let title = app.staticTexts[FeeAccessibilityIdentifiers.feeSelectorChooseTokenTitle].firstMatch
            waitAndAssertTrue(title, "'Choose token' sheet title should be displayed")
        }
        return self
    }

    @discardableResult
    func assertFeeTokenAvailable(symbol: String) -> Self {
        XCTContext.runActivity(named: "Assert fee token '\(symbol)' is available") { _ in
            waitAndAssertTrue(feeTokenRow(symbol: symbol), "Fee token '\(symbol)' should be available for the fee payment")
        }
        return self
    }

    @discardableResult
    func selectFeeToken(symbol: String) -> Self {
        XCTContext.runActivity(named: "Select fee token '\(symbol)'") { _ in
            feeTokenRow(symbol: symbol).waitAndTap()
        }
        return self
    }

    @discardableResult
    func selectStablecoinAsFeeToken(coinSymbol: String, tokenSymbol: String) -> Self {
        openTokenSelector(fromCoinSymbol: coinSymbol)
        waitForChooseTokenSheet()
        selectFeeToken(symbol: tokenSymbol)
        return self
    }

    @discardableResult
    func tapApply() -> SendSummaryScreen {
        XCTContext.runActivity(named: "Tap 'Apply' button on fee selector") { _ in
            applyButton.waitAndTap()
        }
        return SendSummaryScreen(app)
    }

    @discardableResult
    func assertApplyDisabled() -> Self {
        XCTContext.runActivity(named: "Assert 'Apply' button is disabled") { _ in
            waitAndAssertTrue(applyButton, "'Apply' button should exist")
            XCTAssertFalse(applyButton.isEnabled, "'Apply' button should be disabled with insufficient balance")
        }
        return self
    }

    @discardableResult
    func assertNotEnoughFundsError() -> Self {
        XCTContext.runActivity(named: "Assert 'Not enough funds' error is displayed") { _ in
            let error = app.staticTexts[FeeAccessibilityIdentifiers.feeSelectorInsufficientFundsError].firstMatch
            waitAndAssertTrue(error, "'Not enough funds' error should be displayed in the fee selector")
        }
        return self
    }

    @discardableResult
    func assertOnlyMarketSpeedForStablecoin() -> Self {
        XCTContext.runActivity(named: "Assert only Market speed is available for the stablecoin fee") { _ in
            let feeRow = app.buttons[FeeAccessibilityIdentifiers.feeSelectorSummaryFee].firstMatch
            waitAndAssertTrue(feeRow, "Summary fee row should exist")

            feeRow.tap()
            let chooseSpeedTitle = app.staticTexts[FeeAccessibilityIdentifiers.feeSelectorChooseSpeedTitle].firstMatch
            XCTAssertTrue(
                chooseSpeedTitle.waitForNonExistence(timeout: .robustUIUpdate),
                "'Choose speed' sheet should not open for a stablecoin fee"
            )
            XCTAssertFalse(fastOption.waitForExistence(timeout: .quick), "Fast speed should not be available for a stablecoin fee")
            XCTAssertFalse(slowOption.waitForExistence(timeout: .quick), "Slow speed should not be available for a stablecoin fee")
        }
        return self
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

enum CustomField: Int, CaseIterable {
    case totalFeeAmount = 0
    case maxFeePerGas
    case priorityFee
    case gasLimit
    case nonce

    var description: String {
        switch self {
        case .totalFeeAmount:
            return "Fee up to"
        case .maxFeePerGas:
            return "Max fee"
        case .priorityFee:
            return "Priority fee"
        case .gasLimit:
            return "Gas limit"
        case .nonce:
            return "Nonce"
        }
    }
}
