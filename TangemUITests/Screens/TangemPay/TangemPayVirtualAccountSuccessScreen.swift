//
//  TangemPayVirtualAccountSuccessScreen.swift
//  TangemUITests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest

final class TangemPayVirtualAccountSuccessScreen: Screen {
    let app: XCUIApplication

    private lazy var title = app.staticTexts
        .matching(NSPredicate(format: "label == %@", Constants.title))
        .firstMatch
    private lazy var closeButton = app.buttons
        .matching(NSPredicate(format: "label == %@", Constants.closeButton))
        .firstMatch

    init(_ app: XCUIApplication) {
        self.app = app
    }

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

private extension TangemPayVirtualAccountSuccessScreen {
    enum Constants {
        static let title = "Preparing your banking details"
        static let closeButton = "Close"
    }
}
