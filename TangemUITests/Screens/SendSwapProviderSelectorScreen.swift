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
            let rowPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "sendSwapProviderSelectorRow_")
            let rows = app.buttons.matching(rowPredicate)
            let count = rows.count
            XCTAssertGreaterThan(count, 0, "At least one provider row should exist")

            for i in 0 ..< count {
                let row = rows.element(boundBy: i)
                let label = row.label
                XCTAssertTrue(
                    label.contains("CEX"),
                    "Provider row \(i) should contain 'CEX' type but label was '\(label)'"
                )
            }
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

    // MARK: - Selection

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
    func close() -> SendSummaryScreen {
        XCTContext.runActivity(named: "Close provider selector") { _ in
            let closeButton = app.buttons[CommonUIAccessibilityIdentifiers.closeButton].firstMatch
            closeButton.waitAndTap()
        }
        return SendSummaryScreen(app)
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
