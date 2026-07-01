//
//  ManageTokensScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//

import XCTest
import TangemAccessibilityIdentifiers

final class ManageTokensScreen: ScreenBase<ManageTokensScreenElement> {
    private lazy var saveButton = button(.saveButton)
    private lazy var searchField = textField(.searchField)
    private lazy var addCustomTokenButton = app.buttons[CommonUIAccessibilityIdentifiers.addButton].firstMatch

    @discardableResult
    func expandTokenIfNeeded(coinId: String) -> Self {
        XCTContext.runActivity(named: "Expand token if needed: \(coinId)") { _ in
            let identifier = ManageTokensAccessibilityIdentifiers.coinRow(coinId)
            let coinRow = app.staticTexts[identifier]
            waitAndAssertTrue(coinRow, "Coin row should exist: \(coinId)")
            coinRow.waitAndTap()
            return self
        }
    }

    @discardableResult
    func ensureNetworkSelected(_ networkName: String) -> Self {
        XCTContext.runActivity(named: "Ensure network selected: \(networkName)") { _ in
            let networkText = app.staticTexts[networkName]
            waitAndAssertTrue(networkText, "Network row should exist: \(networkName)")

            let toggleIdentifier = ManageTokensAccessibilityIdentifiers.networkToggle(networkName)
            let toggle = app.switches[toggleIdentifier]
            waitAndAssertTrue(toggle, "Network toggle \(toggleIdentifier) should exist")

            if (toggle.value as? String) == "0" {
                toggle.waitAndTap()
            }

            return self
        }
    }

    @discardableResult
    func longPressNetworkToCopy(_ networkName: String, duration: TimeInterval = 1.0) -> Self {
        XCTContext.runActivity(named: "Long press \(networkName) to copy") { _ in
            let networkText = app.staticTexts[networkName]
            waitAndAssertTrue(networkText, "Network row should exist: \(networkName)")
            networkText.press(forDuration: duration)
            return self
        }
    }

    @discardableResult
    func toggleOffNetwork(_ networkName: String) -> Self {
        XCTContext.runActivity(named: "Toggle off network: \(networkName)") { _ in
            let toggleIdentifier = ManageTokensAccessibilityIdentifiers.networkToggle(networkName)
            let toggle = app.switches[toggleIdentifier]
            waitAndAssertTrue(toggle, "Network toggle \(toggleIdentifier) should exist")

            XCTAssertEqual(toggle.value as? String, "1", "Network toggle '\(networkName)' should be ON before toggling off")
            toggle.waitAndTap()

            return self
        }
    }

    @discardableResult
    func confirmHideTokenAlert(tokenName: String) -> Self {
        XCTContext.runActivity(named: "Confirm hide token alert for: \(tokenName)") { _ in
            let alert = app.alerts["Hide \(tokenName)"]
            waitAndAssertTrue(alert, "Hide token alert should appear for '\(tokenName)'")
            alert.buttons["Hide"].waitAndTap()
            return self
        }
    }

    @discardableResult
    func tapSaveButton() -> Self {
        XCTContext.runActivity(named: "Tap Save button") { _ in
            waitAndAssertTrue(saveButton, "Save button should exist")
            saveButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return self
        }
    }

    @discardableResult
    func search(_ query: String) -> Self {
        XCTContext.runActivity(named: "Search for: \(query)") { _ in
            waitAndAssertTrue(searchField, "Search field should exist")
            searchField.waitAndTap()
            typeReliably(element: searchField, text: query)
            return self
        }
    }

    @discardableResult
    func clearSearch() -> Self {
        XCTContext.runActivity(named: "Clear search field") { _ in
            waitAndAssertTrue(searchField, "Search field should exist")
            clearText(element: searchField)
            return self
        }
    }

    @discardableResult
    func verifyTokenRowExists(coinId: String) -> Self {
        XCTContext.runActivity(named: "Verify token row exists: \(coinId)") { _ in
            let row = app.staticTexts[ManageTokensAccessibilityIdentifiers.coinRow(coinId)]
            waitAndAssertTrue(row, "Token row should exist: \(coinId)")
            return self
        }
    }

    @discardableResult
    func verifyTokenRowNotExists(coinId: String) -> Self {
        XCTContext.runActivity(named: "Verify token row absent: \(coinId)") { _ in
            let row = app.staticTexts[ManageTokensAccessibilityIdentifiers.coinRow(coinId)]
            let absence = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: row)
            let result = XCTWaiter().wait(for: [absence], timeout: .conditional)
            XCTAssertEqual(result, .completed, "Token row should become absent: \(coinId)")
            return self
        }
    }

    @discardableResult
    func verifyNetworkStandard(network: String, standard: String) -> Self {
        XCTContext.runActivity(named: "Verify \(network) standard is \(standard)") { _ in
            let label = app.staticTexts[ManageTokensAccessibilityIdentifiers.networkStandardLabel(network)]
            waitAndAssertTrue(label, "Standard label for \(network) should exist")
            XCTAssertEqual(label.label, standard, "\(network) standard should be \(standard)")
            return self
        }
    }

    @discardableResult
    func toggleNetwork(_ networkName: String) -> Self {
        XCTContext.runActivity(named: "Toggle network: \(networkName)") { _ in
            let toggle = app.switches[ManageTokensAccessibilityIdentifiers.networkToggle(networkName)]
            waitAndAssertTrue(toggle, "Network toggle for \(networkName) should exist")
            toggle.waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyNoAlertShown() -> Self {
        XCTContext.runActivity(named: "Verify no alert shown") { _ in
            XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: .shortUIUpdate), "No alert should appear")
            return self
        }
    }

    func openAddCustomToken() -> AddCustomTokenScreen {
        XCTContext.runActivity(named: "Open Add Custom Token") { _ in
            waitAndAssertTrue(addCustomTokenButton, "Add custom token button should exist")
            addCustomTokenButton.waitAndTap()
            return AddCustomTokenScreen(app)
        }
    }

    func goBackToAccountSettings() -> AccountSettingsScreen {
        XCTContext.runActivity(named: "Go back to Account settings") { _ in
            app.navigationBars.buttons["Account"].waitAndTap()
            return AccountSettingsScreen(app)
        }
    }

    func goBackToWalletSettings() -> CardSettingsScreen {
        XCTContext.runActivity(named: "Go back to Wallet settings") { _ in
            app.navigationBars.buttons["Wallet settings"].waitAndTap()
            return CardSettingsScreen(app)
        }
    }
}

enum ManageTokensScreenElement: String, UIElement {
    case saveButton
    case searchField

    var accessibilityIdentifier: String {
        switch self {
        case .saveButton:
            return ManageTokensAccessibilityIdentifiers.saveButton
        case .searchField:
            return ManageTokensAccessibilityIdentifiers.searchField
        }
    }
}
