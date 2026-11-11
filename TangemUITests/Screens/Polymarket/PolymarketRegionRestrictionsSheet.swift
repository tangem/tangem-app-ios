//
//  PolymarketRegionRestrictionsSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import XCTest
import TangemAccessibilityIdentifiers

final class PolymarketRegionRestrictionsSheet: Screen {
    let app: XCUIApplication

    private lazy var sheet = app.descendants(matching: .any)
        .matching(identifier: PolymarketAccessibilityIdentifiers.regionRestrictionSheet)
        .firstMatch
    private lazy var title = app.staticTexts
        .matching(identifier: PolymarketAccessibilityIdentifiers.regionRestrictionSheet)
        .matching(NSPredicate(format: "label == %@", Localization.predictionRegionRestrictionsTitle))
        .firstMatch
    private lazy var closeButton = app.buttons
        .matching(identifier: PolymarketAccessibilityIdentifiers.regionRestrictionSheet)
        .matching(NSPredicate(format: "label == %@", Localization.commonClose))
        .firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the region restrictions message") { _ in
            waitAndAssertTrue(sheet, timeout: .networkRequest, "Region restrictions message should be displayed")
            waitAndAssertTrue(title, "Region restrictions message should show its title")
            return self
        }
    }

    @discardableResult
    func verifyNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the region restrictions message is not displayed") { _ in
            XCTAssertTrue(sheet.staysAbsent(for: .absenceCheck), "Region restrictions message should not be displayed")
            return self
        }
    }

    @discardableResult
    func close<Destination: Screen>(returningTo destination: Destination.Type) -> Destination {
        XCTContext.runActivity(named: "Close the region restrictions message") { _ in
            XCTAssertTrue(closeButton.waitAndTap(), "Close button of the message should be tappable")
            XCTAssertTrue(sheet.waitForNonExistence(timeout: .robustUIUpdate), "Region restrictions message should be dismissed")
            return Destination(app)
        }
    }
}
