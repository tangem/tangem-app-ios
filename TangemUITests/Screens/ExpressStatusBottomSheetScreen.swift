//
//  ExpressStatusBottomSheetScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class ExpressStatusBottomSheetScreen: ScreenBase<ExpressStatusBottomSheetElement> {
    private lazy var title = staticText(.title)
    private lazy var providerTitle = staticText(.providerTitle)

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Wait for express status sheet to display") { _ in
            waitAndAssertTrue(title, "Express status sheet title should exist")
        }
        return self
    }

    @discardableResult
    func assertProviderTitle(contains expected: String) -> Self {
        XCTContext.runActivity(named: "Assert provider title contains '\(expected)'") { _ in
            waitAndAssertTrue(providerTitle, "Provider title should exist")
            let predicate = NSPredicate(format: "label CONTAINS %@", expected)
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: providerTitle)
            XCTAssertEqual(
                XCTWaiter().wait(for: [expectation], timeout: .networkRequest),
                .completed,
                "Provider title should contain '\(expected)' but was '\(providerTitle.label)'"
            )
        }
        return self
    }

    // MARK: - Rating

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

enum ExpressStatusBottomSheetElement: String, UIElement {
    case title
    case providerTitle

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return TokenAccessibilityIdentifiers.expressStatusSheetTitle
        case .providerTitle:
            return TokenAccessibilityIdentifiers.expressStatusProviderTitle
        }
    }
}
