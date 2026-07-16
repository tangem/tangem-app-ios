//
//  TermsOfServiceScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TermsOfServiceScreen: Screen {
    private static let screenTitle = "Terms of service"
    private static let tosTextFragment = "PLEASE READ THESE TERMS OF SERVICE"

    let app: XCUIApplication

    init(_ app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func verifyTitle() -> Self {
        XCTContext.runActivity(named: "Verify ToS screen title is displayed") { _ in
            let title = app.navigationBars.staticTexts[Self.screenTitle].firstMatch
            waitAndAssertTrue(title, "ToS screen title should be displayed")
            return self
        }
    }

    @discardableResult
    func verifyWebViewLoaded() -> Self {
        XCTContext.runActivity(named: "Verify ToS web view is loaded") { _ in
            waitAndAssertTrue(app.webViews.firstMatch, "ToS web view should be loaded")
            return self
        }
    }

    @discardableResult
    func verifyToSText() -> Self {
        XCTContext.runActivity(named: "Verify ToS text is displayed in the web view") { _ in
            let predicate = NSPredicate(format: NSPredicateFormat.labelContains.rawValue, Self.tosTextFragment)
            let termsText = app.webViews.staticTexts.matching(predicate).firstMatch
            waitAndAssertTrue(termsText, "ToS text should be displayed in the web view")
            return self
        }
    }
}
