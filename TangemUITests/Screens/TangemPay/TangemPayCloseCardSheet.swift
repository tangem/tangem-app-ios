//
//  TangemPayCloseCardSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayCloseCardSheet: ScreenBase<TangemPayCloseCardSheetElement> {
    private lazy var icon = app.descendants(matching: .any)[TangemPayAccessibilityIdentifiers.popupIcon].firstMatch
    private lazy var title = app.staticTexts[Constants.title].firstMatch
    private lazy var descriptionText = app.staticTexts[Constants.description].firstMatch
    private lazy var confirmButton = button(.confirmButton)
    private lazy var cancelButton = button(.cancelButton)
    private lazy var closeButton = button(.closeButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Close card sheet") { _ in
            waitAndAssertTrue(confirmButton, "Close card button should be displayed on the Close card sheet")
            return self
        }
    }

    @discardableResult
    func verifySheetContent() -> Self {
        XCTContext.runActivity(named: "Verify Close card sheet content") { _ in
            waitAndAssertTrue(icon, "Warning icon should be displayed")
            waitAndAssertTrue(title, "Sheet title '\(Constants.title)' should be displayed")
            waitAndAssertTrue(descriptionText, "Sheet description '\(Constants.description)' should be displayed")
            waitAndAssertTrue(cancelButton, "Cancel button should be displayed")
            waitAndAssertTrue(closeButton, "Sheet close button should be displayed")
            return self
        }
    }

    @discardableResult
    func confirmClose() -> TangemPayCardDetailsScreen {
        XCTContext.runActivity(named: "Tap Close card to confirm") { _ in
            confirmButton.waitAndTap()
            return TangemPayCardDetailsScreen(app)
        }
    }
}

enum TangemPayCloseCardSheetElement: String, UIElement {
    case confirmButton
    case cancelButton
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .confirmButton:
            TangemPayAccessibilityIdentifiers.closeCardSheetConfirmButton
        case .cancelButton:
            TangemPayAccessibilityIdentifiers.popupSecondaryButton
        case .closeButton:
            TangemPayAccessibilityIdentifiers.popupCloseButton
        }
    }
}

private extension TangemPayCloseCardSheet {
    enum Constants {
        static let title = "Close your card?"
        static let description = "It will disappear from the app"
    }
}
