//
//  SendSwapProviderSelectorScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SendSwapProviderSelectorScreen: ScreenBase<SendSwapProviderSelectorElement> {
    // MARK: - Display

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Wait for provider selector to display") { _ in
            let predicate = NSPredicate(format: "identifier BEGINSWITH %@", "sendSwapProviderSelectorRow_")
            let firstRow = app.buttons.matching(predicate).firstMatch
            waitAndAssertTrue(firstRow, "At least one provider row should be displayed")
        }
        return self
    }

    // MARK: - Assertions

    @discardableResult
    func assertAllProvidersCEX() -> Self {
        XCTContext.runActivity(named: "Assert all providers are CEX type") { _ in
            XCTAssertTrue(waitForAllProviders(ofType: "CEX"), "All provider rows should be CEX type")
        }
        return self
    }

    @discardableResult
    func assertAllProvidersDEX() -> Self {
        XCTContext.runActivity(named: "Assert all providers are DEX type") { _ in
            XCTAssertTrue(waitForAllProviders(ofType: "DEX"), "All provider rows should be DEX type")
        }
        return self
    }

    @discardableResult
    func assertProvidersIncludeBothTypes() -> Self {
        XCTContext.runActivity(named: "Assert the default (unfiltered) list includes both CEX and DEX providers") { _ in
            let rowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "sendSwapProviderSelectorRow_")
            let rows = app.buttons.matching(rowPredicate)
            let count = rows.count
            XCTAssertGreaterThan(count, 0, "At least one provider row should exist")

            var hasCEX = false
            var hasDEX = false
            for i in 0 ..< count {
                let label = rows.element(boundBy: i).label
                hasCEX = hasCEX || label.contains("CEX")
                hasDEX = hasDEX || label.contains("DEX")
            }

            XCTAssertTrue(hasCEX, "Default provider list should include at least one CEX provider")
            XCTAssertTrue(hasDEX, "Default provider list should include at least one DEX provider")
        }
        return self
    }

    @discardableResult
    func assertBestRateBadgeExists() -> Self {
        XCTContext.runActivity(named: "Assert 'Best rate' badge exists on at least one provider") { _ in
            let badge = app.staticTexts[SendAccessibilityIdentifiers.swapProviderBestRateBadge].firstMatch
            waitAndAssertTrue(badge, "'Best rate' badge should be present on at least one provider")
        }
        return self
    }

    @discardableResult
    func assertFilterDisplayed(_ type: String) -> Self {
        XCTContext.runActivity(named: "Assert '\(type)' provider type filter is displayed") { _ in
            let chip = app.buttons[SendAccessibilityIdentifiers.swapProviderTypeFilterChip(type)].firstMatch
            waitAndAssertTrue(chip, "'\(type)' provider type filter chip should exist")
        }
        return self
    }

    @discardableResult
    func assertProviderUnavailable(name: String) -> Self {
        XCTContext.runActivity(named: "Assert provider '\(name)' is listed as not available") { _ in
            let row = providerRow(name: name)
            waitAndAssertTrue(row, "Provider row '\(name)' should exist")
            let isUnavailable = NSPredicate(format: "label CONTAINS %@", Constants.notAvailableBadge)
            let expectation = XCTNSPredicateExpectation(predicate: isUnavailable, object: row)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate),
                .completed,
                "Provider '\(name)' should be marked '\(Constants.notAvailableBadge)', but row label was '\(row.label)'"
            )
        }
        return self
    }

    @discardableResult
    func assertProviderAvailable(name: String) -> Self {
        XCTContext.runActivity(named: "Assert provider '\(name)' is listed as available") { _ in
            let row = providerRow(name: name)
            waitAndAssertTrue(row, "Provider row '\(name)' should exist")
            XCTAssertFalse(
                row.label.contains(Constants.notAvailableBadge),
                "Provider '\(name)' should be available, but row label was '\(row.label)'"
            )
        }
        return self
    }

    // MARK: - Selection

    @discardableResult
    func selectFilter(_ type: String) -> Self {
        XCTContext.runActivity(named: "Select '\(type)' provider type filter") { _ in
            let chip = app.buttons[SendAccessibilityIdentifiers.swapProviderTypeFilterChip(type)].firstMatch
            waitAndAssertTrue(chip, "'\(type)' provider type filter chip should exist")
            chip.waitAndTap()
        }
        return self
    }

    func selectNonBestProvider() -> (providerName: String, screen: SendSummaryScreen) {
        XCTContext.runActivity(named: "Select a provider that does not have 'Best rate' badge") { _ in
            let rowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "sendSwapProviderSelectorRow_")
            let rows = app.buttons.matching(rowPredicate)
            let count = rows.count
            XCTAssertGreaterThan(count, 1, "At least two providers should exist to select a non-best one")

            for i in 0 ..< count {
                let row = rows.element(boundBy: i)
                let badges = row.staticTexts.matching(identifier: SendAccessibilityIdentifiers.swapProviderBestRateBadge)
                if !badges.firstMatch.exists {
                    // Extract provider name from identifier
                    let identifier = row.identifier
                    let prefix = "sendSwapProviderSelectorRow_"
                    let providerName = String(identifier.dropFirst(prefix.count))
                    row.tap()
                    return (providerName: providerName, screen: SendSummaryScreen(app))
                }
            }

            XCTFail("Could not find a provider without 'Best rate' badge")
            return (providerName: "", screen: SendSummaryScreen(app))
        }
    }

    @discardableResult
    func selectProvider(name: String) -> SendSummaryScreen {
        XCTContext.runActivity(named: "Select provider: \(name)") { _ in
            let row = app.buttons[SendAccessibilityIdentifiers.swapProviderSelectorRow(name: name)].firstMatch
            waitAndAssertTrue(row, "Provider row '\(name)' should exist")
            row.tap()
        }
        return SendSummaryScreen(app)
    }

    @discardableResult
    func selectProviderReturningToSwap(name: String) -> SwapScreen {
        XCTContext.runActivity(named: "Select provider: \(name)") { _ in
            let row = app.buttons[SendAccessibilityIdentifiers.swapProviderSelectorRow(name: name)].firstMatch
            waitAndAssertTrue(row, "Provider row '\(name)' should exist")
            row.tap()
        }
        return SwapScreen(app)
    }

    @discardableResult
    func selectProviderAndWaitForClose(name: String) -> SwapScreen {
        XCTContext.runActivity(named: "Select provider '\(name)' and wait for the provider sheet to close") { _ in
            let row = providerRow(name: name)
            waitAndAssertTrue(row, "Provider row '\(name)' should exist")
            row.tap()
            XCTAssertTrue(row.waitForNonExistence(timeout: .robustUIUpdate), "Provider sheet should close after selecting '\(name)'")
        }
        return SwapScreen(app)
    }

    @discardableResult
    func close() -> SendSummaryScreen {
        XCTContext.runActivity(named: "Close provider selector") { _ in
            let closeButton = app.buttons[CommonUIAccessibilityIdentifiers.closeButton].firstMatch
            closeButton.waitAndTap()
        }
        return SendSummaryScreen(app)
    }

    private func providerRow(name: String) -> XCUIElement {
        app.buttons[SendAccessibilityIdentifiers.swapProviderSelectorRow(name: name)].firstMatch
    }

    private func waitForAllProviders(ofType type: String) -> Bool {
        let rowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "sendSwapProviderSelectorRow_")
        let predicate = NSPredicate { _, _ in
            let rows = self.app.buttons.matching(rowPredicate)
            let count = rows.count
            guard count > 0 else { return false }

            for i in 0 ..< count where !rows.element(boundBy: i).label.contains(type) {
                return false
            }
            return true
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        return XCTWaiter().wait(for: [expectation], timeout: .robustUIUpdate) == .completed
    }
}

enum SendSwapProviderSelectorElement: String, UIElement {
    case placeholder

    var accessibilityIdentifier: String {
        switch self {
        case .placeholder:
            return "sendSwapProviderSelectorPlaceholder"
        }
    }
}

private extension SendSwapProviderSelectorScreen {
    enum Constants {
        static let notAvailableBadge = "Not available"
    }
}
