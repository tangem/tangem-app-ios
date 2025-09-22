//
//  MailScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class MailScreen: ScreenBase<MailElement> {
    private lazy var noAccountsTitle = staticText(.noAccountsTitle)

    func validateMailOpened() {
        XCTAssertTrue(noAccountsTitle.waitForExistence(timeout: .robustUIUpdate))
    }
}

enum MailElement: String, UIElement {
    case noAccountsTitle

    var accessibilityIdentifier: String {
        switch self {
        case .noAccountsTitle:
            return MailAccessibilityIdentifiers.noAccountsTitle
        }
    }
}
