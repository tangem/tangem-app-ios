//
//  TransferSheetScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TransferSheetScreen: ScreenBase<TransferSheetScreenElement> {
    private lazy var sendRow = button(.sendRow)

    @discardableResult
    func waitForDisplay() -> Self {
        XCTContext.runActivity(named: "Validate Transfer action sheet is displayed") { _ in
            waitAndAssertTrue(sendRow, "Send row should exist on Transfer sheet")
        }
        return self
    }

    @discardableResult
    func tapSend() -> SendScreen {
        XCTContext.runActivity(named: "Tap Send row on Transfer sheet") { _ in
            sendRow.waitAndTap()
            return SendScreen(app)
        }
    }
}

enum TransferSheetScreenElement: String, UIElement {
    case sendRow

    var accessibilityIdentifier: String {
        switch self {
        case .sendRow:
            return ActionButtonsAccessibilityIdentifiers.transferSendRow
        }
    }
}
