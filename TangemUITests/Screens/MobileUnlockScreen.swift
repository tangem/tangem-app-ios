//
//  MobileUnlockScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class MobileUnlockScreen: ScreenBase<MobileUnlockScreenElement> {
    private lazy var title = staticText(.title)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for mobile wallet unlock screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Mobile wallet unlock title should be displayed")
            return self
        }
    }
}

enum MobileUnlockScreenElement: String, UIElement {
    case title

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            return AuthAccessibilityIdentifiers.mobileUnlockTitle
        }
    }
}
