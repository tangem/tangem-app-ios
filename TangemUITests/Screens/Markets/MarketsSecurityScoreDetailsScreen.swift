//
//  MarketsSecurityScoreDetailsScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemAccessibilityIdentifiers
import XCTest

final class MarketsSecurityScoreDetailsScreen: ScreenBase<MarketsSecurityScoreDetailsScreenElement> {
    private lazy var detailsTitle = staticText(.securityScoreDetailsTitle)
    private lazy var providerLinks = app.buttons.matching(
        identifier: MarketsSecurityScoreDetailsScreenElement.securityScoreDetailsProviderLink.accessibilityIdentifier
    )

    @discardableResult
    func verifyDetailsSheetDisplayed() -> Self {
        XCTContext.runActivity(named: "Verify Security Score details sheet is displayed") { _ in
            waitAndAssertTrue(
                detailsTitle,
                "Security Score details title should be visible"
            )
            return self
        }
    }

    @discardableResult
    func tapFirstProviderLink() -> Self {
        XCTContext.runActivity(named: "Tap first provider link and verify WebView opens") { _ in
            waitAndAssertTrue(
                providerLinks.firstMatch,
                "Provider link should be visible"
            )
            providerLinks.firstMatch.tap()

            let webView = app.webViews.firstMatch
            waitAndAssertTrue(webView, "WebView should appear after tapping provider link")

            return self
        }
    }
}

enum MarketsSecurityScoreDetailsScreenElement: String, UIElement {
    case securityScoreDetailsTitle
    case securityScoreDetailsProviderLink

    var accessibilityIdentifier: String {
        switch self {
        case .securityScoreDetailsTitle:
            MarketsAccessibilityIdentifiers.securityScoreDetailsTitle
        case .securityScoreDetailsProviderLink:
            MarketsAccessibilityIdentifiers.securityScoreDetailsProviderLink
        }
    }
}
