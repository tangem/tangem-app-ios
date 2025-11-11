//
//  NetworkSelectionWarningSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import Foundation

final class NetworkSelectionWarningSheet: ScreenBase<NetworkSelectionWarningSheetElement> {
    private lazy var understoodButton = button(.understoodButton)

    @discardableResult
    func validateDisplayed() -> Self {
        XCTContext.runActivity(named: "Validate network selection warning sheet is displayed") { _ in
            waitAndAssertTrue(
                understoodButton,
                "Network selection warning sheet should be displayed"
            )
        }
        return self
    }

    func tapUnderstood() -> ReceiveTemplatesSheet {
        XCTContext.runActivity(named: "Tap Understood button") { _ in
            understoodButton.waitAndTap()
            return ReceiveTemplatesSheet(app)
        }
    }

    @discardableResult
    func tapUnderstoodIfNeeded() -> ReceiveTemplatesSheet {
        XCTContext.runActivity(named: "Tap Understood button if sheet is displayed") { _ in
            if understoodButton.waitForExistence(timeout: .conditional) {
                understoodButton.tap()
            }
            return ReceiveTemplatesSheet(app)
        }
    }
}

enum NetworkSelectionWarningSheetElement: String, UIElement {
    case understoodButton

    var accessibilityIdentifier: String {
        switch self {
        case .understoodButton:
            return "Got it"
        }
    }
}
