//
//  PolymarketOrderSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//
import XCTest
import TangemAccessibilityIdentifiers

final class PolymarketOrderSheet: Screen {
    let app: XCUIApplication

    private let titles: [String]
    private lazy var title = app.staticTexts
        .matching(NSPredicate(format: "label IN %@", titles))
        .firstMatch
    private lazy var closeButton = app.buttons[CommonUIAccessibilityIdentifiers.closeButton].firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
        titles = [Localization.predictionPlaceTitle, Localization.predictionCloseTitle]
    }

    init(_ app: XCUIApplication, intent: Intent) {
        self.app = app
        titles = [intent.title]
    }

    @discardableResult
    func waitForSheet() -> Self {
        XCTContext.runActivity(named: "Wait for the order screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "order screen should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify the order screen is not displayed") { _ in
            XCTAssertTrue(title.staysAbsent(for: .absenceCheck), "order screen should not be displayed")
            return self
        }
    }

    @discardableResult
    func close<Destination: Screen>(returningTo destination: Destination.Type) -> Destination {
        XCTContext.runActivity(named: "Close the order screen") { _ in
            XCTAssertTrue(closeButton.waitAndTap(), "Close button should be tappable")
            XCTAssertTrue(title.waitForNonExistence(timeout: .robustUIUpdate), "order screen should be dismissed")
            return Destination(app)
        }
    }
}

extension PolymarketOrderSheet {
    enum Intent {
        case buy
        case sell

        var title: String {
            switch self {
            case .buy: Localization.predictionPlaceTitle
            case .sell: Localization.predictionCloseTitle
            }
        }
    }
}
