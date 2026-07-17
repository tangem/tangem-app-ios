//
//  SupportTypeSelectionSheet.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class SupportTypeSelectionSheet: ScreenBase<SupportTypeSelectionElement> {
    private lazy var emailButton = button(.emailButton)

    @discardableResult
    func openMail() -> MailFallbackScreen {
        XCTContext.runActivity(named: "Open mail from support type selection sheet") { _ in
            emailButton.waitAndTap()
            return MailFallbackScreen(app)
        }
    }
}

enum SupportTypeSelectionElement: String, UIElement {
    case emailButton
    case chatButton

    var accessibilityIdentifier: String {
        switch self {
        case .emailButton:
            return SupportChatAccessibilityIdentifiers.supportTypeSelectionEmailButton
        case .chatButton:
            return SupportChatAccessibilityIdentifiers.supportTypeSelectionChatButton
        }
    }
}
