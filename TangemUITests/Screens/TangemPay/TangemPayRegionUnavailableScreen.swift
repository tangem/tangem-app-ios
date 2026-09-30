//
//  TangemPayRegionUnavailableScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayRegionUnavailableScreen: ScreenBase<TangemPayRegionUnavailableScreenElement> {
    private lazy var title = staticText(.title)
    private lazy var gotItButton = button(.gotItButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Tangem Pay region restriction screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Region restriction title should be displayed")
            waitAndAssertTrue(gotItButton, "Got it button should be displayed on the region restriction screen")
            return self
        }
    }

    @discardableResult
    func verifyTitle(_ expectedTitle: String) -> Self {
        XCTContext.runActivity(named: "Verify region restriction title is '\(expectedTitle)'") { _ in
            waitAndAssertTrue(title, "Region restriction title should be displayed")
            XCTAssertEqual(title.label, expectedTitle, "Region restriction title should match")
            return self
        }
    }

    @discardableResult
    func tapGotIt() -> MainScreen {
        XCTContext.runActivity(named: "Tap Got it button") { _ in
            gotItButton.waitAndTap()
            XCTAssertTrue(title.waitForNonExistence(timeout: .conditional), "Region restriction screen should be closed")
            return MainScreen(app)
        }
    }
}

enum TangemPayRegionUnavailableScreenElement: String, UIElement {
    case title
    case gotItButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return TangemPayAccessibilityIdentifiers.regionUnavailableTitle
        case .gotItButton:
            return TangemPayAccessibilityIdentifiers.regionUnavailableGotItButton
        }
    }
}
