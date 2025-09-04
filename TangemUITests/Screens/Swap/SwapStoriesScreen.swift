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
    func closeStoriesIfNeeded() -> SwapScreen {
        XCTContext.runActivity(named: "Close Swap Stories Screen if needed") { _ in
            if closeButton.waitForExistence(timeout: 2.0) {
                closeButton.waitAndTap()
            }

            return SwapScreen(app)
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
