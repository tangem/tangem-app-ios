//
//  YieldModuleActiveScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class YieldModuleActiveScreen: ScreenBase<YieldModuleActiveScreenElement> {
    private lazy var notificationTitle = staticText(.notificationTitle)
    private lazy var approveButton = button(.notificationButton)
    private lazy var disableButton = button(.disableButton)

    @discardableResult
    func assertNotificationDisplayed() -> Self {
        XCTContext.runActivity(named: "Assert notification is displayed on yield active screen") { _ in
            waitAndAssertTrue(notificationTitle, "Yield notification should be displayed")
            return self
        }
    }

    @discardableResult
    func assertNotificationTitle(contains text: String) -> Self {
        XCTContext.runActivity(named: "Assert yield notification title contains '\(text)'") { _ in
            waitAndAssertTrue(notificationTitle, "Yield notification should be displayed")
            XCTAssertTrue(
                notificationTitle.label.contains(text),
                "Yield notification title should contain '\(text)' but was '\(notificationTitle.label)'"
            )
            return self
        }
    }

    @discardableResult
    func tapApprove() -> YieldModuleTransactionScreen {
        XCTContext.runActivity(named: "Tap 'Approve' button on yield active screen") { _ in
            approveButton.waitAndTap()
            return YieldModuleTransactionScreen(app)
        }
    }

    @discardableResult
    func tapDisableYieldMode() -> YieldModuleTransactionScreen {
        XCTContext.runActivity(named: "Tap 'Disable Yield Mode' button on yield active screen") { _ in
            disableButton.waitAndTap()
            return YieldModuleTransactionScreen(app)
        }
    }
}

enum YieldModuleActiveScreenElement: String, UIElement {
    case notificationTitle
    case notificationButton
    case disableButton

    var accessibilityIdentifier: String {
        switch self {
        case .notificationTitle:
            return YieldModuleAccessibilityIdentifiers.notificationTitle
        case .notificationButton:
            return YieldModuleAccessibilityIdentifiers.notificationButton
        case .disableButton:
            return YieldModuleAccessibilityIdentifiers.disableButton
        }
    }
}
