//
//  WalletRenameAlert.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import Foundation

final class WalletRenameAlert: ScreenBase<WalletRenameAlertElement> {
    private var alert: XCUIElement { app.alerts.firstMatch }
    private var nameTextField: XCUIElement { alert.textFields.firstMatch }
    private var saveButton: XCUIElement { alert.buttons["OK"].firstMatch }
    private var cancelButton: XCUIElement { alert.buttons["Cancel"].firstMatch }

    @discardableResult
    func clearName() -> Self {
        XCTContext.runActivity(named: "Clear wallet name field") { _ in
            waitAndAssertTrue(nameTextField, "Rename text field should be visible in alert")
            clearText(element: nameTextField)
            return self
        }
    }

    @discardableResult
    func enterName(_ name: String) -> Self {
        XCTContext.runActivity(named: "Enter new wallet name: \(name)") { _ in
            waitAndAssertTrue(nameTextField, "Rename text field should be visible in alert")
            nameTextField.typeText(name)
            return self
        }
    }

    @discardableResult
    func save() -> CardSettingsScreen {
        XCTContext.runActivity(named: "Tap OK to save wallet name") { _ in
            waitAndAssertTrue(saveButton, "OK button should be visible in rename alert")
            saveButton.waitAndTap()
            return CardSettingsScreen(app)
        }
    }

    @discardableResult
    func cancel() -> CardSettingsScreen {
        XCTContext.runActivity(named: "Tap Cancel in rename alert") { _ in
            cancelButton.waitAndTap()
            return CardSettingsScreen(app)
        }
    }
}

enum WalletRenameAlertElement: String, UIElement {
    case unused

    var accessibilityIdentifier: String { rawValue }
}
