//
//  MailFallbackScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class MailFallbackScreen: ScreenBase<MailFallbackElement> {
    private lazy var title = staticText(.title)
    private lazy var openMailButton = button(.openMailButton)
    private lazy var shareLogsButton = button(.shareLogsButton)

    @discardableResult
    func validateFallbackSheet() -> Self {
        XCTContext.runActivity(named: "Validate Contact Support fallback sheet is displayed") { _ in
            waitAndAssertTrue(title, "Contact Support title should be displayed")
            waitAndAssertTrue(openMailButton, "Open mail button should be displayed")
            waitAndAssertTrue(shareLogsButton, "Share logs button should be displayed")
        }
        return self
    }
}

enum MailFallbackElement: String, UIElement {
    case title
    case openMailButton
    case shareLogsButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return MailAccessibilityIdentifiers.fallbackTitle
        case .openMailButton:
            return MailAccessibilityIdentifiers.fallbackOpenMailButton
        case .shareLogsButton:
            return MailAccessibilityIdentifiers.fallbackShareLogsButton
        }
    }
}
