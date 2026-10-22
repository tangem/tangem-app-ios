//
//  TangemPayGeoSelectionScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayGeoSelectionScreen: Screen {
    let app: XCUIApplication

    private lazy var closeButton = app.buttons[CommonUIAccessibilityIdentifiers.closeButton].firstMatch
    private lazy var searchEmptyState = app.staticTexts[Localization.tangempayResidencySearchEmpty].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForScreen(title: String) -> Self {
        XCTContext.runActivity(named: "Wait for '\(title)' selection screen") { _ in
            waitAndAssertTrue(app.staticTexts[title].firstMatch, timeout: .networkRequest, "'\(title)' screen should be displayed")
            return self
        }
    }

    @discardableResult
    func selectRow(_ title: String) -> Self {
        XCTContext.runActivity(named: "Select '\(title)'") { _ in
            row(title).waitAndTap(timeout: .networkRequest)
            return self
        }
    }

    @discardableResult
    func selectRowExpectingUnavailableRegion(_ title: String) -> TangemPayUnavailableRegionScreen {
        XCTContext.runActivity(named: "Select '\(title)' and expect the region unavailable screen") { _ in
            row(title).waitAndTap(timeout: .networkRequest)
            return TangemPayUnavailableRegionScreen(app)
        }
    }

    @discardableResult
    func waitForClosed(title: String) -> Self {
        XCTContext.runActivity(named: "Wait for '\(title)' selection screen to close") { _ in
            XCTAssertTrue(
                app.staticTexts[title].firstMatch.waitForNonExistence(timeout: .networkRequest),
                "'\(title)' screen should close after the selection"
            )
            return self
        }
    }

    @discardableResult
    func verifySectionHeaderDisplayed(_ header: String) -> Self {
        XCTContext.runActivity(named: "Verify section '\(header)' is displayed") { _ in
            waitAndAssertTrue(app.staticTexts[header].firstMatch, timeout: .networkRequest, "Section '\(header)' should be displayed")
            return self
        }
    }

    @discardableResult
    func verifySectionHeaderNotDisplayed(_ header: String) -> Self {
        XCTContext.runActivity(named: "Verify section '\(header)' is not displayed") { _ in
            XCTAssertTrue(
                app.staticTexts[header].firstMatch.waitForNonExistence(timeout: .conditional),
                "Section '\(header)' should not be displayed"
            )
            return self
        }
    }

    @discardableResult
    func verifyRowCount(_ title: String, equals expectedCount: Int) -> Self {
        XCTContext.runActivity(named: "Verify '\(title)' is listed \(expectedCount) time(s)") { _ in
            waitAndAssertTrue(row(title), timeout: .networkRequest, "'\(title)' should be listed")
            XCTAssertEqual(rows(title).count, expectedCount, "'\(title)' should be listed \(expectedCount) time(s)")
            return self
        }
    }

    @discardableResult
    func verifyRowsDisplayed(_ titles: [String]) -> Self {
        XCTContext.runActivity(named: "Verify \(titles) are listed") { _ in
            for title in titles {
                waitAndAssertTrue(row(title), timeout: .networkRequest, "'\(title)' should be listed")
            }
            return self
        }
    }

    @discardableResult
    func verifyRowNotDisplayed(_ title: String) -> Self {
        XCTContext.runActivity(named: "Verify '\(title)' is not listed") { _ in
            XCTAssertTrue(row(title).waitForNonExistence(timeout: .conditional), "'\(title)' should not be listed")
            return self
        }
    }

    @discardableResult
    func search(_ query: String) -> Self {
        XCTContext.runActivity(named: "Search for '\(query)'") { _ in
            let field = focusedSearchField()
            field.typeText(query)
            return self
        }
    }

    @discardableResult
    func clearSearch() -> Self {
        XCTContext.runActivity(named: "Clear the search query") { _ in
            let field = focusedSearchField()
            let query = field.getValue() == field.placeholderValue ? "" : field.getValue()
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: query.count))
            return self
        }
    }

    @discardableResult
    func verifySearchEmptyState() -> Self {
        XCTContext.runActivity(named: "Verify search shows no results") { _ in
            waitAndAssertTrue(searchEmptyState, timeout: .conditional, "Search zero state should be displayed")
            XCTAssertFalse(app.buttons[TangemPayAccessibilityIdentifiers.geoSelectionRow].exists, "No rows should be listed")
            return self
        }
    }

    @discardableResult
    func close<Destination: Screen>(to destination: Destination.Type) -> Destination {
        XCTContext.runActivity(named: "Close the selection screen") { _ in
            closeButton.waitAndTap()
            XCTAssertTrue(
                app.buttons[TangemPayAccessibilityIdentifiers.geoSelectionRow].firstMatch.waitForNonExistence(timeout: .robustUIUpdate),
                "Selection screen should be closed"
            )
            return Destination(app)
        }
    }

    private func focusedSearchField() -> XCUIElement {
        let field = searchField()
        let focused = NSPredicate(format: "hasKeyboardFocus == true")
        var hasFocus = field.hasFocus
        for _ in 0 ..< Constants.focusAttempts where !hasFocus {
            field.tap()
            hasFocus = XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: focused, object: field)], timeout: .shortUIUpdate) == .completed
        }
        XCTAssertTrue(hasFocus, "Search field should get keyboard focus")
        return field
    }

    private func searchField() -> XCUIElement {
        let fields: XCUIElementQuery
        if #available(iOS 26.0, *) {
            fields = app.searchFields.matching(identifier: Localization.commonSearch)
        } else {
            fields = app.textFields.matching(identifier: TangemPayAccessibilityIdentifiers.geoSelectionSearchField)
        }

        guard let field = fields.firstHittableElement() else {
            XCTFail("Search field should be displayed")
            return fields.firstMatch
        }
        return field
    }

    private func rows(_ title: String) -> XCUIElementQuery {
        app.buttons
            .matching(NSPredicate(format: "identifier == %@ AND label CONTAINS %@", TangemPayAccessibilityIdentifiers.geoSelectionRow, title))
    }

    private func row(_ title: String) -> XCUIElement {
        rows(title).firstMatch
    }
}

private extension TangemPayGeoSelectionScreen {
    enum Constants {
        static let focusAttempts = 3
    }
}
