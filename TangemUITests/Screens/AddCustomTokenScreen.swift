//
//  AddCustomTokenScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class AddCustomTokenScreen: ScreenBase<AddCustomTokenScreenElement> {
    private lazy var contractAddressField = textField(.contractAddressField)
    private lazy var derivationSelectorRow = button(.derivationSelectorRow)
    private lazy var addButton = button(.addButton)

    @discardableResult
    func selectNetwork(_ networkName: String) -> Self {
        XCTContext.runActivity(named: "Select network: \(networkName)") { _ in
            let row = element(withIdentifier: AddCustomTokenAccessibilityIdentifiers.networkRow(networkName))
            scrollToElement(row, attempts: .lazy)
            waitAndAssertTrue(row, "Network row should exist: \(networkName)")
            row.waitAndTap()
            return self
        }
    }

    @discardableResult
    func enterContractAddress(_ address: String) -> Self {
        XCTContext.runActivity(named: "Enter contract address") { _ in
            waitAndAssertTrue(contractAddressField, "Contract address field should exist")
            contractAddressField.waitAndTap()
            typeReliably(element: contractAddressField, text: address)
            dismissKeyboardAccessory()
            return self
        }
    }

    @discardableResult
    func verifyDerivationFieldEnabled() -> Self {
        XCTContext.runActivity(named: "Verify derivation field enabled") { _ in
            waitAndAssertTrue(derivationSelectorRow, "Derivation selector row should exist")
            XCTAssertTrue(derivationSelectorRow.isEnabled, "Derivation selector should be enabled")
            return self
        }
    }

    @discardableResult
    func openDerivationSelector() -> Self {
        XCTContext.runActivity(named: "Open derivation selector") { _ in
            waitAndAssertTrue(derivationSelectorRow, "Derivation selector row should exist")
            derivationSelectorRow.waitAndTap()
            return self
        }
    }

    @discardableResult
    func chooseCustomDerivation() -> Self {
        XCTContext.runActivity(named: "Choose custom derivation option") { _ in
            let option = element(withIdentifier: AddCustomTokenAccessibilityIdentifiers.derivationOptionRow("custom"))
            scrollToElement(option)
            waitAndAssertTrue(option, "Custom derivation option should exist")
            option.waitAndTap()
            return self
        }
    }

    @discardableResult
    func enterCustomDerivationPath(_ path: String) -> Self {
        XCTContext.runActivity(named: "Enter custom derivation path: \(path)") { _ in
            let field = app.textFields[AddCustomTokenAccessibilityIdentifiers.derivationPathField]
            waitAndAssertTrue(field, "Derivation path field should exist")
            field.waitAndTap()
            typeReliably(element: field, text: path)
            let saveButton = app.buttons[AddCustomTokenAccessibilityIdentifiers.derivationPathSaveButton]
            waitAndAssertTrue(saveButton, "Derivation path save button should exist")
            saveButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapAddToken() -> Self {
        XCTContext.runActivity(named: "Tap Add Token") { _ in
            waitAndAssertTrue(addButton, "Add token button should exist")
            addButton.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyNoUnsupportedTokenWarning() -> Self {
        XCTContext.runActivity(named: "Verify no unsupported-token warning") { _ in
            let warning = element(withIdentifier: AddCustomTokenAccessibilityIdentifiers.warningNotification)
            XCTAssertFalse(warning.waitForExistence(timeout: .shortUIUpdate), "No warning should appear")
            return self
        }
    }

    @discardableResult
    func verifyUnsupportedCurveAlert(blockchain: String) -> Self {
        XCTContext.runActivity(named: "Verify unsupported-curve alert for \(blockchain)") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Unsupported-curve alert should appear")
            let predicate = NSPredicate(format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@", blockchain, "reset the wallet")
            let message = alert.staticTexts.containing(predicate).firstMatch
            waitAndAssertTrue(message, "Alert should state \(blockchain) needs the wallet to be recreated")
            return self
        }
    }

    @discardableResult
    func verifyFirmwareLimitationAlert(blockchain: String) -> Self {
        XCTContext.runActivity(named: "Verify firmware-limitation alert for \(blockchain)") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Firmware-limitation alert should appear")
            let predicate = NSPredicate(format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@", blockchain, "firmware limitation")
            let message = alert.staticTexts.containing(predicate).firstMatch
            waitAndAssertTrue(message, "Alert should state \(blockchain) is unsupported due to firmware limitation")
            return self
        }
    }

    @discardableResult
    func verifyDerivationOptionPath(option: String, expectedPath: String) -> Self {
        XCTContext.runActivity(named: "Verify \(option) derivation path is \(expectedPath)") { _ in
            let identifier = AddCustomTokenAccessibilityIdentifiers.derivationOptionRow(option)
            let predicate = NSPredicate(format: "identifier == %@ AND label BEGINSWITH %@", identifier, "m/")
            let pathText = app.staticTexts.matching(predicate).firstMatch
            scrollToElement(pathText, attempts: .lazy)
            waitAndAssertTrue(pathText, "Derivation path for \(option) should exist")
            XCTAssertEqual(pathText.label, expectedPath, "\(option) derivation path should be \(expectedPath)")
            return self
        }
    }

    private func element(withIdentifier identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func dismissKeyboardAccessory() {
        let toolbar = app.toolbars.firstMatch
        let dismissButton = toolbar.buttons[CommonUIAccessibilityIdentifiers.hideKeyboardButton]
        if dismissButton.waitForExistence(timeout: .quick) {
            dismissButton.tap()
        } else if toolbar.buttons.firstMatch.exists {
            toolbar.buttons.firstMatch.tap()
        }
    }
}

enum AddCustomTokenScreenElement: String, UIElement {
    case contractAddressField
    case derivationSelectorRow
    case addButton

    var accessibilityIdentifier: String {
        switch self {
        case .contractAddressField:
            return AddCustomTokenAccessibilityIdentifiers.contractAddressField
        case .derivationSelectorRow:
            return AddCustomTokenAccessibilityIdentifiers.derivationSelectorRow
        case .addButton:
            return AddCustomTokenAccessibilityIdentifiers.addButton
        }
    }
}
