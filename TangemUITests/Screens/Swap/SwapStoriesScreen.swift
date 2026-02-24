//
//  SwapStoriesScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SwapStoriesScreen: ScreenBase<SwapStoriesScreenElement> {
    private lazy var closeButton = button(.closeButton)

    @discardableResult
    func assertStoriesDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert Swap stories overlay is displayed") { _ in
            waitAndAssertTrue(
                closeButton,
                timeout: .robustUIUpdate,
                "Stories overlay close button should be displayed when stories are available"
            )
            return self
        }
    }

    @discardableResult
    func assertStoriesNotDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert Swap stories overlay is not displayed") { _ in
            let storiesShown = closeButton.waitForExistence(timeout: 2.0)
            XCTAssertFalse(
                storiesShown,
                "Stories overlay should not be displayed when stories API returns error"
            )
            return self
        }
    }

    @discardableResult
    func closeStoriesIfNeeded() -> SwapScreen {
        XCTContext.runActivity(named: "Close Swap Stories Screen if needed") { _ in
            if closeButton.waitForExistence(timeout: 2.0) {
                closeButton.waitAndTap()
            }
            return SwapScreen(app)
        }
    }

    @discardableResult
    func closeStories() -> SwapScreen {
        XCTContext.runActivity(named: "Close Swap Stories Screen") { _ in
            closeButton.waitAndTap()
            return SwapScreen(app)
        }
    }

    @discardableResult
    func closeStoriesAndReturnToMain() -> SwapTokenSelectorScreen {
        XCTContext.runActivity(named: "Close Swap Stories Screen and return to main") { _ in
            closeButton.waitAndTap()
            return SwapTokenSelectorScreen(app)
        }
    }
}

enum SwapStoriesScreenElement: String, UIElement {
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .closeButton:
            StoriesAccessibilityIdentifiers.closeButton
        }
    }
}
