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
    private lazy var rateRow = app.descendants(matching: .any)[
        TransactionDetailsAccessibilityIdentifiers.infoRow(id: Constants.rateRowId)
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
    func assertHeaderDateDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert the header date is displayed") { _ in
            // The header date text inherits the sheet's own identifier rather than its own, so match by content.
            let dateTexts = app.staticTexts.matching(identifier: TransactionDetailsAccessibilityIdentifiers.sheet)
                .matching(NSPredicate(format: "(label CONTAINS[c] %@ OR label CONTAINS[c] %@) AND label CONTAINS %@", "AM", "PM", ":"))
            waitAndAssertTrue(dateTexts.firstMatch, "Header date should be displayed")
        }
        return self
    }

    @discardableResult
    func assertHeaderTitle(contains expected: String) -> Self {
        XCTContext.runActivity(named: "Assert header title contains '\(expected)'") { _ in
            // The header title text inherits the sheet's own identifier rather than its own, so match by content.
            let titleTexts = app.staticTexts.matching(identifier: TransactionDetailsAccessibilityIdentifiers.sheet)
                .matching(NSPredicate(format: "label CONTAINS[c] %@", expected))
            waitAndAssertTrue(titleTexts.firstMatch, timeout: .networkRequest, "Header title should contain '\(expected)'")
        }
        return self
    }

    @discardableResult
    func assertLegAmountDisplayed(legId: String) -> Self {
        XCTContext.runActivity(named: "Assert the '\(legId)' leg amount is displayed") { _ in
            // Several elements here share one identifier (SwiftUI propagation); only the amount has a decimal point.
            let legElements = app.descendants(matching: .any).matching(identifier: TransactionDetailsAccessibilityIdentifiers.tokensLeg(id: legId))
            let amountText = legElements.matching(NSPredicate(format: "label MATCHES %@", ".*[0-9]+\\.[0-9]+.*")).firstMatch
            waitAndAssertTrue(amountText, "'\(legId)' leg should display an amount")
        }
        return self
    }

    @discardableResult
    func assertRateRowDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert rate row is displayed") { _ in
            waitAndAssertTrue(rateRow, "Rate row should exist")
        }
        return self
    }

    @discardableResult
    func tapProviderRow() -> Self {
        XCTContext.runActivity(named: "Tap provider row to navigate to the provider") { _ in
            waitAndAssertTrue(providerRow, "Provider row should exist")
            providerRow.waitAndTap()
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
        static let rateRowId = "rate"
    }
}
