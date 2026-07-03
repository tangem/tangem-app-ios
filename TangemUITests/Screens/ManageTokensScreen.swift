//
//  ManageTokensScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//

import XCTest
import UIKit
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
            let networkRow = app.staticTexts[ManageTokensAccessibilityIdentifiers.networkRow(networkName)]
            waitAndAssertTrue(networkRow, "Network row should exist: \(networkName)")
            networkRow.press(forDuration: duration)
            return self
        }
    }

    @discardableResult
    func seedPasteboard(_ sentinel: String) -> Self {
        XCTContext.runActivity(named: "Seed pasteboard with sentinel") { _ in
            UIPasteboard.general.string = sentinel
            return self
        }
    }

    @discardableResult
    func verifyCopiedContract(equals expected: String) -> Self {
        XCTContext.runActivity(named: "Verify copied contract equals '\(expected)'") { _ in
            // Paste inside the app: it reads the pasteboard it wrote itself (same process),
            // which avoids the cross-app system paste-permission prompt the test runner would trigger.
            waitAndAssertTrue(searchField, "Search field should exist")
            searchField.waitAndTap()
            searchField.press(forDuration: 1.0)

            let pasteMenuItem = app.menuItems["Paste"].firstMatch
            let pasteButton = app.buttons["Paste"].firstMatch
            if pasteMenuItem.waitForExistence(timeout: .shortUIUpdate) {
                pasteMenuItem.tap()
            } else {
                waitAndAssertTrue(pasteButton, "Paste option should appear")
                pasteButton.tap()
            }

            let matched = searchField.waitForValue(expected, timeout: .conditional)
            XCTAssertTrue(matched, "Search field should contain pasted contract '\(expected)' but was '\(searchField.value as? String ?? "")'")
            clearText(element: searchField)
            return self
        }
    }

    @discardableResult
    func verifyCopySuccessToast(text: String) -> Self {
        XCTContext.runActivity(named: "Verify copy success toast: \(text)") { _ in
            let toast = app.staticTexts[CommonUIAccessibilityIdentifiers.successToast].firstMatch
            waitAndAssertTrue(toast, timeout: .conditional, "Copy success toast should be displayed")
            XCTAssertEqual(toast.label, text, "Toast should show translated text '\(text)', not a raw key")
            return self
        }
    }

    @discardableResult
    func verifyNothingCopied(sentinel: String) -> Self {
        XCTContext.runActivity(named: "Verify nothing copied") { _ in
            let toast = app.staticTexts[CommonUIAccessibilityIdentifiers.successToast].firstMatch
            XCTAssertFalse(toast.waitForExistence(timeout: .shortUIUpdate), "No copy toast should appear for a network without a contract")
            XCTAssertEqual(UIPasteboard.general.string, sentinel, "Pasteboard should be unchanged for a network without a contract")
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
    func verifyFirmwareLimitationAlertAndDismiss(blockchain: String) -> Self {
        XCTContext.runActivity(named: "Verify firmware-limitation alert for \(blockchain)") { _ in
            let alert = app.alerts.firstMatch
            waitAndAssertTrue(alert, "Firmware-limitation alert should appear")
            let predicate = NSPredicate(format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@", blockchain, "firmware limitation")
            let message = alert.staticTexts.containing(predicate).firstMatch
            waitAndAssertTrue(message, "Alert should state \(blockchain) is unsupported due to firmware limitation")
            alert.buttons["OK"].waitAndTap()
            return self
        }
    }

    @discardableResult
    func verifyNetworkToggleOff(_ networkName: String) -> Self {
        XCTContext.runActivity(named: "Verify network toggle off: \(networkName)") { _ in
            let toggle = app.switches[ManageTokensAccessibilityIdentifiers.networkToggle(networkName)]
            waitAndAssertTrue(toggle, "Network toggle for \(networkName) should exist")
            let offExpectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == '0'"), object: toggle)
            let result = XCTWaiter().wait(for: [offExpectation], timeout: .conditional)
            XCTAssertEqual(result, .completed, "Network toggle '\(networkName)' should revert to off")
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
