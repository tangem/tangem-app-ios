//
//  TransactionDetailsSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TransactionDetailsSheet: ScreenBase<TransactionDetailsSheetElement> {
    private lazy var sheet = app.descendants(matching: .any)[TransactionDetailsAccessibilityIdentifiers.sheet].firstMatch
    private lazy var providerRow = app.descendants(matching: .any)[
        TransactionDetailsAccessibilityIdentifiers.infoRow(id: Constants.providerRowId)
    ].firstMatch

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Wait for transaction details sheet to display") { _ in
            waitAndAssertTrue(sheet, "Transaction details sheet should exist")
        }
        return self
    }

    @discardableResult
    func assertProviderTitle(contains expected: String) -> Self {
        XCTContext.runActivity(named: "Assert provider row contains '\(expected)'") { _ in
            waitAndAssertTrue(providerRow, "Provider row should exist")
            let predicate = NSPredicate(format: "label CONTAINS %@", expected)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: providerRow)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .networkRequest),
                .completed,
                "Provider row should contain '\(expected)' but was '\(providerRow.label)'"
            )
        }
        return self
    }

    @discardableResult
    func assertRatingBlockDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert rating block is displayed") { _ in
            let block = app.descendants(matching: .any)[RatingAccessibilityIdentifiers.block]
            waitAndAssertTrue(block, "Rating block should be displayed")
        }
        return self
    }

    @discardableResult
    func tapStar(_ rating: Int) -> RatingFeedbackSheetScreen {
        XCTContext.runActivity(named: "Tap '\(rating)' star rating") { _ in
            let star = app.buttons[RatingAccessibilityIdentifiers.star(rating)].firstMatch
            waitAndAssertTrue(star, "'\(rating)' star button should exist")
            star.waitAndTap()
        }
        return RatingFeedbackSheetScreen(app)
    }

    @discardableResult
    func assertStarNotTappable(_ rating: Int) -> Self {
        XCTContext.runActivity(named: "Assert '\(rating)' star is no longer tappable") { _ in
            let star = app.buttons[RatingAccessibilityIdentifiers.star(rating)]
            XCTAssertTrue(star.waitForNonExistence(timeout: .robustUIUpdate), "'\(rating)' star should no longer be a tappable button after rating")
        }
        return self
    }
}

enum TransactionDetailsSheetElement: String, UIElement {
    case sheet

    var accessibilityIdentifier: String {
        switch self {
        case .sheet:
            return TransactionDetailsAccessibilityIdentifiers.sheet
        }
    }
}

private extension TransactionDetailsSheet {
    enum Constants {
        static let providerRowId = "provider"
    }
}
