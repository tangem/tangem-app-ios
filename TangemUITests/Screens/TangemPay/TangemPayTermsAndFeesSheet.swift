//
//  TangemPayTermsAndFeesSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayTermsAndFeesSheet: Screen {
    private static let documentTitleFragment = "Terms, fees and limits for Tangem Pay Card"

    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func verifyWebViewLoaded() -> Self {
        XCTContext.runActivity(named: "Verify Terms and Fees web view is loaded") { _ in
            waitAndAssertTrue(app.webViews.firstMatch, timeout: .networkRequest, "Terms and Fees web view should be loaded")
            return self
        }
    }

    @discardableResult
    func verifyDocumentTitle() -> Self {
        XCTContext.runActivity(named: "Verify tariffs document title is displayed") { _ in
            let predicate = NSPredicate(format: NSPredicateFormat.labelContains.rawValue, Self.documentTitleFragment)
            let title = app.webViews.descendants(matching: .any).matching(predicate).firstMatch
            waitAndAssertTrue(title, timeout: .networkRequest, "Tariffs document title should be displayed")
            return self
        }
    }
}
