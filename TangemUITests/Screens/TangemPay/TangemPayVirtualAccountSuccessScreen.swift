//
//  TangemPayVirtualAccountSuccessScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
import TangemAccessibilityIdentifiers

final class TangemPayVirtualAccountSuccessScreen: ScreenBase<TangemPayVirtualAccountSuccessScreenElement> {
    private lazy var title = staticText(.title)
    private lazy var closeButton = button(.closeButton)

    @discardableResult
    func waitForScreen() -> Self {
        XCTContext.runActivity(named: "Wait for Virtual account order success screen") { _ in
            waitAndAssertTrue(title, timeout: .networkRequest, "Virtual account success title should be displayed")
            return self
        }
    }

    @discardableResult
    func tapClose() -> TangemPayMainScreen {
        XCTContext.runActivity(named: "Tap Close on Virtual account order success screen") { _ in
            closeButton.waitAndTap()
            return TangemPayMainScreen(app)
        }
    }
}

enum TangemPayVirtualAccountSuccessScreenElement: String, UIElement {
    case title
    case closeButton

    var accessibilityIdentifier: String {
        switch self {
        case .title:
            TangemPayAccessibilityIdentifiers.virtualAccountSuccessTitle
        case .closeButton:
            TangemPayAccessibilityIdentifiers.virtualAccountSuccessCloseButton
        }
    }
}
